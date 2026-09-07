[CmdletBinding()]
param(
  [string]$Lab,
  [ValidateSet('Local', 'Azure')][string]$Mode = 'Local',
  [string]$Domain,
  [ValidateRange(1, 1440)][int]$MaxMinutes = 1440,
  [switch]$List,
  [switch]$AsJson,
  [string]$Python = 'python',
  [ValidateRange(1024, 65535)][int]$Port = 7071
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Workshop.Tools.ps1')
$rows = @(Get-ChildItem (Join-Path $PSScriptRoot '../labs') -Directory | ForEach-Object {
  $path = Join-Path $_.FullName 'lab.json'
  if (Test-Path $path) {
    $manifest = Get-Content $path -Raw | ConvertFrom-Json
    if ($manifest.implementations.azure.status -in @('implemented', 'verified')) {
      [pscustomobject]@{
        id=$manifest.id; title=$manifest.title; domains=@($manifest.domains)
        minutes=$(if ($Mode -eq 'Local') { $manifest.execution.local_minutes } else { $manifest.implementations.azure.estimated_minutes })
        azure_runner=$manifest.execution.azure
      }
    }
  }
} | Where-Object { (!$Domain -or $Domain -in $_.domains) -and $_.minutes -le $MaxMinutes } | Sort-Object id)
if ($AsJson) { ConvertTo-Json -InputObject $rows -Depth 5; return }
if ($List) { $rows | Format-Table id, minutes, azure_runner, domains -AutoSize; return }
if (-not $rows.Count) { throw 'No projects match these filters.' }
if (-not $Lab) {
  for ($index = 0; $index -lt $rows.Count; $index++) {
    Write-Host ("{0}. {1} — {2} minutes (estimate)" -f ($index + 1), $rows[$index].title, $rows[$index].minutes)
  }
  $choice = Read-Host 'Choose a project number (Ctrl+C cancels)'
  $number = 0
  if (-not [int]::TryParse($choice, [ref]$number) -or $number -lt 1 -or $number -gt $rows.Count) { throw 'Invalid selection.' }
  $Lab = $rows[$number - 1].id
}
$manifest = Get-WorkshopManifest $Lab
if ($Lab -notin $rows.id) { throw 'This project does not match the selected filters.' }
if ($Mode -eq 'Azure') {
  Write-Host "Selected $($manifest.title). No cloud changes have been made."
  Write-Host "Read labs/$Lab/implementations/azure/README.md and docs/run-a-project.md."
  Write-Host "Terraform root: $(Get-WorkshopRoot $Lab)"
  Write-Host "Azure runner: $($manifest.execution.azure). Review preflight, plan and cleanup before applying."
  return
}
Invoke-WorkshopInteractive $Python @((Join-Path $PSScriptRoot '../apps/workshop/local.py'), '--project', $Lab, '--port', "$Port")
