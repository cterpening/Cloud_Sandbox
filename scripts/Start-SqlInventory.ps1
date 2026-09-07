[CmdletBinding()]
param([string]$Python = 'python', [ValidateRange(1024, 65535)][int]$Port = 7071)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Workshop.Tools.ps1')
$deployment = Get-WorkshopDeployment 'sql-inventory'
$previousHost, $previousPassword = $env:WORKSHOP_SQL_HOST, $env:WORKSHOP_SQL_PASSWORD
try {
  $env:WORKSHOP_SQL_HOST = $deployment.Output.sql_host.value
  $env:WORKSHOP_SQL_PASSWORD = $deployment.Output.sql_password.value
  if (-not $env:WORKSHOP_SQL_PASSWORD) { throw 'SQL credentials are missing from this project state.' }
  Write-Host 'Starting the loopback application against Azure SQL. This creates its two tables if absent.'
  Write-Host 'The SQL password is passed only through the child process environment; do not export it.'
  Invoke-WorkshopInteractive $Python @((Join-Path $PSScriptRoot '../apps/workshop/local.py'),
    '--project', 'sql-inventory', '--backend', 'azure-sql', '--port', "$Port")
} finally {
  $env:WORKSHOP_SQL_HOST, $env:WORKSHOP_SQL_PASSWORD = $previousHost, $previousPassword
}
