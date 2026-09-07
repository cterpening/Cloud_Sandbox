# Architecture cards

Choose one independent recipe. These are implemented blueprints, not a promise
that every combination can coexist in one sandbox. The [generated matrix](coverage.md)
lists services and time estimates; each project guide contains its experiments.

| Recipe | Request / data path | Infrastructure addition or distinction |
| --- | --- | --- |
| [Observable API](../labs/observable-serverless-api/) | Client → Function → request telemetry → alert condition | Shared Functions foundation |
| [Tiny Notes](../labs/tiny-notes/) | Browser → Function → table → saved note | Shared table |
| [Queue Worker](../labs/queue-worker/) | API → Service Bus → worker → receipt / dead letter | One Basic namespace and queue |
| [Broken Dependency](../labs/broken-dependency/) | API → wrong table → 503 → repaired setting | No extra service |
| [Search Playground](../labs/search-playground/) | Query → search index → retrieved passage → extractive answer | One Free service / index |
| [File Pipeline](../labs/file-pipeline/) | Inbox blob → Event Grid → queue → worker → processed / rejected | One topic/subscription, queue and four containers |
| [Feature Flags](../labs/feature-flags/) | Setting write → App Configuration → offer evaluation | One Free store |
| [Network Detective](../labs/network-detective/) | Private client → DNS / NSG → private server | Two B1s VMs; explicit outbound NAT for diagnostics |
| [Container Playground](../labs/container-playground/) | Versioned source → isolated ACI → health probes / logs | One container, 1 vCPU / 1 GiB |
| [SQL Inventory](../labs/sql-inventory/) | Loopback app → TLS → stock update + order insert → joined report | One Basic 2 GiB DB; workstation-only firewall |

## Shared foundations

The seven Functions recipes use one Y1 plan, one Function, one LRS storage
account/table, one Log Analytics workspace, Application Insights and a metric
alert. Extra services are created only for the selected recipe. Workstation /32
access and Function keys protect experiment APIs; public storage endpoints still
use keys. This is a temporary sandbox compromise.

Networking, containers and SQL use separate modules. They do not inherit a
Function plan, workspace or alert that their experiment does not use. SQL's
application intentionally stays on the workstation to avoid a broad firewall
exception for dynamic cloud outbound addresses.

## Composition rule

Sharing source code is not the same as sharing a deployment. Each lab owns an
independent root/state inside the supplied resource group. Do not deploy every
root to assemble a capstone: that duplicates plans and can exceed sandbox limits.
A future order-system recipe should intentionally share storage, messaging and
telemetry, declare its aggregate quota budget, and have its own end-to-end test.

Local networking is a prediction model; local queues/files are stand-ins; local
SQL is SQLite. Azure checks and sanitized live verification records are separate.
Nothing on this page establishes live Pluralsight compatibility.
