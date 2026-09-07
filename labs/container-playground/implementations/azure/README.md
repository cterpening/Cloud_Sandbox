# Azure implementation: Container Playground

Uses the [container-workshop module](../../../../modules/container-workshop/)
and [original workload](../../../../apps/workshop/). Status: implemented/offline
checked, **not live Pluralsight verified**.

## Prepare and deploy

First follow account selection and prerequisites in the [shared runbook](../../../../docs/run-a-project.md).
Run from the repository root in a fresh session with the assigned resource group.
Terraform must never create or own that group.

```powershell
$lab = 'container-playground'
$tf = "labs/$lab/implementations/azure/terraform"
Copy-Item "$tf/sandbox.auto.tfvars.example" "$tf/sandbox.auto.tfvars"
```

Edit the ignored file with your assigned group and an approved region. Leave `app_version = "v1"` and `broken_startup = false`. No workstation CIDR is
needed: this isolated ACI group has no public endpoint. The optional
`container_image` accepts the approved Python base tag family or a Python digest.

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
pwsh scripts/Test-AzureProject.ps1 -Lab $lab -Evidence "evidence/$lab-azure.json"
```

This uses the active Azure CLI session and matching Terraform state. It does not
use Function ZIP publishing or a Function key. Checks inspect running state and the requested version's startup-probe log, or the intentionally broken startup marker.

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
