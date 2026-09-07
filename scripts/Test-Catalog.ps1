[CmdletBinding()]
param(
  [Parameter()]
  [string]$RepositoryRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'
$problems = [System.Collections.Generic.List[string]]::new()
$warnings = [System.Collections.Generic.List[string]]::new()

function Read-JsonFile {
  param([Parameter(Mandatory)][string]$Path)

  try {
    return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json -Depth 100
  }
  catch {
    $problems.Add("Invalid JSON: $Path - $($_.Exception.Message)")
    return $null
  }
}

function Test-RequiredProperty {
  param(
    [Parameter(Mandatory)]$Object,
    [Parameter(Mandatory)][string]$Property,
    [Parameter(Mandatory)][string]$Context
  )

  if ($null -eq $Object.PSObject.Properties[$Property]) {
    $problems.Add("Missing '$Property' in $Context")
    return $false
  }

  return $true
}

$repositoryPath = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$validationSets = @(
  @{ Files = @(Get-ChildItem (Join-Path $repositoryPath 'catalog/clouds') -Filter '*.json' -File); Schema = 'cloud.schema.json' },
  @{ Files = @(Get-ChildItem (Join-Path $repositoryPath 'catalog/platforms') -Filter '*.json' -Recurse -File); Schema = 'platform-profile.schema.json' },
  @{ Files = @(Get-ChildItem (Join-Path $repositoryPath 'labs') -Filter 'lab.json' -Recurse -File); Schema = 'lab.schema.json' },
  @{ Files = @(Get-ChildItem (Join-Path $repositoryPath 'templates') -Filter 'lab.json' -Recurse -File); Schema = 'lab.schema.json' }
)
$allJsonFiles = @($validationSets | ForEach-Object { $_.Files })

foreach ($set in $validationSets) {
  foreach ($file in $set.Files) {
    try {
      $valid = Test-Json -Json (Get-Content $file.FullName -Raw) -SchemaFile (Join-Path $repositoryPath "schemas/$($set.Schema)") -ErrorAction Stop
      if (-not $valid) { $problems.Add("Schema validation failed: $($file.FullName)") }
    }
    catch { $problems.Add("Schema validation failed: $($file.FullName) - $($_.Exception.Message)") }
  }
}
if ($problems.Count) {
  $problems | ForEach-Object { Write-Host $_ -ForegroundColor Red }
  exit 1
}

foreach ($file in $allJsonFiles) {
  $null = Read-JsonFile -Path $file.FullName
}

$cloudFiles = Get-ChildItem -LiteralPath (Join-Path $repositoryPath 'catalog/clouds') -Filter '*.json' -File
$clouds = @{}

foreach ($file in $cloudFiles) {
  $cloud = Read-JsonFile -Path $file.FullName
  if ($null -eq $cloud) { continue }

  foreach ($property in @('schema_version', 'id', 'display_name', 'implementation_status', 'initial_service_ids')) {
    $null = Test-RequiredProperty -Object $cloud -Property $property -Context $file.FullName
  }

  if (-not $cloud.id) { continue }
  if ($clouds.ContainsKey($cloud.id)) {
    $problems.Add("Duplicate cloud id '$($cloud.id)' in $($file.FullName)")
  }
  else {
    $clouds[$cloud.id] = $cloud
  }

  $duplicateServices = @($cloud.initial_service_ids | Group-Object | Where-Object Count -gt 1)
  foreach ($duplicate in $duplicateServices) {
    $problems.Add("Duplicate service id '$($duplicate.Name)' in cloud '$($cloud.id)'")
  }
}

$allowedServiceStatuses = @('supported', 'conditional', 'separate_environment', 'unsupported', 'unknown')
$profileFiles = Get-ChildItem -LiteralPath (Join-Path $repositoryPath 'catalog/platforms') -Filter '*.json' -Recurse -File

foreach ($file in $profileFiles) {
  $profile = Read-JsonFile -Path $file.FullName
  if ($null -eq $profile) { continue }

  foreach ($property in @('schema_version', 'platform', 'cloud', 'profile_status', 'coverage', 'reviewed_on', 'sources', 'session', 'services')) {
    $null = Test-RequiredProperty -Object $profile -Property $property -Context $file.FullName
  }

  if (-not $clouds.ContainsKey($profile.cloud)) {
    $problems.Add("Profile '$($file.FullName)' references unknown cloud '$($profile.cloud)'")
    continue
  }

  $knownCloudServices = @($clouds[$profile.cloud].initial_service_ids)
  foreach ($serviceProperty in $profile.services.PSObject.Properties) {
    if ($serviceProperty.Name -notin $knownCloudServices) {
      $problems.Add("Profile '$($file.FullName)' contains service '$($serviceProperty.Name)' not declared by cloud '$($profile.cloud)'")
    }

    if ($serviceProperty.Value.status -notin $allowedServiceStatuses) {
      $problems.Add("Service '$($serviceProperty.Name)' in '$($file.FullName)' has invalid status '$($serviceProperty.Value.status)'")
    }
  }

  foreach ($source in @($profile.sources)) {
    if (-not $source.url.StartsWith('https://')) {
      $problems.Add("Profile source must use HTTPS in '$($file.FullName)': $($source.url)")
    }
  }

  try {
    $null = [datetime]::ParseExact($profile.reviewed_on, 'yyyy-MM-dd', [Globalization.CultureInfo]::InvariantCulture)
  }
  catch {
    $problems.Add("Profile '$($file.FullName)' has invalid reviewed_on date '$($profile.reviewed_on)'")
  }

  if ($profile.coverage -eq 'future_seed') {
    $warnings.Add("Seed profile is not ready for lab verification: $($profile.platform)/$($profile.cloud)")
  }
}

$allowedLabStates = @('idea', 'designed', 'implemented', 'verified', 'published', 'maintenance', 'retired')
$allowedImplementationStatuses = @('idea', 'planned', 'implemented', 'verified', 'design_only', 'retired')
$labFiles = Get-ChildItem -LiteralPath (Join-Path $repositoryPath 'labs') -Filter 'lab.json' -Recurse -File
$labIds = @{}

foreach ($file in $labFiles) {
  $lab = Read-JsonFile -Path $file.FullName
  if ($null -eq $lab) { continue }

  foreach ($property in @('schema_version', 'id', 'title', 'summary', 'state', 'domains', 'portable_capabilities', 'objectives', 'implementations', 'evidence')) {
    $null = Test-RequiredProperty -Object $lab -Property $property -Context $file.FullName
  }

  if ($lab.id) {
    if ($labIds.ContainsKey($lab.id)) {
      $problems.Add("Duplicate lab id '$($lab.id)' in $($file.FullName)")
    }
    else {
      $labIds[$lab.id] = $file.FullName
    }
  }

  if ($lab.state -notin $allowedLabStates) {
    $problems.Add("Lab '$($lab.id)' has invalid state '$($lab.state)'")
  }

  foreach ($implementationProperty in $lab.implementations.PSObject.Properties) {
    $cloudId = $implementationProperty.Name
    $implementation = $implementationProperty.Value

    if (-not $clouds.ContainsKey($cloudId)) {
      $problems.Add("Lab '$($lab.id)' references unknown cloud '$cloudId'")
      continue
    }

    if ($implementation.status -notin $allowedImplementationStatuses) {
      $problems.Add("Lab '$($lab.id)' cloud '$cloudId' has invalid implementation status '$($implementation.status)'")
    }

    $knownCloudServices = @($clouds[$cloudId].initial_service_ids)
    foreach ($demand in $implementation.resource_requirements.PSObject.Properties) {
      if ($demand.Name -notin $implementation.required_services) {
        $problems.Add("Lab '$($lab.id)' has resource demands for '$($demand.Name)' without declaring it a required service")
      }
    }
    foreach ($serviceId in @($implementation.required_services) + @($implementation.optional_services)) {
      if ($serviceId -notin $knownCloudServices) {
        $problems.Add("Lab '$($lab.id)' cloud '$cloudId' references undeclared service '$serviceId'")
      }
    }
  }
}

Write-Host "Catalog validation summary"
Write-Host "  JSON files:       $($allJsonFiles.Count)"
Write-Host "  Clouds:           $($cloudFiles.Count)"
Write-Host "  Platform profiles:$($profileFiles.Count)"
Write-Host "  Labs:             $($labFiles.Count)"

foreach ($warning in $warnings) {
  Write-Warning $warning
}

if ($problems.Count -gt 0) {
  Write-Host ''
  Write-Host 'Validation failed:' -ForegroundColor Red
  foreach ($problem in $problems) {
    Write-Host "  - $problem" -ForegroundColor Red
  }
  exit 1
}

Write-Host ''
Write-Host 'Catalog validation passed.' -ForegroundColor Green
