# Search and Retrieval Playground

Seed five original synthetic documents, query Azure AI Search, and evaluate retrieved evidence with an extractive answer demo.

**Implemented and offline-tested; not yet verified in a live sandbox.** Local mode
needs Python 3.11+ only. The first cloud target is Pluralsight's normal Azure
sandbox; the cloud run needs a fresh session, PowerShell 7, Azure CLI and Terraform.
Budget roughly 60 minutes for a first cloud attempt, not a measured completion time.

## What you can learn

Understand the components below, predict the result of the experiment, compare
local behavior with the actual Azure services, and preserve safe evidence before
cleanup.

## How it fits together

Browser/checker → Function → one Free Azure AI Search service and one index containing five original synthetic documents. The answer is copied from the first retrieved passage; there is no model call, embedding pipeline or vector index.

The Azure implementation adds the shared Functions host, LRS storage, Log Analytics,
Application Insights and a metric alert. Reuse the supplied resource group and run
one project at a time. See the [manifest](lab.json) for declared services and quotas.

## Run it

From the repository root:

```powershell
python apps/workshop/local.py --project search-playground
```

Open http://127.0.0.1:7071/api/ui and leave the key blank. For Azure preflight,
Terraform deployment and publishing, follow [Run a project](../../docs/run-a-project.md)
with `$lab = 'search-playground'`. The
[Azure implementation](implementations/azure/README.md) identifies the Terraform root.

## Try the experiment

1. Select **Seed search documents**. Repeating the seed merges the same five IDs.
2. Search for `poison`, `DNS`, `latency` and `identities`.
3. Inspect each result's ID, title and content. The answer must equal a retrieved passage.
4. Search for `quasarzzzz`: no matching evidence means the answer is null.
5. Change an original document and extend the golden-query checks to explore retrieval quality.
   Do not describe this extractive demo as a complete RAG/LLM application.

## API and verification

`POST /api/seed` → document count 5. `GET /api/search?q=poison` → up to three matches, `answer`, `answer_mode=extractive_demo` and an engine label. Local token matching and Azure keyword search may rank other queries differently.

In another terminal, from the repository root:

```powershell
python scripts/check_project.py --project search-playground --evidence evidence/search-playground.json
```

For cloud mode add `--mode azure --base-url $base` and set the Function key in the
process environment as shown in the shared runbook. The checker exports only
allowlisted check labels, project, mode and pass status—not credentials or data.
Review relevant telemetry privately; automated functional checks do not certify
cloud monitoring or cleanup.

## Cleanup

Stop the local process with Ctrl+C; in-memory data disappears. After Azure use:

```powershell
pwsh scripts/Remove-Lab.ps1 -Lab search-playground
```

Review the saved destroy plan and type the exact Function App name when prompted.
This removes the deployment and its data, **not the assigned resource group**.
Keep state/plans private. Use fresh state for a new sandbox session.

## Sandbox compromise and production extension

Short-lived service keys and Function keys replace identities unavailable in this
sandbox. /32 ingress is a workshop safeguard, not end-user authorization.
Separate read/query identity from index administration. Add a licensed corpus, retrieval evaluation, access filtering and optionally a separately authorized model integration. Model access is not assumed to be included in this normal sandbox.

## Troubleshooting

A new index can take time to become searchable; the checker retries. Preflight stops if the one-service allowance is already used. Do not upgrade SKUs or delete an existing unrelated service just to force deployment. See the [shared troubleshooting guide](../../docs/run-a-project.md#troubleshooting)
for access, provider, regional-capacity and publishing failures.

## Primary sources

Reviewed 2026-09-06; documentation review is not live verification.

- [Pluralsight Azure restrictions](https://help.pluralsight.com/hc/en-us/articles/24392988447636-Azure-cloud-sandbox)
- [Azure AI Search Python quickstart](https://learn.microsoft.com/en-us/azure/search/search-get-started-text)

## Try

Seed the five synthetic documents and compare the top results for the golden queries.

## Break

Search for an unknown term and confirm the extractive answer abstains rather than fabricating guidance.

## Remix

Add an original document and its expected query, then compare local token overlap with Azure ranking. Vector/LLM integration remains a separate future implementation.

See the [architecture cards](../../docs/architecture-cards.md) and
[coverage matrix](../../docs/coverage.md) to choose another independent experiment.
