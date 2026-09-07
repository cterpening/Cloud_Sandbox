function Invoke-WorkshopTool {
  [CmdletBinding()]
  param([Parameter(Mandatory)][string]$Name, [string[]]$Arguments = @())
  $command = Get-Command $Name -CommandType Application -ErrorAction Stop | Select-Object -First 1
  if ($IsWindows -and [IO.Path]::GetExtension($command.Source) -in @('.cmd', '.bat')) {
    # Azure CLI is commonly a .cmd launcher on Windows. Use PowerShell's native
    # launcher with an argument array; fail explicitly if nothing was executed.
    $global:LASTEXITCODE = $null
    $result = & $command.Source @Arguments 2>&1
    if ($null -eq $LASTEXITCODE -or $LASTEXITCODE -ne 0) { throw "$Name failed; inspect your local CLI installation/authentication." }
    return ($result | Out-String).Trim()
  }
  $start = [Diagnostics.ProcessStartInfo]::new($command.Source)
  $start.UseShellExecute = $false
  $start.RedirectStandardOutput = $true
  $start.RedirectStandardError = $true
  foreach ($argument in $Arguments) { $start.ArgumentList.Add($argument) }
  $process = [Diagnostics.Process]::Start($start)
  $stdout = $process.StandardOutput.ReadToEndAsync()
  $stderr = $process.StandardError.ReadToEndAsync()
  $process.WaitForExit()
  if ($process.ExitCode -ne 0) {
    # Provider/CLI stderr may contain account identifiers. Keep it local and do
    # not include it in exported evidence. The caller sees a bounded error.
    throw "$Name exited $($process.ExitCode). Rerun that command locally for provider diagnostics."
  }
  return $stdout.Result.Trim()
}

function Get-WorkshopRoot {
  param([Parameter(Mandatory)][string]$Lab)
  $null = Get-WorkshopManifest $Lab
  return (Resolve-Path (Join-Path $PSScriptRoot "../labs/$Lab/implementations/azure/terraform")).Path
}

function Get-WorkshopManifest {
  param([Parameter(Mandatory)][string]$Lab)
  if ($Lab -notmatch '^[a-z][a-z0-9-]*$') { throw 'Invalid project identifier.' }
  $path = Join-Path $PSScriptRoot "../labs/$Lab/lab.json"
  if (-not (Test-Path -LiteralPath $path)) { throw 'Unknown project.' }
  $manifest = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
  if ($manifest.id -ne $Lab -or $manifest.implementations.azure.status -notin @('implemented', 'verified')) {
    throw 'The selected project has no executable Azure implementation.'
  }
  return $manifest
}

function Invoke-WorkshopInteractive {
  param([Parameter(Mandatory)][string]$Name, [string[]]$Arguments = @())
  $command = Get-Command $Name -CommandType Application -ErrorAction Stop | Select-Object -First 1
  $start = [Diagnostics.ProcessStartInfo]::new($command.Source)
  $start.UseShellExecute = $false
  $start.WorkingDirectory = Split-Path $PSScriptRoot -Parent
  foreach ($argument in $Arguments) { $start.ArgumentList.Add($argument) }
  $process = [Diagnostics.Process]::Start($start)
  $process.WaitForExit()
  if ($process.ExitCode) { throw "$Name exited with code $($process.ExitCode)." }
}

function Get-WorkshopDeployment {
  param([Parameter(Mandatory)][string]$Lab)
  $root = Get-WorkshopRoot $Lab
  $output = Invoke-WorkshopTool terraform @("-chdir=$root", 'output', '-json') | ConvertFrom-Json
  $resourceName = if ($output.resource_name) { $output.resource_name.value } else { $output.function_name.value }
  if ($output.project.value -ne $Lab -or -not $resourceName) {
    throw 'The Terraform state does not describe the selected project.'
  }
  $account = Invoke-WorkshopTool az @('account', 'show', '--output', 'json') | ConvertFrom-Json
  if (-not $env:ARM_SUBSCRIPTION_ID -or $account.id -ne $env:ARM_SUBSCRIPTION_ID) {
    throw 'Select the sandbox subscription and set ARM_SUBSCRIPTION_ID to the same value.'
  }
  $state = Invoke-WorkshopTool terraform @("-chdir=$root", 'show', '-json') | ConvertFrom-Json -Depth 100
  function Get-StateResources($Module) {
    @($Module.resources)
    foreach ($child in @($Module.child_modules)) { if ($child) { Get-StateResources $child } }
  }
  $resources = @(Get-StateResources $state.values.root_module | Where-Object { $_ -and $_.mode -eq 'managed' })
  if (@($resources | Where-Object type -eq 'azurerm_resource_group').Count) {
    throw 'Refusing a deployment state that owns a resource group.'
  }
  foreach ($resource in $resources) {
    if (-not $resource.address.StartsWith('module.workshop.')) {
      throw 'State contains resources outside the selected workshop module.'
    }
    if ($resource.values.id -match '(?i)^/subscriptions/([^/]+)/') {
      if ($Matches[1] -ne $account.id) { throw 'State belongs to a different subscription. Stop and check the session.' }
    }
    if ($resource.values.id -match '(?i)/resourceGroups/([^/]+)/') {
      if ($Matches[1] -ne $output.resource_group_name.value) { throw 'State contains a resource in a different group.' }
    }
  }
  return [pscustomobject]@{Root=$root; Output=$output; Account=$account; Resources=$resources; ResourceName=$resourceName}
}
