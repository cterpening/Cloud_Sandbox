# Roadmap

The roadmap is ordered by dependency and learning value. Dates will be assigned only when work is scheduled.

Current snapshot (2026-09-07): the repository foundation and ten small Azure
projects are implemented and offline-tested. Phase 1's live verification exit
criteria are still open. Queue and retrieval breadth has begun in code, not yet
in verified cloud runs. File processing, networking, containers, SQL and flags now
have code plus local/offline checks, alongside picker/coverage/maintenance tooling.
See [the project shelf](../labs/README.md).

## Phase 0 — Repository operating system

Goal: establish enough structure that humans and coding agents can add content consistently.

- Define cloud, platform-profile, and lab schemas.
- Record initial Pluralsight Azure limits.
- Add catalog validation and compatibility reporting.
- Establish source, security, and contribution policies.
- Capture the high-level backlog.
- Add a lab template and proposal workflow.

Exit criteria:

- Catalog validation passes.
- One planned lab can be evaluated against Pluralsight Azure.
- The repository clearly distinguishes planned content from verified content.

## Phase 1 — First verified Azure lab

Goal: complete a thin, useful vertical slice.

- Build the Observable Serverless API with Azure Functions.
- Add Terraform with sandbox-aware variables.
- Create synthetic success, failure, and latency traffic.
- Query Application Insights and Log Analytics.
- Configure one alert.
- Add evidence collection and guarded cleanup.
- Run the entire lab in the Pluralsight Azure sandbox.
- Record actual provisioning and cleanup durations.

Exit criteria:

- A fresh user can complete it within 90 minutes.
- Deployment, verification, evidence, and cleanup all succeed.
- Production differences are documented.

## Phase 2 — Azure sandbox breadth

Goal: exercise the major categories that Pluralsight exposes.

- Networking foundation and private connectivity.
- Container Apps revisions and observability.
- Service Bus dead-letter investigation.
- Event Grid and Functions processing.
- App Gateway WAF exercise.
- Azure SQL and Cosmos DB constrained-data labs.
- Azure Policy and Sentinel exercises.
- Small AKS workload and operational troubleshooting.
- AI Search retrieval lab with mock inference.

Exit criteria:

- At least one verified lab exists for compute, networking, data, integration, observability, security, containers, and AI-adjacent capabilities.

## Phase 3 — Reference application and AIOps capstone

Goal: connect individual exercises into an end-to-end operational story.

- Build the Observable Reference Application.
- Standardize synthetic incident scenarios.
- Build evidence collectors and KQL investigation packs.
- Add provider-neutral incident JSON.
- Add AI summarization through a pluggable inference interface.
- Require approval before any remediation action.
- Verify the result and generate a post-incident report.

Exit criteria:

- The capstone demonstrates an observable incident-to-verification loop.
- The lab remains usable with deterministic mock inference.
- AI is helpful but not required for basic correctness.

## Phase 4 — Architecture mapper and field guides

Goal: turn the verified lab knowledge into discoverable architecture content.

- Inventory Azure Architecture Center patterns.
- Map patterns to portable capabilities and Azure services.
- Publish compatible, adaptable, design-only, and unsuitable classifications.
- Connect patterns to labs.
- Grow the Cloud Architecture Field Guide.
- Grow the Multi-Cloud AI System Design Guide.
- Generate a searchable GitHub Pages catalog.

Exit criteria:

- Architecture classifications are source-backed and reproducible.
- A reader can navigate from a pattern to an executable lab or an explicit design-only explanation.

## Phase 5 — AWS implementations

Goal: validate that the data model supports a second cloud without distorting either provider.

- Complete the Pluralsight AWS profile.
- Port the Observable Serverless API to Lambda, CloudWatch, and X-Ray.
- Port messaging and container scenarios.
- Compare identity, observability, deployment, and cleanup behavior.
- Add Bedrock only through an allowed AI profile or mock interface.

Exit criteria:

- One portable lab has verified Azure and AWS implementations.
- Comparison content explains meaningful differences.

## Phase 6 — GCP implementations

Goal: complete the first three-cloud comparison.

- Complete the Pluralsight GCP profile.
- Port the Observable Serverless API to Cloud Functions or Cloud Run.
- Add Cloud Logging, Cloud Monitoring, Pub/Sub, and a supported data service.
- Add GKE and AI variants where the sandbox profile permits them.

Exit criteria:

- One portable lab has verified Azure, AWS, and GCP implementations.
- The common manifest remains useful without hiding provider-specific behavior.

## Phase 7 — Additional learning platforms

Goal: separate cloud portability from sandbox-platform portability in practice.

- Add Whizlabs profiles based on published documentation and safe verification.
- Add O'Reilly profiles for short-lived cloud labs and preconfigured interactive environments.
- Document platform-specific bootstrap and resource-scope behavior.
- Add compatibility reports by platform.

## Phase 8 — Mature standalone repositories

Potential extractions:

- `cloud-architecture-field-guide`
- `multi-cloud-ai-system-design-guide`
- `observable-cloud-reference-app`
- `kubernetes-ai-inference-patterns`
- `multi-cloud-aiops-playbook`
- `architecture-sandbox-mapper`

Extraction is earned by verified content, not by the size of the idea.
