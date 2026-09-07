# File-processing Pipeline

Upload synthetic documents, route BlobCreated events through a queue, and inspect processed or rejected results.

**Implemented and offline-tested; not live-sandbox verified.** Normal Pluralsight
Azure is the first target. Use synthetic data and run one project at a time.

## Architecture card

Browser/API → private inbox blob → Event Grid → storage queue → Function worker → processed/rejected blobs

One Y1 Function plan and storage account, four private containers, one queue, one Event Grid system topic/subscription, and shared telemetry.

Estimate: 15 minutes locally, 75 minutes for the Azure exercise including
inspection and cleanup. These are planning estimates, not measured durations.

## Start

From the repository root, use Python 3.11+:

```powershell
python apps/workshop/local.py --project file-pipeline
```

Open **http://127.0.0.1:7071/api/ui**. In another terminal:

```powershell
python scripts/check_project.py --project file-pipeline --evidence evidence/file-pipeline-local.json
```

For Azure prerequisites and deployment, use the [implementation guide](implementations/azure/README.md)
and [shared runbook](../../docs/run-a-project.md). A local pass is not cloud proof.

## Try

Start the local project, then choose **Files: upload synthetic document** in the page.
The default JSON contains one item with quantity 3. Choose **process once** locally,
then **inspect results**: the output is processed with total_quantity 3. Azure
processes queue deliveries automatically; its API has no tick endpoint.

Run the checker to upload both valid and malformed documents and wait for their
outcomes. Repeated input IDs return 409: choose a fresh synthetic ID for each new file.

## Break

Change the uploaded content string to `not-json`: it should appear as rejected,
not as a successful empty document. Resubmit the same ID and observe 409. Unit
tests additionally replay an identical event and verify deterministic output.

Event-delivery dead letters (`event-deadletters` blobs) are different from Function
processing failures (`file-events-poison` queue, created by the host). Inspect
these privately if a cloud file never completes.

## Remix

Change the item validator, add a bounded summary field, or write a second original
document fixture. Keep IDs immutable and output deterministic. Do not add
untrusted URL downloads or real customer files.

## Tradeoffs and production extension

The queue delivery path keeps the Function's workstation /32 ingress rule intact.
Storage endpoints remain public but key-authenticated; containers deny anonymous
access. The host accepts raw queue messages and our decoder accepts either JSON
or one base64 envelope. Each message must contain one event.

This demo uses one immutable input ID to overwrite one deterministic result; it
does not provide a general exactly-once processing guarantee. Production needs
version-aware idempotency, least-privilege identity, private service access,
retention and replay procedures.

## Evidence and cleanup

Keep the checker's allowlisted summary and a short synthetic observation about
failure and recovery. Do not publish raw state, identifiers, secrets or portal
exports. Local mode stops with Ctrl+C; Docker's --rm removes its stopped container.

After Azure work, inspect the scope and confirm the resource name when prompted:

```powershell
pwsh scripts/Remove-Lab.ps1 -Lab file-pipeline
```

This removes the selected project's resources and cloud data, not the assigned
resource group. State, plans and evidence remain ignored local files; protect
them. Record deployment, verification and cleanup outcomes before adding a live
verification record.

## Troubleshooting

Allow up to 90 seconds for the bounded checker. Check Event Grid delivery and the queue trigger separately. A successful Blob upload alone does not verify the pipeline.

## Primary sources

Reviewed 2026-09-07; documented fit does not guarantee session permissions/capacity.

- [Pluralsight Azure sandbox restrictions](https://help.pluralsight.com/hc/en-us/articles/24392988447636-Azure-cloud-sandbox)
- [Event Grid delivery to Storage Queues](https://learn.microsoft.com/en-us/azure/event-grid/handler-storage-queues)
- [Queue trigger encoding and retries](https://learn.microsoft.com/en-us/azure/azure-functions/functions-bindings-storage-queue)
