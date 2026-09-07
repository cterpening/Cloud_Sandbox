[CmdletBinding()]
param(
  [Parameter(Mandatory)][string]$Lab,
  [Parameter(Mandatory)][string]$ResourceGroupName,
  [string]$Location = 'eastus'
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Workshop.Tools.ps1')
$null = Get-WorkshopRoot $Lab
$repo = Split-Path $PSScriptRoot -Parent
$profilePath = Join-Path $repo 'catalog/platforms/pluralsight/azure.json'
$profile = Get-Content $profilePath -Raw | ConvertFrom-Json
if ($Location -notin $profile.scope.regions -or $Location -eq 'global') { throw 'Select a deployable region from the documented allowlist.' }
& (Join-Path $PSScriptRoot 'Test-LabCompatibility.ps1') -LabManifest (Join-Path $repo "labs/$Lab/lab.json") -PlatformProfile $profilePath -Cloud azure -FailOnIncompatible
if ($LASTEXITCODE) { throw 'Compatibility check failed.' }
$account = Invoke-WorkshopTool az @('account', 'show', '--output', 'json') | ConvertFrom-Json
if (-not $env:ARM_SUBSCRIPTION_ID -or $account.id -ne $env:ARM_SUBSCRIPTION_ID) { throw 'Set ARM_SUBSCRIPTION_ID and select the matching sandbox account in Azure CLI.' }
$group = Invoke-WorkshopTool az @('group', 'show', '--name', $ResourceGroupName, '--output', 'json') | ConvertFrom-Json
if ($group.properties.provisioningState -ne 'Succeeded') { throw 'The supplied resource group is not ready.' }
$required = @('Microsoft.Web', 'Microsoft.Storage', 'Microsoft.Insights', 'Microsoft.OperationalInsights')
if ($Lab -eq 'queue-worker') { $required += 'Microsoft.ServiceBus' }
if ($Lab -eq 'search-playground') { $required += 'Microsoft.Search' }
foreach ($namespace in $required) {
  $provider = Invoke-WorkshopTool az @('provider', 'show', '--namespace', $namespace, '--output', 'json') | ConvertFrom-Json
  if ($provider.registrationState -ne 'Registered') { throw "Required provider $namespace is not registered. No registration was attempted." }
}
$resources = Invoke-WorkshopTool az @('resource', 'list', '--output', 'json') | ConvertFrom-Json
if (@($resources | Where-Object type -eq 'Microsoft.Web/serverfarms').Count -ge 2) { throw 'The documented two-server-farm limit is already reached.' }
if ($Lab -eq 'search-playground' -and @($resources | Where-Object type -eq 'Microsoft.Search/searchServices').Count -ge 1) { throw 'An AI Search service already exists; this lab needs the one-service allowance.' }
Write-Host 'Preflight passed the documented region, account/group, provider-registration and visible resource-count checks.'
Write-Host 'Actual service capacity, all policy restrictions and application deployment permission still require a real run.'
