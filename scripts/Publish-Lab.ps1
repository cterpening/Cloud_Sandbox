[CmdletBinding()]
param([Parameter(Mandatory)][string]$Lab, [switch]$PackageOnly)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Workshop.Tools.ps1')
$null = Get-WorkshopRoot $Lab
$manifest = Get-WorkshopManifest $Lab
if ($manifest.execution -and $manifest.execution.azure -ne 'functions') {
  throw 'This project is not an Azure Function; follow its project guide instead of ZIP publishing.'
}
$repo = Split-Path $PSScriptRoot -Parent
$artifactRoot = Join-Path $repo 'artifacts/packages'
$null = New-Item -ItemType Directory -Path $artifactRoot -Force
$zip = Join-Path $artifactRoot "$Lab-$([guid]::NewGuid().ToString('N')).zip"
$app = Join-Path $repo 'apps/workshop'
# Explicit allowlist avoids packaging venvs, local settings, state or evidence.
$files = @('function_app.py', 'core.py', 'azure_adapters.py', 'azure_extras.py', 'experiments.py', 'corpus.json', 'index.html', 'host.json', 'requirements.txt') |
  ForEach-Object { Join-Path $app $_ }
Compress-Archive -LiteralPath $files -DestinationPath $zip
if ($PackageOnly) { Write-Output $zip; return }
$deployment = Get-WorkshopDeployment $Lab
$null = Invoke-WorkshopTool az @('functionapp', 'deployment', 'source', 'config-zip', '--resource-group', $deployment.Output.resource_group_name.value,
  '--name', $deployment.Output.function_name.value, '--src', $zip, '--build-remote', 'true', '--output', 'none')
Write-Host 'Package submitted. Run the functional checks after the Functions host finishes starting.'
