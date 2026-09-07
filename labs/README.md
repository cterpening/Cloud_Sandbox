# Project shelf

Pick any project; there is no required order. Each has a local demo and Azure
Terraform implementation. All are **implemented/offline-tested, not live-sandbox
verified**.

- [Observable Serverless API](observable-serverless-api/): Send normal, slow and failed requests; inspect correlation IDs, traces and a metric alert.
- [Tiny Notes App](tiny-notes/): Run a small browser/API application backed by Azure Table Storage, then restart the client and read the saved notes.
- [Queue Worker and Poison Messages](queue-worker/): Submit synthetic orders, inspect idempotent receipts, and watch poison messages move to the dead-letter queue.
- [The Broken Storage Dependency](broken-dependency/): Investigate an API returning 503 because its table setting is wrong; repair it through Terraform and verify recovery.
- [Search and Retrieval Playground](search-playground/): Seed five original synthetic documents, query Azure AI Search, and evaluate retrieved evidence with an extractive answer demo.

- [File-processing Pipeline](file-pipeline/): Process and quarantine synthetic uploads through Blob events and a queue.
- [Network Detective](network-detective/): Diagnose DNS and NSG faults between two private VMs.
- [Container Playground](container-playground/): Run a versioned app in Python, Docker or isolated ACI; reproduce startup failure.
- [Tiny SQL Inventory](sql-inventory/): Exercise transactions, joined reports and oversell rejection.
- [Feature-flag Playground](feature-flags/): Change behavior through App Configuration and recover from invalid settings.

Begin with [Run a project](../docs/run-a-project.md). Browse the
[coverage matrix](../docs/coverage.md), [architecture cards](../docs/architecture-cards.md)
or [next-project menu](../docs/project-ideas.md).
The historical v0.1 reference is not part of this catalog.
