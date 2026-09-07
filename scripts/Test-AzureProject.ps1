[CmdletBinding()]
param(
  [Parameter(Mandatory)][ValidateSet('network-detective', 'container-playground')][string]$Lab,
  [string]$Evidence
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Workshop.Tools.ps1')
$deployment = Get-WorkshopDeployment $Lab
$group = $deployment.Output.resource_group_name.value
$checks = [Collections.Generic.List[string]]::new()
if ($Lab -eq 'network-detective') {
  # Fixed repository-owned read-only probe, not user-supplied shell interpolation.
  $bytes = [IO.File]::ReadAllBytes((Join-Path $PSScriptRoot 'network_probe.py'))
  $encoded = [Convert]::ToBase64String($bytes)
  $script = "printf '%s' '$encoded' | base64 --decode | python3"
  $response = Invoke-WorkshopTool az @('vm', 'run-command', 'invoke', '--resource-group', $group,
    '--name', $deployment.Output.client_vm_name.value, '--command-id', 'RunShellScript', '--scripts', $script, '--output', 'json') | ConvertFrom-Json
  $message = @($response.value | ForEach-Object message) -join "`n"
  if ($message -notmatch 'WORKSHOP_PROBE=(\{[^\r\n]+\})') { throw 'The private VM probe did not return evidence. Check VM agent/Run Command availability.' }
  $actual = $Matches[1] | ConvertFrom-Json
  $fault = $deployment.Output.fault.value
  $expected = switch ($fault) {
    'healthy' { @{dns_matches_server=$true; direct_connection=$true; named_connection=$true} }
    'nsg' { @{dns_matches_server=$true; direct_connection=$false; named_connection=$false} }
    'dns' { @{dns_matches_server=$false; direct_connection=$true; named_connection=$false} }
    default { throw 'Unknown fault in state.' }
  }
  foreach ($key in $expected.Keys) {
    if ($actual.$key -isnot [bool] -or $actual.$key -ne $expected[$key]) { throw "Probe mismatch: $key. Check provisioning, DNS propagation and the selected fault." }
    $checks.Add("Private VM probe: $key matches $fault")
  }
} else {
  $groupState = Invoke-WorkshopTool az @('container', 'show', '--resource-group', $group,
    '--name', $deployment.ResourceName, '--output', 'json') | ConvertFrom-Json
  $logs = Invoke-WorkshopTool az @('container', 'logs', '--resource-group', $group,
    '--name', $deployment.ResourceName, '--container-name', 'workshop')
  $container = @($groupState.containers | Where-Object name -eq 'workshop')
  if ($container.Count -ne 1) { throw 'Expected exactly one workshop container.' }
  if ($deployment.Output.broken_startup.value) {
    if ($logs -notmatch '"event":\s*"intentional_startup_failure"') { throw 'Expected startup failure was not observed.' }
    $checks.Add('Intentional startup failure appears in container logs')
  } else {
    $version = $deployment.Output.app_version.value
    if ($container[0].instanceView.currentState.state -ne 'Running') { throw 'Container is not running; inspect events locally.' }
    $markers = @($logs -split "`r?`n" | Where-Object { $_ -match '^\{.*"event":\s*"container_started"' } | ForEach-Object { $_ | ConvertFrom-Json })
    $latest = $markers | Select-Object -Last 1
    if (-not $latest -or $latest.version -ne $version -or $latest.startup_probe -ne 'passed') { throw 'Current version has no passing startup health probe.' }
    $checks.Add('Container is running with the requested version and a passing startup HTTP probe')
  }
}
$result = [ordered]@{project=$Lab; mode='azure'; passed=$true; checks=@($checks)}
$json = $result | ConvertTo-Json -Depth 5
Write-Output $json
if ($Evidence) {
  $parent = Split-Path ([IO.Path]::GetFullPath($Evidence)) -Parent
  $null = New-Item -ItemType Directory -Path $parent -Force
  $json | Set-Content -LiteralPath $Evidence -Encoding utf8
}
