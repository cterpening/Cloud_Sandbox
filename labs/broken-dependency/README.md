# The Broken Storage Dependency

Investigate an API returning 503 because its table setting is wrong; repair it through Terraform and verify recovery.

**Implemented and offline-tested; not yet verified in a live sandbox.** Local mode
needs Python 3.11+ only. The first cloud target is Pluralsight's normal Azure
sandbox; the cloud run needs a fresh session, PowerShell 7, Azure CLI and Terraform.
Budget roughly 45 minutes for a first cloud attempt, not a measured completion time.

## What you can learn

Understand the components below, predict the result of the experiment, compare
local behavior with the actual Azure services, and preserve safe evidence before
cleanup.

## How it fits together

The Function's checkout handler reads a table selected by configuration. Terraform creates `items`, but the initial `DEPENDENCY_TABLE` setting is deliberately `missingitems`.

The Azure implementation adds the shared Functions host, LRS storage, Log Analytics,
Application Insights and a metric alert. Reuse the supplied resource group and run
one project at a time. See the [manifest](lab.json) for declared services and quotas.

## Run it

From the repository root:

```powershell
python apps/workshop/local.py --project broken-dependency
```

Open http://127.0.0.1:7071/api/ui and leave the key blank. For Azure preflight,
Terraform deployment and publishing, follow [Run a project](../../docs/run-a-project.md)
with `$lab = 'broken-dependency'`. The
[Azure implementation](implementations/azure/README.md) identifies the Terraform root.

## Try the experiment

1. Select **Checkout** and observe HTTP 503 with `dependency_unavailable`.
2. Health still returns 200: process health is different from dependency readiness.
3. Compare the app setting with the actual table name. Do not create a second table to hide the fault.
4. Locally, stop the process and restart it with:
   `python apps/workshop/local.py --project broken-dependency --dependency-table items`.
5. In Azure, set `dependency_table = "items"` in the ignored
   `sandbox.auto.tfvars`, then review `terraform plan` and approve `terraform apply`
   in this project's Terraform directory. The setting change restarts the app;
   no republish is required.
6. Check again with `--expect-repaired`. Checkout should now return 200.

## API and verification

`GET /api/checkout` → initial 503, then 200 with `checkout_ready` after repair. The normal checker expects the fault; add `--expect-repaired` only after changing the setting.

In another terminal, from the repository root:

```powershell
python scripts/check_project.py --project broken-dependency --evidence evidence/broken-dependency.json
```

For cloud mode add `--mode azure --base-url $base` and set the Function key in the
process environment as shown in the shared runbook. The checker exports only
allowlisted check labels, project, mode and pass status—not credentials or data.
Review relevant telemetry privately; automated functional checks do not certify
cloud monitoring or cleanup.

## Cleanup

Stop the local process with Ctrl+C; in-memory data disappears. After Azure use:

```powershell
pwsh scripts/Remove-Lab.ps1 -Lab broken-dependency
```

Review the saved destroy plan and type the exact Function App name when prompted.
This removes the deployment and its data, **not the assigned resource group**.
Keep state/plans private. Use fresh state for a new sandbox session.

## Sandbox compromise and production extension

Short-lived service keys and Function keys replace identities unavailable in this
sandbox. /32 ingress is a workshop safeguard, not end-user authorization.
Use readiness probes, configuration validation before release, alert routing, dependency tracing and controlled rollback. A deliberately broken startup configuration is a training scenario, not a production default.

## Troubleshooting

If the repaired app still returns 503, wait for restart and check the effective setting. A 502 is a different backend/authentication fault, not the expected missing-table scenario. See the [shared troubleshooting guide](../../docs/run-a-project.md#troubleshooting)
for access, provider, regional-capacity and publishing failures.

## Primary sources

Reviewed 2026-09-06; documentation review is not live verification.

- [Pluralsight Azure restrictions](https://help.pluralsight.com/hc/en-us/articles/24392988447636-Azure-cloud-sandbox)
- [Functions application settings](https://learn.microsoft.com/en-us/azure/azure-functions/functions-app-settings)
