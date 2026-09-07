# Azure implementation: Tiny Notes App

Status: implemented/offline-tested; live Pluralsight verification pending.

- Terraform root: [terraform/](terraform/).
- Shared infrastructure: [function-workshop module](../../../../modules/function-workshop/).
- Shared Azure Function workload: [apps/workshop](../../../../apps/workshop/).
- Deployment, preflight, evidence and cleanup: [runbook](../../../../docs/run-a-project.md).
- Experiment and expected results: [project guide](../../README.md).

Run commands from the repository root and select `$lab = 'tiny-notes'`.
Each project has independent local Terraform state. Do not combine independent roots
in one session or reuse expired-session state. Supply the assigned resource group;
this implementation never creates or owns it.

To inspect the application ZIP without accessing Azure:

```powershell
pwsh scripts/Publish-Lab.ps1 -Lab tiny-notes -PackageOnly
```

To check infrastructure without credentials:

```powershell
terraform -chdir=labs/tiny-notes/implementations/azure/terraform init -backend=false
terraform -chdir=labs/tiny-notes/implementations/azure/terraform validate
terraform -chdir=labs/tiny-notes/implementations/azure/terraform test
```

The last command uses mock providers; it is not an Azure deployment test.
