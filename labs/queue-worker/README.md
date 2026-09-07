# Queue Worker and Poison Messages

Submit synthetic orders, inspect idempotent receipts, and watch poison messages move to the dead-letter queue.

**Implemented and offline-tested; not yet verified in a live sandbox.** Local mode
needs Python 3.11+ only. The first cloud target is Pluralsight's normal Azure
sandbox; the cloud run needs a fresh session, PowerShell 7, Azure CLI and Terraform.
Budget roughly 75 minutes for a first cloud attempt, not a measured completion time.

## What you can learn

Understand the components below, predict the result of the experiment, compare
local behavior with the actual Azure services, and preserve safe evidence before
cleanup.

## How it fits together

Browser/checker → HTTP sender → Service Bus orders queue → Function trigger → atomic Table Storage receipt. Failed poison messages are retried by Service Bus and move to its dead-letter subqueue.

The Azure implementation adds the shared Functions host, LRS storage, Log Analytics,
Application Insights and a metric alert. Reuse the supplied resource group and run
one project at a time. See the [manifest](lab.json) for declared services and quotas.

## Run it

From the repository root:

```powershell
python apps/workshop/local.py --project queue-worker
```

Open http://127.0.0.1:7071/api/ui and leave the key blank. For Azure preflight,
Terraform deployment and publishing, follow [Run a project](../../docs/run-a-project.md)
with `$lab = 'queue-worker'`. The
[Azure implementation](implementations/azure/README.md) identifies the Terraform root.

## Try the experiment

1. Submit `{"id":"demo-001","kind":"normal"}` twice.
2. Locally, select **Process one message** twice. In Azure, the trigger runs asynchronously;
   there is no `/api/tick` route.
3. List receipts: `demo-001` must appear once.
4. Submit `{"id":"broken-001","kind":"poison"}`. Locally process it three times;
   in Azure allow the broker/worker retries to run.
5. Inspect dead letters. Resubmit the same ID with `"kind":"normal"` and process/read
   again. A receipt should now exist; the original dead letter remains for inspection.
   This sample does not acknowledge or delete dead-letter messages.

## API and verification

`POST /api/messages` → 202; `GET /api/receipts` → receipt IDs; `GET /api/deadletters` → up to 10 peeked messages. IDs accept 1–64 letters, digits or hyphens. Only `normal` and `poison` kinds are accepted.

In another terminal, from the repository root:

```powershell
python scripts/check_project.py --project queue-worker --evidence evidence/queue-worker.json
```

For cloud mode add `--mode azure --base-url $base` and set the Function key in the
process environment as shown in the shared runbook. The checker exports only
allowlisted check labels, project, mode and pass status—not credentials or data.
Review relevant telemetry privately; automated functional checks do not certify
cloud monitoring or cleanup.

## Cleanup

Stop the local process with Ctrl+C; in-memory data disappears. After Azure use:

```powershell
pwsh scripts/Remove-Lab.ps1 -Lab queue-worker
```

Review the saved destroy plan and type the exact Function App name when prompted.
This removes the deployment and its data, **not the assigned resource group**.
Keep state/plans private. Use fresh state for a new sandbox session.

## Sandbox compromise and production extension

Short-lived service keys and Function keys replace identities unavailable in this
sandbox. /32 ingress is a workshop safeguard, not end-user authorization.
The receipt is the worker's entire side effect, so atomic insertion makes retries harmless. Real payments or multi-system effects require transactional/outbox design. Split send/listen credentials or identities, and add poison-message remediation and alerting.

## Troubleshooting

Allow cloud delivery time and inspect the order_worker trigger if no receipt appears. Old dead letters can fill the ten-message peek window; use a fresh deployment for a clean check. Basic-tier broker duplicate detection is not required: deduplication here is application-level. See the [shared troubleshooting guide](../../docs/run-a-project.md#troubleshooting)
for access, provider, regional-capacity and publishing failures.

## Primary sources

Reviewed 2026-09-06; documentation review is not live verification.

- [Pluralsight Azure restrictions](https://help.pluralsight.com/hc/en-us/articles/24392988447636-Azure-cloud-sandbox)
- [Service Bus dead-letter queues](https://learn.microsoft.com/en-us/azure/service-bus-messaging/service-bus-dead-letter-queues)
- [Functions Service Bus trigger](https://learn.microsoft.com/en-us/azure/azure-functions/functions-bindings-service-bus-trigger)
