# Tiny Notes App

Run a small browser/API application backed by Azure Table Storage, then restart the client and read the saved notes.

**Implemented and offline-tested; not yet verified in a live sandbox.** Local mode
needs Python 3.11+ only. The first cloud target is Pluralsight's normal Azure
sandbox; the cloud run needs a fresh session, PowerShell 7, Azure CLI and Terraform.
Budget roughly 45 minutes for a first cloud attempt, not a measured completion time.

## What you can learn

Understand the components below, predict the result of the experiment, compare
local behavior with the actual Azure services, and preserve safe evidence before
cleanup.

## How it fits together

Browser/checker → Function HTTP handler → the `items` Azure table, with a notes partition. The local adapter instead uses a process-local list.

The Azure implementation adds the shared Functions host, LRS storage, Log Analytics,
Application Insights and a metric alert. Reuse the supplied resource group and run
one project at a time. See the [manifest](lab.json) for declared services and quotas.

## Run it

From the repository root:

```powershell
python apps/workshop/local.py --project tiny-notes
```

Open http://127.0.0.1:7071/api/ui and leave the key blank. For Azure preflight,
Terraform deployment and publishing, follow [Run a project](../../docs/run-a-project.md)
with `$lab = 'tiny-notes'`. The
[Azure implementation](implementations/azure/README.md) identifies the Terraform root.

## Try the experiment

1. Send `{"text":"Remember to test cleanup"}` using **Create note**.
2. Select **List notes** and find its returned ID.
3. Refresh the browser and list again. In Azure, the table—not the browser—holds the data.
4. Stop and restart the local runner: its notes disappear. Compare that with reading
   the Azure table from a fresh client while the sandbox still exists.
5. Try an empty note or more than 500 characters and expect HTTP 400.

## API and verification

`POST /api/notes` with a text field → 201 and an opaque ID. `GET /api/notes` → up to 100 notes. This is a bounded single-user demo; it has no edit/delete or account system.

In another terminal, from the repository root:

```powershell
python scripts/check_project.py --project tiny-notes --evidence evidence/tiny-notes.json
```

For cloud mode add `--mode azure --base-url $base` and set the Function key in the
process environment as shown in the shared runbook. The checker exports only
allowlisted check labels, project, mode and pass status—not credentials or data.
Review relevant telemetry privately; automated functional checks do not certify
cloud monitoring or cleanup.

## Cleanup

Stop the local process with Ctrl+C; in-memory data disappears. After Azure use:

```powershell
pwsh scripts/Remove-Lab.ps1 -Lab tiny-notes
```

Review the saved destroy plan and type the exact Function App name when prompted.
This removes the deployment and its data, **not the assigned resource group**.
Keep state/plans private. Use fresh state for a new sandbox session.

## Sandbox compromise and production extension

Short-lived service keys and Function keys replace identities unavailable in this
sandbox. /32 ingress is a workshop safeguard, not end-user authorization.
Add end-user authentication, per-user authorization, pagination, concurrency handling, backup/recovery and a least-privilege workload identity. Sandbox expiration destroys the cloud data.

## Troubleshooting

HTTP 502 suggests a storage/authentication problem; inspect it privately in Azure. The checker uses synthetic notes and repeated runs add records; begin a fresh deployment before exceeding the demo's 100-row read window. See the [shared troubleshooting guide](../../docs/run-a-project.md#troubleshooting)
for access, provider, regional-capacity and publishing failures.

## Primary sources

Reviewed 2026-09-06; documentation review is not live verification.

- [Pluralsight Azure restrictions](https://help.pluralsight.com/hc/en-us/articles/24392988447636-Azure-cloud-sandbox)
- [Azure Tables Python client](https://learn.microsoft.com/en-us/python/api/overview/azure/data-tables-readme?view=azure-python)
