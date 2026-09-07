# Vision and Scope

## Vision

Create a trustworthy, practical library that helps architects, platform engineers, developers, and certification learners turn temporary cloud sandboxes into meaningful hands-on experience.

The long-term goal is not merely to collect deployment scripts. It is to connect:

- Cloud architecture concepts.
- Sandbox capabilities and restrictions.
- Repeatable infrastructure-as-code.
- Failure scenarios and troubleshooting.
- Evidence of successful learning.
- Production-grade design extensions.
- Multi-cloud comparisons.

## The opportunity

Cloud sandboxes provide real environments but impose unusual constraints. Generic tutorials often fail because they assume services, quotas, permissions, or persistence that a learner does not have. Vendor-specific guided labs solve a narrow exercise, but they rarely create reusable public material or show how a sandbox design differs from production.

This project occupies the space between those approaches:

> Open, source-backed, portable cloud labs that are intentionally engineered for restricted environments.

## Intended audiences

- Cloud and platform engineers who need focused practice.
- Architects who want to validate parts of a design cheaply.
- Certification learners who want legal, practical reinforcement rather than exam dumps.
- Consultants preparing demonstrations or reusable discovery exercises.
- Teams evaluating how the same workload maps across Azure, AWS, and GCP.
- AI coding agents that need structured manifests, guardrails, and deterministic checks.

## Content families

### Architecture cards

Short explanations of one pattern, its forces, tradeoffs, sandbox version, and production extension.

### Guided labs

Step-by-step exercises with preflight checks, deployment, verification, evidence collection, and cleanup.

### Challenge labs

Scenario-based exercises with objectives and acceptance checks but fewer implementation instructions.

### Reference applications

Small reusable workloads that create realistic behavior for networking, security, observability, reliability, and AI exercises.

### Field guides

Curated, cited collections comparable in spirit to system-design and AI-system-design repositories, while emphasizing cloud/platform engineering decisions.

### Capstone playbooks

Longer workflows that combine several labs, such as an AIOps incident investigation or a multi-cloud serverless comparison.

## Technical scope

The content model must be capable of representing labs in these domains:

- Compute and serverless.
- Containers and Kubernetes.
- Networking and application delivery.
- Storage and databases.
- Messaging, events, and integration.
- Observability, SRE, and incident response.
- Security, identity, and governance.
- AI/ML, RAG, agents, and inference.
- Infrastructure as code and delivery pipelines.
- Resilience, backup, and disaster recovery.
- Migration and modernization.
- FinOps and architectural tradeoffs.

## Cloud and platform scope

### Cloud implementation sequence

1. Microsoft Azure.
2. Amazon Web Services.
3. Google Cloud Platform.

### Sandbox platform sequence

1. Pluralsight.
2. Whizlabs.
3. O'Reilly.
4. Personal or unrestricted cloud accounts.

The sequence defines implementation priority, not a permanent limitation.

## Non-goals

- Reproducing paid course content or proprietary guided labs.
- Publishing exam dumps or remembered exam questions.
- Promising production readiness for sandbox configurations.
- Creating a single abstraction that hides all meaningful cloud differences.
- Maintaining a full replacement for official cloud documentation.
- Deploying expensive, long-running, or unattended workloads.
- Treating star count or social-media popularity as proof of technical quality.

## Measures of success

A lab is successful when:

- A learner can determine compatibility before attempting deployment.
- The lab can complete inside its declared time tier.
- The learner can reproduce and verify the intended behavior.
- The environment can be cleaned up without broad destructive permissions.
- Sandbox-only compromises are visible.
- The production extension explains the missing identity, security, scale, and reliability controls.
- The same concept can acquire another cloud implementation without rewriting its learning objectives.
