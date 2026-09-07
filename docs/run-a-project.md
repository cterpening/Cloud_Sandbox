# Run a project

All five projects can be tried locally before spending a sandbox session. Python
3.11 or newer runs the local version with its standard library. Use `python3`
instead of `python` where that is your installed command. Cloud deployments use
Python 3.11, Functions runtime 4, Terraform 1.9+ (tested with 1.14.6), and the pinned
AzureRM 4.64.0 provider. Run commands from the repository root unless stated otherwise.

The Azure Functions Python package is pinned to 1.25.0 for the Python 3.11 host.
Package major version 2 requires Python 3.13+, so do not upgrade it independently
of the cloud runtime. The app still uses the decorator-based Python v2 programming
model; that model name is different from the package version.

## Start locally

Choose `observable-serverless-api`, `tiny-notes`, `queue-worker`,
`broken-dependency`, or `search-playground`:

```powershell
python apps/workshop/local.py --project tiny-notes
```

Open **http://127.0.0.1:7071/api/ui**. Leave the Function key blank. Pick an operation
for the selected project. In another terminal:

```powershell
python scripts/check_project.py --project tiny-notes --evidence evidence/tiny-notes.json
```

Stop with Ctrl+C. Local tables/queues/search live in memory and reset on restart.
They exercise application behavior, not Azure scaling, permissions, quotas,
networking or delivery timing. Local search uses token overlap; Azure uses its
actual search engine. Different rankings outside the golden examples are expected.

## Deploy in Pluralsight Azure

Start the **normal Azure cloud sandbox** in Pluralsight. You need eligible access,
Azure CLI 2.48.1 or newer, PowerShell 7, Terraform and Python installed locally. Terraform provisions
resources inside the sandbox; it does not create the Pluralsight session.

1. Sign into Azure CLI using the temporary sandbox account. Select its subscription.
   Never paste the password into a tracked file or a command saved in Git.
2. Set the subscription only in your current terminal and choose a project:

   ```powershell
   az login
   az account set --subscription YOUR_SANDBOX_SUBSCRIPTION
   $env:ARM_SUBSCRIPTION_ID = az account show --query id -o tsv
   $lab = 'tiny-notes'
   $tf = "labs/$lab/implementations/azure/terraform"
   Copy-Item "$tf/sandbox.auto.tfvars.example" "$tf/sandbox.auto.tfvars"
   ```

3. Edit the ignored `sandbox.auto.tfvars`: set the assigned group name, an approved
   region, and your workstation's **public IPv4 /32**. `192.0.2.10` is a documentation
   placeholder, not your address. Use the public address shown by your router/network
   tools; do not use your private LAN address. Use the same egress network for Azure CLI
   publishing and the browser. VPN changes can change the required address.
4. Check the session before provisioning:

   ```powershell
   pwsh scripts/Test-AzureSandbox.ps1 -Lab $lab -ResourceGroupName YOUR_ASSIGNED_GROUP -Location eastus
   terraform "-chdir=$tf" init
   terraform "-chdir=$tf" plan
   terraform "-chdir=$tf" apply
   ```

   Read and approve the plan. There must be **no resource-group creation or role
   assignment**. Provider auto-registration is disabled; missing providers cause
   preflight to stop. Run one project at a time to preserve the two-plan allowance.
5. Publish the application with an explicit remote build:

   ```powershell
   pwsh scripts/Publish-Lab.ps1 -Lab $lab
   $name = terraform "-chdir=$tf" output -raw function_name
   $group = terraform "-chdir=$tf" output -raw resource_group_name
   $base = terraform "-chdir=$tf" output -raw base_url
   $env:WORKSHOP_FUNCTION_KEY = az functionapp keys list --name $name --resource-group $group --query functionKeys.default -o tsv
   python scripts/check_project.py --project $lab --mode azure --base-url $base --evidence "evidence/$lab.json"
   ```

   The checker sends the key as a header. Do not put it in the URL. For the browser
   page at `$base/api/ui`, retrieve the key privately in the portal and enter it in
   the password field; the page does not persist it. Every data endpoint requires a
   Function key, and the app/SCM endpoints also have the /32 restriction. The static
   UI route contains no data. Give a freshly deployed Functions host time to start.

## Investigate and clean up

Use Application Insights or the workspace named by `workspace_name` to inspect
requests. The [API queries](../labs/observable-serverless-api/implementations/azure/investigate.kql)
also work for the other apps. The included alert has no external notification
action; view its condition in Azure Monitor after generating failures. Telemetry
and alert ingestion can take minutes. Export the checker's allowlisted evidence
summary, not raw state, URLs, connection strings or portal exports.

```powershell
pwsh scripts/Remove-Lab.ps1 -Lab $lab
```

This checks the active subscription against the state, displays a saved destroy
plan, refuses resource-group deletion, and asks you to type the exact Function App
name immediately before applying that plan. It removes the deployment and its
application data. The assigned resource group remains. State, packages and plans
remain local and ignored; treat them as sensitive. Start each new sandbox session
from a fresh checkout/state directory; never reuse another session's state blindly.

## Troubleshooting

- **Unsigned PowerShell file blocked:** inspect downloaded scripts first. On a
  workstation where you are permitted to run them, a per-process invocation is
  `pwsh -ExecutionPolicy Bypass -File scripts/Test-Catalog.ps1`. It does not alter
  the machine's persistent execution policy. Follow your organization's policy.
- **403 from the Function or SCM endpoint:** check the /32 address, VPN/egress,
  selected subscription and Function key. Do not widen access to everyone as a fix.
- **Provider not registered:** stop. This collection does not grant itself
  subscription administration rights. A sandbox session with the required
  providers must be available before deployment.
- **Y1 plan or search provisioning rejected:** documented service support does not
  guarantee capacity in every approved region. Check the provider error and choose
  another documented region only after reviewing any replacement plan.
- **ZIP deployment/build rejected:** inspect the Azure CLI and remote-build result.
  App deployment is a separate permission from resource creation. Do not claim the
  lab verified until both succeed. No publishing passwords are embedded in the repo.
- **Search empty just after seeding:** allow index ingestion to finish. The checker
  retries for a bounded period. Only one small index/service is used.
- **Queue has no receipts:** check the Functions `order_worker` trigger, connection
  setting and Service Bus host extension logs. Cloud retries are asynchronous;
  `/api/tick` exists only in the local stand-in.
- **Cloud checker exits 1:** it intentionally prints a sanitized error category.
  Inspect the selected operation in the experiment page and Azure logs privately.

## What a production version changes

The sample uses short-lived storage/Service Bus/search credentials because the
normal Pluralsight profile does not offer managed identities. Function keys and
IP restrictions are workshop access controls, not an end-user identity system.
Production needs least-privilege workload identity, appropriate private networking,
durable protected state, proper user authentication, budget/retention controls,
dependency maintenance and recovery testing. The toy receipt is the queue worker's
entire side effect; adding real payments or other effects requires a transactional
idempotency design.

Sources reviewed 2026-09-06:

- [Pluralsight Azure restrictions](https://help.pluralsight.com/hc/en-us/articles/24392988447636-Azure-cloud-sandbox)
- [Starting a sandbox and session limits](https://help.pluralsight.com/hc/en-us/articles/24425549311380-Cloud-sandboxes-getting-started)
- [AzureRM CLI authentication](https://registry.terraform.io/providers/hashicorp/azurerm/4.64.0/docs/guides/azure_cli)
- [Functions ZIP deployment](https://learn.microsoft.com/en-us/azure/azure-functions/deployment-zip-push)
- [Functions Python SDK 1.25.0 runtime requirement](https://pypi.org/project/azure-functions/1.25.0/)
- [Functions Python SDK 2.3.0 runtime requirement](https://pypi.org/project/azure-functions/2.3.0/)
- [CLI deployment without publishing-password authentication](https://learn.microsoft.com/en-us/azure/app-service/configure-basic-auth-disable#deploy-without-basic-authentication)

These are implemented examples with offline checks. A Pluralsight verification
record requires an actual successful deployment, experiment and cleanup session.
