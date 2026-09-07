# Azure implementation: File-processing Pipeline

Uses the [function-workshop module](../../../../modules/function-workshop/)
and [original workload](../../../../apps/workshop/). Status: implemented/offline
checked, **not live Pluralsight verified**.

## Prepare and deploy

First follow account selection and prerequisites in the [shared runbook](../../../../docs/run-a-project.md).
Run from the repository root in a fresh session with the assigned resource group.
Terraform must never create or own that group.

```powershell
$lab = 'file-pipeline'
$tf = "labs/$lab/implementations/azure/terraform"
Copy-Item "$tf/sandbox.auto.tfvars.example" "$tf/sandbox.auto.tfvars"
```

Edit the ignored file with your assigned group and an approved region. Set `client_cidr` to your current workstation's public IPv4 /32, not the synthetic
example address. Keep the same egress network for application access.

```powershell
pwsh scripts/Test-AzureSandbox.ps1 -Lab $lab -ResourceGroupName YOUR_ASSIGNED_GROUP -Location eastus
terraform "-chdir=$tf" init
terraform "-chdir=$tf" plan
terraform "-chdir=$tf" apply
```

Use the same location in preflight and tfvars. Review the proposed resources and
explicitly approve apply. Do not run an unattended apply or combine roots.

## Run and verify

```powershell
pwsh scripts/Publish-Lab.ps1 -Lab $lab
$name = terraform "-chdir=$tf" output -raw function_name
$group = terraform "-chdir=$tf" output -raw resource_group_name
$base = terraform "-chdir=$tf" output -raw base_url
$env:WORKSHOP_FUNCTION_KEY = az functionapp keys list --name $name --resource-group $group --query functionKeys.default -o tsv
python scripts/check_project.py --project $lab --mode azure --base-url $base --evidence "evidence/$lab-azure.json"
Remove-Item Env:WORKSHOP_FUNCTION_KEY
```

Wait for the Functions host/trigger to start. API requests require a Function key;
never include the key in a URL, commit, issue or evidence file.

Follow the [project's Try / Break / Remix guide](../../README.md) for expected
results and repair. For Terraform-controlled faults, edit the ignored tfvars,
review `plan`, approve `apply`, then check again.

## Cleanup

```powershell
pwsh scripts/Remove-Lab.ps1 -Lab $lab
```

Review the saved destroy plan and type the exact displayed resource name
immediately before cleanup. This deletes project data. It leaves the assigned
group and ignored local state/evidence; never reuse another session's state.

## Offline infrastructure checks

```powershell
terraform "-chdir=$tf" init -backend=false
terraform "-chdir=$tf" fmt -check
terraform "-chdir=$tf" validate
terraform "-chdir=$tf" test
```

Mock providers validate plan contracts, not live cloud provisioning. Primary
sources and production differences are in the [project guide](../../README.md).
