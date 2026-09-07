[CmdletBinding()]
param([Parameter(Mandatory)][string]$Lab)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Workshop.Tools.ps1')
$deployment = Get-WorkshopDeployment $Lab
$planRoot = Join-Path (Split-Path $PSScriptRoot -Parent) 'artifacts/cleanup'
$null = New-Item -ItemType Directory -Path $planRoot -Force
$planPath = Join-Path $planRoot "$Lab-$([guid]::NewGuid().ToString('N')).tfplan"
$planText = Invoke-WorkshopTool terraform @("-chdir=$($deployment.Root)", 'plan', '-destroy', '-input=false', '-no-color', "-out=$planPath")
Write-Host $planText
$plan = Invoke-WorkshopTool terraform @("-chdir=$($deployment.Root)", 'show', '-json', $planPath) | ConvertFrom-Json -Depth 100
$deletions = @($plan.resource_changes | Where-Object { 'delete' -in $_.change.actions })
if (-not $deletions.Count) { Write-Host 'Nothing to destroy.'; return }
if (@($deletions | Where-Object type -eq 'azurerm_resource_group').Count) { throw 'Refusing to delete a resource group.' }
foreach ($change in $deletions) {
  if (-not $change.address.StartsWith('module.workshop.')) { throw 'Destroy plan includes an unrelated resource address.' }
  if ($change.change.before.id -match '(?i)^/subscriptions/([^/]+)/' -and $Matches[1] -ne $deployment.Account.id) {
    throw 'Destroy plan targets a different subscription.'
  }
  if ($change.change.before.id -match '(?i)/resourceGroups/([^/]+)/' -and $Matches[1] -ne $deployment.Output.resource_group_name.value) {
    throw 'Destroy plan targets a different group.'
  }
}
Write-Host "Project: $Lab"
Write-Host "Subscription (local display only): $($deployment.Account.id)"
Write-Host "Existing group retained: $($deployment.Output.resource_group_name.value)"
Write-Host "Resources to remove: $($deletions.Count)"
$confirmation = Read-Host "Type $($deployment.Output.function_name.value) to execute this saved destroy plan"
if ($confirmation -cne $deployment.Output.function_name.value) { Write-Host 'Cancelled.'; return }
# The explicit confirmation above immediately precedes the destructive action.
$null = Invoke-WorkshopTool terraform @("-chdir=$($deployment.Root)", 'apply', '-input=false', '-no-color', $planPath)
Write-Host 'Deployment removed. The assigned resource group was retained. Local state/plans may contain secrets; keep them private.'
