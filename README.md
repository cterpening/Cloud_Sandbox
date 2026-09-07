# Cloud Sandbox Workshop

Small, premade cloud projects you can clone, run, break, and change.

This is a collection of experiments, not a course you have to complete in order.
Start with something interesting, see how the pieces fit, then try your own idea.
Terraform builds the Azure resources; small Python apps supply something to do
with them.

**Status:** five projects implemented and tested offline. Azure deployment code is
included, but **none is yet verified in a live Pluralsight sandbox**. AWS/GCP and
other learning platforms are future ideas, not supported deployments.

## Pick something to try

| Project | What you can do | Distinctive piece |
| --- | --- | --- |
| [Observable API](labs/observable-serverless-api/) | Generate successful, slow and failed requests; investigate traces and an alert. | Functions + Monitor |
| [Tiny Notes](labs/tiny-notes/) | Save a note through a browser/API and read it back. | Table Storage |
| [Queue Worker](labs/queue-worker/) | Submit orders twice, poison a message and inspect retries/dead letters. | Service Bus Basic |
| [Broken Dependency](labs/broken-dependency/) | Diagnose a 503 and repair the wrong table setting through Terraform. | Configuration fault |
| [Search Playground](labs/search-playground/) | Seed five documents, search them and test whether answers have evidence. | AI Search Free |

All five have a local mode, a browser experiment page, a functional checker,
an independent Terraform root, and cleanup instructions. They share a small
Functions/Storage/telemetry foundation. Local adapters are in-memory stand-ins,
**not Azure emulators**. Search returns an extractive answer, not LLM-generated text.

## Try one in two minutes

Install Python 3.11+ and run from the cloned repository:

```powershell
python apps/workshop/local.py --project tiny-notes
```

Open **http://127.0.0.1:7071/api/ui**. No Azure account, key or Python packages are
needed for local mode. In another terminal:

```powershell
python scripts/check_project.py --project tiny-notes
```

Use any project ID from its folder name. Stop with Ctrl+C; local data resets.

For prerequisites, preflight, Azure deployment, evidence and cleanup:
**[Run a project](docs/run-a-project.md)**.

## Why a restricted sandbox is still useful

The aim is broad experience with application patterns, data, asynchronous work,
observability, troubleshooting and retrieval—not reproducing every production
architecture. Small combinations let you explore those ideas without requiring a
large, permanent environment.

The initial cloud target is the normal **Pluralsight Azure cloud sandbox**. Its
documented constraints shape the examples: reuse the assigned resource group,
avoid role assignments and managed identity, and keep resource counts/SKUs small.
Run **one project at a time**. Service availability still depends on the session
and regional capacity. See the dated [capability profile](docs/pluralsight-azure-capabilities.md)
and [Pluralsight restrictions](https://help.pluralsight.com/hc/en-us/articles/24392988447636-Azure-cloud-sandbox)
(reviewed 2026-09-06).

The module uses Function keys and workstation /32 access restrictions. Connection
strings in app settings are a temporary sandbox compromise, not the production
recommendation. Never commit credentials, real identifiers, Terraform state or
raw portal exports.

## Make it your own

Try the [next-project menu](docs/project-ideas.md), or change one thing in an
existing project: the data store, failure, consumer, query or verification rule.
The [backlog](docs/backlog.md) keeps larger possibilities without promising that
everything already works.

Cloud capabilities remain separate from platform restrictions so future AWS/GCP
implementations can express real differences. A green compatibility report is a
documented fit check, not proof of a successful deployment.

## Repository map

- `labs/`: project manifests, experiment guides and independent Azure Terraform roots.
- `apps/workshop/`: shared workload, local adapters and Azure adapters.
- `modules/function-workshop/`: shared small Azure foundation.
- `catalog/` and `schemas/`: cloud capabilities, sandbox limits and JSON contracts.
- `scripts/`: checks, preflight, publishing and guarded cleanup.
- `tests/`: local HTTP, Azure SDK contract and application behavior tests.
- `docs/`: runbook, ideas, sources, design decisions and roadmap.

The historical `SandboxPluralSight-main/` v0.1 reference is kept locally and
Git-ignored. It is not packaged, validated as current content or published.

## Check a change

```powershell
pwsh scripts/Test-Catalog.ps1
pwsh scripts/Get-LabCatalog.ps1
pwsh scripts/Test-Tooling.ps1
python -m pip install -r apps/workshop/requirements.txt
python -m unittest discover -s tests -v
```

Use a Python virtual environment for dependencies. CI also formats, validates and
mock-plans all five Terraform roots and the shared module. It uses **no cloud
credentials and never applies infrastructure**. See [contributing](CONTRIBUTING.md).

## Independence and license

An independent educational project; not affiliated with Microsoft, Pluralsight or
other named providers. Code and original documentation use the [MIT License](LICENSE).
Third-party names, documentation and trademarks remain their owners' property.
