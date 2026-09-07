# Azure implementation: Queue Worker and Poison Messages

Status: implemented/offline-tested; live Pluralsight verification pending.

- Terraform root: [terraform/](terraform/).
- Shared infrastructure: [function-workshop module](../../../../modules/function-workshop/).
- Shared Azure Function workload: [apps/workshop](../../../../apps/workshop/).
- Deployment, preflight, evidence and cleanup: [runbook](../../../../docs/run-a-project.md).
- Experiment and expected results: [project guide](../../README.md).

Run commands from the repository root and select `$lab = 'queue-worker'`.
Each project has independent local Terraform state. Do not combine all five roots
in one session or reuse expired-session state. Supply the assigned resource group;
this implementation never creates or owns it.

To inspect the application ZIP without accessing Azure:

```powershell
pwsh scripts/Publish-Lab.ps1 -Lab queue-worker -PackageOnly
```

To check infrastructure without credentials:

```powershell
terraform -chdir=labs/queue-worker/implementations/azure/terraform init -backend=false
terraform -chdir=labs/queue-worker/implementations/azure/terraform validate
terraform -chdir=labs/queue-worker/implementations/azure/terraform test
```

The last command uses mock providers; it is not an Azure deployment test.
