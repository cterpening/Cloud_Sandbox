# High-Level Backlog

This is an idea inventory, not a commitment to implement every item. Priority favors reusable foundations, short verified labs, and material that supports several future content families.

## Current delivery snapshot — 2026-09-06

Implemented and offline-tested: five [starter projects](../labs/README.md), shared
Terraform/Python foundations, schema/compatibility regression checks, read-only
preflight, application packaging, bounded functional evidence and guarded cleanup.
The [next-project menu](project-ideas.md) is the short browsing list; the inventory
below preserves longer-term possibilities.

Still P0: run every project in a fresh Pluralsight Azure session; verify app
publishing, workload behavior, telemetry/alert ingestion and cleanup; record
actual durations and sanitized verification records. No live verification is claimed.

## Priority legend

| Priority | Meaning |
| --- | --- |
| P0 | Required for the first verified lab. |
| P1 | High reuse or high learning value. |
| P2 | Valuable after the foundation is stable. |
| P3 | Exploration or long-term expansion. |

## Foundation and repository tooling

| ID | Priority | Idea | Outcome |
| --- | --- | --- | --- |
| FND-001 | P0 | Complete Pluralsight Azure profile | Machine-readable service and quota coverage. |
| FND-002 | P0 | Catalog validator | Detect malformed profiles and manifests. |
| FND-003 | P0 | Compatibility evaluator | Explain supported, conditional, unknown, and blocked requirements. |
| FND-004 | P0 | Lab template | Standard structure for objectives, deployment, evidence, cleanup, and production extensions. |
| FND-005 | P0 | Azure preflight script | Check current account, resource group, locations, providers, and key quotas safely. |
| FND-006 | P0 | Evidence sanitizer | Remove tenant, subscription, account, project, and resource identifiers. |
| FND-007 | P0 | Guarded cleanup pattern | Confirm exact scope before deletion. |
| FND-008 | P1 | Lab scaffolding command | Create a lab folder and manifest from a template. |
| FND-009 | P1 | Source freshness checker | Flag changed sandbox documentation for human review. |
| FND-010 | P1 | GitHub Pages catalog generator | Publish searchable lab and compatibility views. |
| FND-011 | P1 | Verification record format | Record date, platform, duration, result, and sanitized evidence. |
| FND-012 | P1 | Architecture card template | Standardize concise pattern documentation. |
| FND-013 | P2 | Certification objective mapping | Connect labs to public exam skill outlines without exam dumps. |
| FND-014 | P2 | Challenge-mode template | Reuse a guided lab as a scenario-based assessment. |
| FND-015 | P2 | Lab dependency graph | Show which labs and components feed capstones. |
| FND-016 | P2 | Local emulation conventions | Standardize containers, mocks, and saved evidence. |
| FND-017 | P3 | Repository extraction tool | Graduate mature content families without losing history or links. |

## Azure compute and application platform

| ID | Priority | Idea | Sandbox approach |
| --- | --- | --- | --- |
| AZ-CMP-001 | P0 | Observable Serverless API | Azure Functions consumption plan with synthetic telemetry. |
| AZ-CMP-002 | P1 | Container Apps revisions | Deploy two revisions, split traffic, observe, and roll back. |
| AZ-CMP-003 | P1 | App Service health and deployment | Use supported low-cost SKU and health checks. |
| AZ-CMP-004 | P2 | VM diagnostics baseline | One small VM, boot diagnostics, Azure Monitor, and safe teardown. |
| AZ-CMP-005 | P2 | VM scale-set behavior | Small instance count within documented limits. |
| AZ-CMP-006 | P2 | Container Instances batch worker | Short-lived container groups within CPU/memory caps. |
| AZ-CMP-007 | P3 | Image Builder exploration | Design a minimal image pipeline if timing permits. |

## Azure networking and application delivery

| ID | Priority | Idea | Sandbox approach |
| --- | --- | --- | --- |
| AZ-NET-001 | P1 | VNet, subnet, NSG, and routes | Reusable network foundation with verification commands. |
| AZ-NET-002 | P1 | Private endpoint and DNS | Storage or App Service private connectivity, subject to runtime validation. |
| AZ-NET-003 | P1 | Application Gateway WAF | Small backend, OWASP detection, custom rule, and logs. |
| AZ-NET-004 | P1 | NAT Gateway egress | Demonstrate deterministic outbound IP and route behavior. |
| AZ-NET-005 | P2 | Front Door routing | Two simple origins or simulated failover. |
| AZ-NET-006 | P2 | Azure Firewall Basic | Minimal rules and flow verification with time/cost warning. |
| AZ-NET-007 | P2 | Load Balancer health probes | Small VM or container backend. |
| AZ-NET-008 | P2 | DNS troubleshooting challenge | Broken record, private resolution, and evidence-driven repair. |
| AZ-NET-009 | P3 | VPN gateway fundamentals | Use supported SKU only when provisioning time fits. |
| AZ-NET-010 | P3 | ExpressRoute design card | Design-only because sandbox deployment is unavailable. |

## Azure data, messaging, and integration

| ID | Priority | Idea | Sandbox approach |
| --- | --- | --- | --- |
| AZ-DAT-001 | P1 | Storage security and lifecycle | Blob, file, table, access controls, and lifecycle concepts. |
| AZ-DAT-002 | P1 | Service Bus dead-letter investigation | Generate poison messages, inspect, repair, and replay. |
| AZ-DAT-003 | P1 | Event Grid fan-out | Route synthetic events to Functions or storage. |
| AZ-DAT-004 | P1 | Logic Apps operational workflow | Alert-driven workflow without proprietary integrations. |
| AZ-DAT-005 | P1 | Cosmos DB constrained design | Stay at or below 1,000 RU/s and explain production scaling. |
| AZ-DAT-006 | P1 | Azure SQL resilient access | Basic or Standard tier, retry behavior, and telemetry. |
| AZ-DAT-007 | P2 | PostgreSQL application backend | Supported small SKU with safe synthetic data. |
| AZ-DAT-008 | P2 | Event Hubs streaming | Basic/Standard, limited units, no Capture or cluster dependency. |
| AZ-DAT-009 | P2 | API Management front door | Consumption or supported SKU with a small API. |
| AZ-DAT-010 | P2 | Data Factory movement | Move synthetic data between supported stores. |
| AZ-DAT-011 | P3 | Synapse constrained Spark | Small fixed cluster only; strict timing gate. |
| AZ-DAT-012 | P3 | Managed Instance design card | Design-only because provisioning and service are unsupported. |

## Azure observability, SRE, and operations

| ID | Priority | Idea | Sandbox approach |
| --- | --- | --- | --- |
| AZ-OPS-001 | P0 | Application Insights investigation | Success, failure, latency, trace correlation, and KQL. |
| AZ-OPS-002 | P0 | Azure Monitor alert lifecycle | Create, trigger, acknowledge conceptually, and verify recovery. |
| AZ-OPS-003 | P1 | KQL investigation pack | Reusable queries for app, platform, and security scenarios. |
| AZ-OPS-004 | P1 | SLO and error-budget exercise | Calculate availability and burn from synthetic telemetry. |
| AZ-OPS-005 | P1 | Incident evidence package | Export a sanitized, provider-neutral incident record. |
| AZ-OPS-006 | P1 | Diagnostic settings pattern | Apply consistent logging without requiring root-level ad hoc blocks. |
| AZ-OPS-007 | P2 | Change correlation | Relate deployments or configuration changes to failures. |
| AZ-OPS-008 | P2 | Automated runbook with approval | Azure Automation within account/runbook limits. |
| AZ-OPS-009 | P2 | Resilience game day | Inject an application-level failure and verify detection/recovery. |
| AZ-OPS-010 | P3 | Azure SRE agent comparison | Compare the custom playbook with current managed-agent capabilities. |

## Azure security and governance

| ID | Priority | Idea | Sandbox approach |
| --- | --- | --- | --- |
| AZ-SEC-001 | P1 | Azure Policy guardrail | Deny or audit a safe synthetic misconfiguration. |
| AZ-SEC-002 | P1 | Sentinel analytics rule | Generate a benign event, detect it, and document triage. |
| AZ-SEC-003 | P1 | Key Vault without managed identity | Explicit sandbox compromise plus production managed-identity design. |
| AZ-SEC-004 | P1 | WAF investigation | Trigger and analyze a harmless blocked request. |
| AZ-SEC-005 | P2 | Storage exposure challenge | Detect and repair an intentionally weak lab configuration. |
| AZ-SEC-006 | P2 | Network segmentation review | Evaluate NSGs, routes, and public endpoints. |
| AZ-SEC-007 | P2 | Defender posture exercise | Use only features visible in the sandbox. |
| AZ-SEC-008 | P2 | Secret scanning and repository hygiene | Local/GitHub validation with synthetic secrets. |
| AZ-SEC-009 | P3 | Entra design cards | Design-only or guided-lab-specific because normal administration is unavailable. |
| AZ-SEC-010 | P3 | Management-group landing zone | Design-only reduced-scope policy exercise. |

## Azure containers and Kubernetes

| ID | Priority | Idea | Sandbox approach |
| --- | --- | --- | --- |
| AZ-K8S-001 | P1 | Small AKS platform baseline | One cluster, one or two nodes, resource limits, and cleanup. |
| AZ-K8S-002 | P1 | Probes and failure recovery | Broken readiness/liveness configuration challenge. |
| AZ-K8S-003 | P1 | Horizontal autoscaling | CPU or application metric with bounded replicas. |
| AZ-K8S-004 | P1 | ACR-to-AKS delivery | One registry, no ACR Tasks, explicit credential constraints. |
| AZ-K8S-005 | P2 | Kubernetes observability | Metrics, logs, restarts, and basic dashboards. |
| AZ-K8S-006 | P2 | GitOps workflow simulation | Local validation and pull-based reconciliation without Azure DevOps. |
| AZ-K8S-007 | P2 | Namespace and policy challenge | Resource quotas, limits, and network-policy concepts. |
| AZ-K8S-008 | P2 | OpenAI-compatible inference simulator | Teach model-service routing without a GPU. |
| AZ-K8S-009 | P3 | vLLM production extension | GPU-backed design and optional unrestricted implementation. |

## Azure AI and agentic systems

| ID | Priority | Idea | Sandbox approach |
| --- | --- | --- | --- |
| AZ-AI-001 | P1 | AI Search retrieval | One Free/Basic search service and a small synthetic corpus. |
| AZ-AI-002 | P1 | Hybrid retrieval comparison | Keyword, vector, and hybrid results within one-index limits. |
| AZ-AI-003 | P1 | Pluggable inference interface | Deterministic mock plus Azure/OpenAI-compatible adapters. |
| AZ-AI-004 | P1 | Incident summarization | Analyze saved evidence locally or in a separate AI sandbox. |
| AZ-AI-005 | P1 | Evaluation-first prompt lab | Golden cases, deterministic scoring, and model-optional execution. |
| AZ-AI-006 | P2 | Tool-calling operations agent | Read-only tools first; approval required for changes. |
| AZ-AI-007 | P2 | Agent state and memory | Local state first; optional constrained cloud store. |
| AZ-AI-008 | P2 | Document ingestion pipeline | Storage, extraction, indexing, and retrieval with synthetic documents. |
| AZ-AI-009 | P2 | Model router | Route between mock, external, and Azure-compatible endpoints. |
| AZ-AI-010 | P2 | AI observability | Trace tool calls, latency, tokens, evaluation, and failure categories. |
| AZ-AI-011 | P3 | Azure AI sandbox companion | Separate three-hour exercise using its pre-created deployment. |
| AZ-AI-012 | P3 | Foundry production extension | Design-only in the normal sandbox. |

## Infrastructure as code and delivery

| ID | Priority | Idea | Sandbox approach |
| --- | --- | --- | --- |
| IAC-001 | P0 | Terraform sandbox bootstrap | Current CLI identity, supplied RG support, naming, and tags. |
| IAC-002 | P1 | Terraform validation workflow | Format, validate, lint, security scan, and plan without cloud secrets. |
| IAC-003 | P1 | Module-first diagnostic settings | Reusable pattern for strict module environments. |
| IAC-004 | P1 | Terraform tests | Mock/provider tests that run without a sandbox. |
| IAC-005 | P1 | Safe import exercise | Import a small sandbox resource and reconcile configuration. |
| IAC-006 | P2 | Drift simulation | Make a controlled change and detect/reconcile it. |
| IAC-007 | P2 | Policy-as-code checks | Enforce sandbox safety and production recommendations separately. |
| IAC-008 | P2 | Bicep implementation variant | Add after the Terraform vertical slice is stable. |
| IAC-009 | P2 | GitHub Actions plan pattern | Validation by default; cloud deployment only with explicit credentials. |
| IAC-010 | P3 | TFE/TFC workflow card | Explain remote-run constraints without requiring sandbox support. |

## Capstones and reference content

| ID | Priority | Idea | Outcome |
| --- | --- | --- | --- |
| CAP-001 | P1 | Observable Reference Application | Shared workload for later labs. |
| CAP-002 | P1 | Azure AIOps Playbook | Incident-to-evidence-to-recommendation-to-verification loop. |
| CAP-003 | P1 | Architecture Sandbox Mapper | Match reference architectures to sandbox profiles. |
| CAP-004 | P2 | Cloud Architecture Field Guide | Cited architecture patterns and tradeoffs. |
| CAP-005 | P2 | Multi-Cloud AI System Design Guide | Theory connected to executable exercises. |
| CAP-006 | P2 | Kubernetes AI Inference Patterns | Sandbox simulation plus GPU production extensions. |
| CAP-007 | P2 | Technology lifecycle monitor | Track deprecations that can invalidate labs. |
| CAP-008 | P3 | Voice-guided challenge mode | Optional agent-driven lab navigation. |

## AWS and GCP expansion

| ID | Priority | Idea | Outcome |
| --- | --- | --- | --- |
| MC-001 | P2 | Complete Pluralsight AWS profile | Full service and quota mapping. |
| MC-002 | P2 | Complete Pluralsight GCP profile | Full service and quota mapping. |
| MC-003 | P2 | Observable Serverless API on AWS | Lambda, CloudWatch, X-Ray, and a small data store. |
| MC-004 | P2 | Observable Serverless API on GCP | Functions/Cloud Run, Logging, Monitoring, and a small data store. |
| MC-005 | P2 | Cross-cloud messaging comparison | Service Bus/Event Grid, SQS/EventBridge, and Pub/Sub. |
| MC-006 | P2 | Cross-cloud container comparison | Container Apps, ECS/Fargate, and Cloud Run. |
| MC-007 | P2 | Cross-cloud Kubernetes comparison | AKS, EKS, and GKE within platform limits. |
| MC-008 | P3 | Cross-cloud RAG comparison | Search/retrieval and model-access differences. |
| MC-009 | P3 | Cross-cloud security evidence | Compare logs, posture, secrets, and alerting. |
| MC-010 | P3 | Well-architected comparison | Map equivalent concerns without forcing false equivalence. |

## Additional sandbox platforms

| ID | Priority | Idea | Outcome |
| --- | --- | --- | --- |
| PLT-001 | P2 | Whizlabs Azure profile | Documented limits plus safe runtime verification. |
| PLT-002 | P2 | O'Reilly Azure profile | Short-duration, assigned-resource-group execution. |
| PLT-003 | P2 | Bootstrap portability | Work with portal, Cloud Shell, local CLI, or browser terminal. |
| PLT-004 | P2 | Platform comparison report | Compare duration, scope, services, identity, and persistence. |
| PLT-005 | P3 | Whizlabs AWS/GCP profiles | Expand after Azure validation. |
| PLT-006 | P3 | O'Reilly local sandbox mappings | Use Python, Linux, Docker, and Kubernetes environments where cloud access is absent. |

## Parking lot

- Interactive architecture-cost calculator.
- Diagram-as-code generation from deployed resources.
- Multi-agent lab authoring workflow with human approval.
- Automated troubleshooting-case extraction from verified run notes.
- Public badges for `sandbox-verified`, `local-compatible`, and `production-extension`.
- Translation of selected labs into workshop or meetup format.
- Optional Jupyter notebooks for data and AI exercises.
- Integration with the certification study library without merging the projects.
