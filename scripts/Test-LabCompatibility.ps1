[CmdletBinding()]
param(
  [Parameter(Mandatory)]
  [string]$LabManifest,

  [Parameter(Mandatory)]
  [string]$PlatformProfile,

  [Parameter(Mandatory)]
  [ValidateSet('azure', 'aws', 'gcp')]
  [string]$Cloud,

  [Parameter()]
  [switch]$AsJson,

  [Parameter()]
  [switch]$FailOnIncompatible
)

$ErrorActionPreference = 'Stop'

$labPath = (Resolve-Path -LiteralPath $LabManifest).Path
$profilePath = (Resolve-Path -LiteralPath $PlatformProfile).Path
foreach ($inputFile in @(@{Path=$labPath; Schema='lab.schema.json'}, @{Path=$profilePath; Schema='platform-profile.schema.json'})) {
  if (-not (Test-Json -Json (Get-Content $inputFile.Path -Raw) -SchemaFile (Join-Path $PSScriptRoot "../schemas/$($inputFile.Schema)") -ErrorAction Stop)) {
    throw "Invalid compatibility input: $($inputFile.Path)"
  }
}
$lab = Get-Content -LiteralPath $labPath -Raw | ConvertFrom-Json -Depth 100
$profile = Get-Content -LiteralPath $profilePath -Raw | ConvertFrom-Json -Depth 100

if ($profile.cloud -ne $Cloud) {
  throw "Profile cloud '$($profile.cloud)' does not match requested cloud '$Cloud'."
}

$implementationProperty = $lab.implementations.PSObject.Properties[$Cloud]
if ($null -eq $implementationProperty) {
  throw "Lab '$($lab.id)' does not define a '$Cloud' implementation."
}

$implementation = $implementationProperty.Value
$checks = [System.Collections.Generic.List[object]]::new()
$blockers = 0
$conditions = 0
$unknowns = 0

function Add-Check {
  param(
    [Parameter(Mandatory)][string]$Type,
    [Parameter(Mandatory)][string]$Requirement,
    [Parameter(Mandatory)][string]$Result,
    [Parameter(Mandatory)][string]$Detail
  )

  $script:checks.Add([pscustomobject]@{
      type        = $Type
      requirement = $Requirement
      result      = $Result
      detail      = $Detail
    })

  switch ($Result) {
    'blocked' { $script:blockers++ }
    'conditional' { $script:conditions++ }
    'unknown' { $script:unknowns++ }
  }
}

foreach ($serviceId in @($implementation.required_services)) {
  $serviceProperty = $profile.services.PSObject.Properties[$serviceId]
  if ($null -eq $serviceProperty) {
    Add-Check -Type 'service' -Requirement $serviceId -Result 'unknown' -Detail 'The platform profile does not contain this required service.'
    continue
  }

  $service = $serviceProperty.Value
  switch ($service.status) {
    'supported' {
      Add-Check -Type 'service' -Requirement $serviceId -Result 'pass' -Detail 'Listed as supported.'
    }
    'conditional' {
      Add-Check -Type 'service' -Requirement $serviceId -Result 'conditional' -Detail 'Supported with profile-specific limits; review limits and notes.'
    }
    'separate_environment' {
      Add-Check -Type 'service' -Requirement $serviceId -Result 'blocked' -Detail 'Available only through a separate environment, not this profile.'
    }
    'unsupported' {
      Add-Check -Type 'service' -Requirement $serviceId -Result 'blocked' -Detail 'Listed as unsupported.'
    }
    default {
      Add-Check -Type 'service' -Requirement $serviceId -Result 'unknown' -Detail "Unrecognized or unknown service status '$($service.status)'."
    }
  }
}

foreach ($serviceId in @($implementation.optional_services)) {
  $serviceProperty = $profile.services.PSObject.Properties[$serviceId]
  if ($null -eq $serviceProperty) {
    Add-Check -Type 'optional_service' -Requirement $serviceId -Result 'optional_unknown' -Detail 'Optional service is not described by the profile; the core lab can continue.'
    continue
  }

  $status = $serviceProperty.Value.status
  $result = if ($status -eq 'supported') { 'pass' } elseif ($status -eq 'conditional') { 'optional_conditional' } else { 'optional_unavailable' }
  Add-Check -Type 'optional_service' -Requirement $serviceId -Result $result -Detail "Optional service profile status: $status."
}

function Resolve-CapabilityResult($Status) {
  switch ($Status) {
    'supported' { 'pass' }
    'conditional' { 'conditional' }
    'unsupported' { 'blocked' }
    'not_applicable' { 'blocked' }
    default { 'unknown' }
  }
}

if ($implementation.requirements.managed_identity) {
  $managedIdentity = $profile.capabilities.managed_identity
  $result = Resolve-CapabilityResult $managedIdentity
  Add-Check -Type 'capability' -Requirement 'managed_identity' -Result $result -Detail "Profile capability: $managedIdentity."
}
else {
  Add-Check -Type 'capability' -Requirement 'managed_identity' -Result 'pass' -Detail 'The sandbox implementation does not require managed identity.'
}

if ($implementation.requirements.gpu) {
  $gpu = $profile.capabilities.gpu
  $result = Resolve-CapabilityResult $gpu
  Add-Check -Type 'capability' -Requirement 'gpu' -Result $result -Detail "Profile capability: $gpu."
}
else {
  Add-Check -Type 'capability' -Requirement 'gpu' -Result 'pass' -Detail 'The implementation does not require a GPU.'
}

if ($implementation.requirements.resource_group_creation) {
  $resourceGroupCreation = $profile.scope.resource_group_creation
  switch ($resourceGroupCreation) {
    'supported' { Add-Check -Type 'scope' -Requirement 'resource_group_creation' -Result 'pass' -Detail 'Profile permits resource-group creation.' }
    'conditional' { Add-Check -Type 'scope' -Requirement 'resource_group_creation' -Result 'conditional' -Detail 'Resource-group creation is conditional.' }
    'unknown' { Add-Check -Type 'scope' -Requirement 'resource_group_creation' -Result 'unknown' -Detail 'Preflight must verify resource-group creation.' }
    default { Add-Check -Type 'scope' -Requirement 'resource_group_creation' -Result 'blocked' -Detail "Profile capability: $resourceGroupCreation." }
  }
}
else {
  Add-Check -Type 'scope' -Requirement 'resource_group_creation' -Result 'pass' -Detail 'Implementation can use an existing resource group.'
}

$requestedSandboxes = [int]$implementation.requirements.concurrent_sandboxes
$availableSandboxes = [int]$profile.session.maximum_concurrent_sandboxes
if ($requestedSandboxes -gt $availableSandboxes) {
  Add-Check -Type 'session' -Requirement 'concurrent_sandboxes' -Result 'blocked' -Detail "Requires $requestedSandboxes but profile allows $availableSandboxes."
}
else {
  Add-Check -Type 'session' -Requirement 'concurrent_sandboxes' -Result 'pass' -Detail "Requires $requestedSandboxes; profile allows $availableSandboxes."
}

$estimatedMinutes = [int]$implementation.estimated_minutes
$standardMinutes = [int]$profile.session.standard_minutes
$maximumMinutes = if ($profile.session.maximum_documented_minutes) { [int]$profile.session.maximum_documented_minutes } else { $standardMinutes }

if ($estimatedMinutes -le $standardMinutes) {
  Add-Check -Type 'session' -Requirement 'duration' -Result 'pass' -Detail "Estimated $estimatedMinutes minutes within the $standardMinutes-minute standard session."
}
elseif ($estimatedMinutes -le $maximumMinutes) {
  Add-Check -Type 'session' -Requirement 'duration' -Result 'conditional' -Detail "Estimated $estimatedMinutes minutes exceeds the standard session and may require an eligible extension."
}
else {
  Add-Check -Type 'session' -Requirement 'duration' -Result 'blocked' -Detail "Estimated $estimatedMinutes minutes exceeds the documented maximum of $maximumMinutes."
}

foreach ($serviceRequirement in @($implementation.resource_requirements.PSObject.Properties)) {
  if ($null -eq $serviceRequirement) { continue }
  $serviceId = $serviceRequirement.Name
  $limits = $profile.services.PSObject.Properties[$serviceId].Value.limits
  foreach ($demand in $serviceRequirement.Value.PSObject.Properties) {
    $limitKey = if ($demand.Name -eq 'sku') { 'allowed_skus' } else { "maximum_$($demand.Name)" }
    $limit = if ($limits) { $limits.PSObject.Properties[$limitKey] } else { $null }
    if ($null -eq $limit) {
      Add-Check 'resource' "$serviceId.$($demand.Name)" 'unknown' 'No matching documented limit.'
    }
    elseif (($demand.Name -eq 'sku' -and $demand.Value -notin $limit.Value) -or ($demand.Name -ne 'sku' -and [double]$demand.Value -gt [double]$limit.Value)) {
      Add-Check 'resource' "$serviceId.$($demand.Name)" 'blocked' 'Requested size exceeds the documented limit or SKU allowlist.'
    }
    else { Add-Check 'resource' "$serviceId.$($demand.Name)" 'pass' 'Requested size fits the documented limit.' }
  }
}

if ($profile.profile_status -ne 'active' -or $profile.coverage -eq 'future_seed') {
  Add-Check 'profile' 'readiness' 'unknown' 'This profile is a seed or retired; it is not a deployment-ready profile.'
}

$overall = if ($implementation.status -eq 'design_only') {
  'design_only'
}
elseif ($blockers -gt 0) {
  'incompatible'
}
elseif ($unknowns -gt 0) {
  'unknown'
}
elseif ($conditions -gt 0) {
  'compatible_with_conditions'
}
else {
  'compatible'
}

$resultObject = [pscustomobject]@{
  lab                   = $lab.id
  title                 = $lab.title
  implementation_status = $implementation.status
  execution_ready       = ($implementation.status -in @('implemented', 'verified') -and $profile.profile_status -eq 'active' -and $overall -in @('compatible', 'compatible_with_conditions'))
  platform              = $profile.platform
  cloud                 = $Cloud
  profile_coverage      = $profile.coverage
  profile_reviewed_on   = $profile.reviewed_on
  result                = $overall
  checks                = $checks
}

if ($AsJson) {
  $resultObject | ConvertTo-Json -Depth 20
}
else {
  Write-Host "$($lab.title) on $($profile.platform)/$Cloud"
  Write-Host "Result: $overall"
  Write-Host "Implementation status: $($implementation.status)"
  Write-Host "Profile coverage: $($profile.coverage), reviewed $($profile.reviewed_on)"
  Write-Host ''
  $checks | Format-Table -AutoSize type, requirement, result, detail
}

if ($FailOnIncompatible -and $overall -in @('incompatible', 'unknown', 'design_only')) {
  exit 2
}
