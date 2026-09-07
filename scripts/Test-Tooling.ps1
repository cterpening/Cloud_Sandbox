[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot -Parent
$pwsh = (Get-Process -Id $PID).Path
$casesRoot = Join-Path $repo "artifacts/tooling-tests/$([guid]::NewGuid().ToString('N'))"
$null = New-Item -ItemType Directory -Path $casesRoot -Force

function New-Case($Name) {
  $root = Join-Path $casesRoot $Name
  $null = New-Item -ItemType Directory -Path $root
  foreach ($folder in @('scripts', 'schemas', 'catalog', 'templates')) {
    Copy-Item (Join-Path $repo $folder) -Destination $root -Recurse
  }
  foreach ($file in Get-ChildItem (Join-Path $repo 'labs') -Filter lab.json -Recurse -File) {
    $destination = Join-Path $root ([IO.Path]::GetRelativePath($repo, $file.FullName))
    $null = New-Item -ItemType Directory -Path (Split-Path $destination -Parent) -Force
    Copy-Item $file.FullName $destination
  }
  return $root
}

function Run-Case($Root, $Tool, [string[]]$Arguments = @()) {
  $info = [Diagnostics.ProcessStartInfo]::new($pwsh)
  $info.UseShellExecute = $false
  $info.RedirectStandardOutput = $true
  $info.RedirectStandardError = $true
  foreach ($argument in @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', (Join-Path $Root "scripts/$Tool.ps1")) + $Arguments) { $info.ArgumentList.Add($argument) }
  $process = [Diagnostics.Process]::Start($info)
  $stdout = $process.StandardOutput.ReadToEndAsync()
  $stderr = $process.StandardError.ReadToEndAsync()
  $process.WaitForExit()
  return @{Code=$process.ExitCode; Text=$stdout.Result + $stderr.Result}
}

function Assert-Case($Condition, $Message) {
  if (-not $Condition) { throw $Message }
  Write-Host "PASS: $Message"
}

function Save-Case($Object, $Path) { $Object | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $Path -Encoding utf8 }
function Compatibility($Root) {
  Run-Case $Root 'Test-LabCompatibility' @('-LabManifest', (Join-Path $Root 'labs/tiny-notes/lab.json'),
    '-PlatformProfile', (Join-Path $Root 'catalog/platforms/pluralsight/azure.json'), '-Cloud', 'azure', '-AsJson', '-FailOnIncompatible')
}

$root = New-Case 'invalid-schema'
$path = Join-Path $root 'labs/tiny-notes/lab.json'
$lab = Get-Content $path -Raw | ConvertFrom-Json
$lab.implementations.azure.PSObject.Properties.Remove('requirements')
Save-Case $lab $path
Assert-Case ((Run-Case $root 'Test-Catalog').Code -ne 0) 'Missing required fields fail catalog validation'
Assert-Case ((Compatibility $root).Code -ne 0) 'Missing requirements fail compatibility validation'

$root = New-Case 'reference-isolation'
$null = New-Item -ItemType Directory -Path (Join-Path $root 'SandboxPluralSight-main')
'{invalid JSON' | Set-Content (Join-Path $root 'SandboxPluralSight-main/broken.json')
Assert-Case ((Run-Case $root 'Test-Catalog').Code -eq 0) 'Historical reference JSON does not affect the catalog'

foreach ($status in @('unknown', 'supported', 'unsupported')) {
  $root = New-Case "capability-$status"
  $labPath = Join-Path $root 'labs/tiny-notes/lab.json'
  $profilePath = Join-Path $root 'catalog/platforms/pluralsight/azure.json'
  $lab = Get-Content $labPath -Raw | ConvertFrom-Json
  $profile = Get-Content $profilePath -Raw | ConvertFrom-Json
  $lab.implementations.azure.requirements.gpu = $true
  $profile.capabilities.gpu = $status
  Save-Case $lab $labPath
  Save-Case $profile $profilePath
  $run = Compatibility $root
  $result = $run.Text | ConvertFrom-Json
  $expected = @{unknown='unknown'; supported='pass'; unsupported='blocked'}[$status]
  Assert-Case (($result.checks | Where-Object requirement -eq 'gpu').result -eq $expected) "GPU $status remains $expected"
  Assert-Case ($run.Code -eq $(if ($status -eq 'supported') { 0 } else { 2 })) "Strict exit for GPU $status"
}

$root = New-Case 'quota'
$labPath = Join-Path $root 'labs/tiny-notes/lab.json'
$lab = Get-Content $labPath -Raw | ConvertFrom-Json
$lab.implementations.azure.resource_requirements.app_service.server_farms = 3
Save-Case $lab $labPath
Assert-Case ((Compatibility $root).Code -eq 2) 'Over-limit server farms fail compatibility'

$root = New-Case 'sku'
$labPath = Join-Path $root 'labs/tiny-notes/lab.json'
$lab = Get-Content $labPath -Raw | ConvertFrom-Json
$lab.implementations.azure.resource_requirements.app_service.sku = 'P3v3'
Save-Case $lab $labPath
Assert-Case ((Compatibility $root).Code -eq 2) 'Unlisted SKU fails compatibility'

$root = New-Case 'retired-profile'
$profilePath = Join-Path $root 'catalog/platforms/pluralsight/azure.json'
$profile = Get-Content $profilePath -Raw | ConvertFrom-Json
$profile.profile_status = 'retired'
Save-Case $profile $profilePath
Assert-Case ((Compatibility $root).Code -eq 2) 'Retired profile is not ready for execution'

# A fresh minimal labs directory exercises the single-row JSON contract.
$single = Join-Path $casesRoot 'single'
$null = New-Item -ItemType Directory -Path (Join-Path $single 'labs/tiny-notes') -Force
$null = New-Item -ItemType Directory -Path (Join-Path $single 'scripts')
Copy-Item (Join-Path $repo 'labs/tiny-notes/lab.json') (Join-Path $single 'labs/tiny-notes/lab.json')
Copy-Item (Join-Path $repo 'scripts/Get-LabCatalog.ps1') (Join-Path $single 'scripts/Get-LabCatalog.ps1')
$one = Run-Case $single 'Get-LabCatalog' @('-AsJson')
Assert-Case ($one.Code -eq 0 -and $one.Text.TrimStart().StartsWith('[')) 'One-row catalog is still a JSON array'

foreach ($file in Get-ChildItem $PSScriptRoot -Filter '*.ps1') {
  $tokens = $null; $parseErrors = $null
  $null = [Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$tokens, [ref]$parseErrors)
  Assert-Case ($parseErrors.Count -eq 0) "PowerShell syntax: $($file.Name)"
}
Write-Host 'Tooling regression checks passed. Isolated fixtures remain in ignored artifacts/tooling-tests.'

# Exercise the real native-process helper, then use synthetic responses to test
# deployment-state guards. These tests never contact Azure or execute Terraform.
. (Join-Path $PSScriptRoot 'Workshop.Tools.ps1')
$nativeResult = Invoke-WorkshopTool $pwsh @('-NoProfile', '-Command', 'Write-Output "synthetic-success"')
Assert-Case ($nativeResult -eq 'synthetic-success') 'Native executable output is captured'
$didThrow = $false
try { $null = Invoke-WorkshopTool $pwsh @('-NoProfile', '-Command', 'exit 9') } catch { $didThrow = $true }
Assert-Case $didThrow 'Nonzero native exit fails closed'

$syntheticSubscription = '00000000-0000-0000-0000-000000000001'
$previousSubscription = $env:ARM_SUBSCRIPTION_ID
try {
  $env:ARM_SUBSCRIPTION_ID = $syntheticSubscription
  $script:fakeProject = 'tiny-notes'
  $script:fakeResource = [pscustomobject]@{
    address='module.workshop.azurerm_linux_function_app.workshop'; mode='managed'; type='azurerm_linux_function_app'
    values=@{id="/subscriptions/$syntheticSubscription/resourceGroups/synthetic-group/providers/Microsoft.Web/sites/synthetic-app"}
  }
  function Invoke-WorkshopTool($Name, [string[]]$Arguments) {
    if ($Name -eq 'az') { return (@{id=$syntheticSubscription} | ConvertTo-Json) }
    if ('output' -in $Arguments) {
      return (@{project=@{value=$script:fakeProject}; function_name=@{value='synthetic-app'};
        resource_group_name=@{value='synthetic-group'}} | ConvertTo-Json -Depth 10)
    }
    return (@{values=@{root_module=@{child_modules=@(@{resources=@($script:fakeResource)})}}} | ConvertTo-Json -Depth 20)
  }
  $null = Get-WorkshopDeployment 'tiny-notes'
  Assert-Case $true 'Matching synthetic deployment state is accepted'
  foreach ($fault in @('project', 'subscription', 'group', 'address', 'resource-group')) {
    $script:fakeProject = 'tiny-notes'
    $script:fakeResource.address = 'module.workshop.azurerm_linux_function_app.workshop'
    $script:fakeResource.type = 'azurerm_linux_function_app'
    $script:fakeResource.values.id = "/subscriptions/$syntheticSubscription/resourceGroups/synthetic-group/providers/Microsoft.Web/sites/synthetic-app"
    switch ($fault) {
      'project' { $script:fakeProject = 'queue-worker' }
      'subscription' { $script:fakeResource.values.id = '/subscriptions/00000000-0000-0000-0000-000000000002/resourceGroups/synthetic-group/providers/Microsoft.Web/sites/synthetic-app' }
      'group' { $script:fakeResource.values.id = "/subscriptions/$syntheticSubscription/resourceGroups/unrelated-group/providers/Microsoft.Web/sites/synthetic-app" }
      'address' { $script:fakeResource.address = 'azurerm_linux_function_app.unrelated' }
      'resource-group' { $script:fakeResource.type = 'azurerm_resource_group' }
    }
    $didThrow = $false
    try { $null = Get-WorkshopDeployment 'tiny-notes' } catch { $didThrow = $true }
    Assert-Case $didThrow "Deployment guard rejects $fault mismatch"
  }
} finally { $env:ARM_SUBSCRIPTION_ID = $previousSubscription }
