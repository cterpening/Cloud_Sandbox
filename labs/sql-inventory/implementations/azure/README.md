# Azure implementation: Tiny SQL Inventory

Uses the [sql-workshop module](../../../../modules/sql-workshop/)
and [original workload](../../../../apps/workshop/). Status: implemented/offline
checked, **not live Pluralsight verified**.

## Prepare and deploy

First follow account selection and prerequisites in the [shared runbook](../../../../docs/run-a-project.md).
Run from the repository root in a fresh session with the assigned resource group.
Terraform must never create or own that group.

```powershell
$lab = 'sql-inventory'
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
python -m pip install -r apps/workshop/requirements-sql.txt
pwsh scripts/Start-SqlInventory.ps1
```

The launcher creates the application's schema if absent and keeps SQL credentials
in process memory/environment. In a second terminal:

```powershell
python scripts/check_project.py --project sql-inventory --mode azure-sql --evidence evidence/sql-inventory-azure.json
```

The browser is still at loopback; only the database is in Azure. Stop the app with
Ctrl+C before cleanup. Do not run `terraform output -json` into a shared log: it
contains the sensitive SQL password even though normal output redacts it.

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
