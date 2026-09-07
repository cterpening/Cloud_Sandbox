[CmdletBinding()]
param(
  [Parameter()]
  [string]$RepositoryRoot = (Split-Path -Parent $PSScriptRoot),

  [Parameter()]
  [switch]$AsJson
)

$ErrorActionPreference = 'Stop'
$repositoryPath = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$labFiles = Get-ChildItem -LiteralPath (Join-Path $repositoryPath 'labs') -Filter 'lab.json' -Recurse -File
$rows = [System.Collections.Generic.List[object]]::new()

foreach ($file in $labFiles) {
  $lab = Get-Content -LiteralPath $file.FullName -Raw | ConvertFrom-Json -Depth 100
  foreach ($implementationProperty in $lab.implementations.PSObject.Properties) {
    $implementation = $implementationProperty.Value
    $rows.Add([pscustomobject]@{
        lab_id             = $lab.id
        title              = $lab.title
        domains            = @($lab.domains) -join ', '
        local_minutes      = $lab.execution.local_minutes
        azure_runner       = $lab.execution.azure
        lab_state          = $lab.state
        difficulty         = $lab.difficulty
        time_tier          = $lab.time_tier
        cloud              = $implementationProperty.Name
        implementation     = $implementation.status
        estimated_minutes  = $implementation.estimated_minutes
        required_services  = @($implementation.required_services) -join ', '
      })
  }
}

$orderedRows = @($rows | Sort-Object lab_id, cloud)

if ($AsJson) {
  ConvertTo-Json -InputObject $orderedRows -Depth 10
}
else {
  $orderedRows | Format-Table -AutoSize lab_id, cloud, lab_state, implementation, estimated_minutes, required_services
}
