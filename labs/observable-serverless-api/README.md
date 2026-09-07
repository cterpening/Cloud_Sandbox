# Observable Serverless API

Send normal, slow and failed requests; inspect correlation IDs, traces and a metric alert.

**Implemented and offline-tested; not yet verified in a live sandbox.** Local mode
needs Python 3.11+ only. The first cloud target is Pluralsight's normal Azure
sandbox; the cloud run needs a fresh session, PowerShell 7, Azure CLI and Terraform.
Budget roughly 75 minutes for a first cloud attempt, not a measured completion time.

## What you can learn

Understand the components below, predict the result of the experiment, compare
local behavior with the actual Azure services, and preserve safe evidence before
cleanup.

## How it fits together

Browser/checker → Function HTTP handler → structured traces → Application Insights/workspace and a metric alert. Storage is the Functions host backing store.

The Azure implementation adds the shared Functions host, LRS storage, Log Analytics,
Application Insights and a metric alert. Reuse the supplied resource group and run
one project at a time. See the [manifest](lab.json) for declared services and quotas.

## Run it

From the repository root:

```powershell
python apps/workshop/local.py --project observable-serverless-api
```

Open http://127.0.0.1:7071/api/ui and leave the key blank. For Azure preflight,
Terraform deployment and publishing, follow [Run a project](../../docs/run-a-project.md)
with `$lab = 'observable-serverless-api'`. The
[Azure implementation](implementations/azure/README.md) identifies the Terraform root.

## Try the experiment

1. Select **Normal request**, then **Slow request** in the experiment page.
2. Select **Failed request**. HTTP 500 is intentional, not a deployment failure.
3. Compare the returned correlation IDs with the structured `workshop_request` traces.
4. In Azure, run [the KQL queries](implementations/azure/investigate.kql) in the Log
   Analytics workspace. Repeat failures a few times and inspect the metric alert.
   It has no email/action group, and alert ingestion is not instantaneous.

## API and verification

`GET /api/work?mode=normal` → 200; `mode=slow` → 200 after ~250 ms of added application latency; `mode=fail` → 500. All return a synthetic correlation ID.

In another terminal, from the repository root:

```powershell
python scripts/check_project.py --project observable-serverless-api --evidence evidence/observable-serverless-api.json
```

For cloud mode add `--mode azure --base-url $base` and set the Function key in the
process environment as shown in the shared runbook. The checker exports only
allowlisted check labels, project, mode and pass status—not credentials or data.
Review relevant telemetry privately; automated functional checks do not certify
cloud monitoring or cleanup.

## Cleanup

Stop the local process with Ctrl+C; in-memory data disappears. After Azure use:

```powershell
pwsh scripts/Remove-Lab.ps1 -Lab observable-serverless-api
```

Review the saved destroy plan and type the exact Function App name when prompted.
This removes the deployment and its data, **not the assigned resource group**.
Keep state/plans private. Use fresh state for a new sandbox session.

## Sandbox compromise and production extension

Short-lived service keys and Function keys replace identities unavailable in this
sandbox. /32 ingress is a workshop safeguard, not end-user authorization.
Tune latency/error objectives and alert routing. Replace workshop keys with real application authentication and test realistic dependencies. A metric threshold alone is not an SLO.

## Troubleshooting

If requests work but logs appear empty, use the workspace output, widen the time range and allow ingestion time. The functional checker does not prove that telemetry ingestion or the cloud alert has fired. See the [shared troubleshooting guide](../../docs/run-a-project.md#troubleshooting)
for access, provider, regional-capacity and publishing failures.

## Primary sources

Reviewed 2026-09-06; documentation review is not live verification.

- [Pluralsight Azure restrictions](https://help.pluralsight.com/hc/en-us/articles/24392988447636-Azure-cloud-sandbox)
- [Application Insights overview](https://learn.microsoft.com/en-us/azure/azure-monitor/app/app-insights-overview)
- [Metric alert overview](https://learn.microsoft.com/en-us/azure/azure-monitor/alerts/alerts-types#metric-alerts)
