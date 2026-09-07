# Content Strategy

## Goal

Create content that can use nearly any meaningful capability a sandbox exposes while remaining organized, discoverable, and technically honest.

## Content building blocks

The current collection presents a shelf of ten optional experiments, not a mandatory
curriculum. Shared code implements the reusable blocks below. Ideas do not become
supported projects until code, instructions and verification justify that status.

Instead of treating every idea as an unrelated repository, build reusable blocks.

| Block | Examples |
| --- | --- |
| Workload | HTTP API, queue worker, event processor, scheduled job. |
| State | Object storage, relational database, document database, cache. |
| Connectivity | Public endpoint, private endpoint, load balancer, gateway. |
| Telemetry | Logs, metrics, traces, dependency calls, audit events. |
| Failure | Latency, exception, throttling, unavailable dependency, poison message. |
| Control | Alert, policy, firewall rule, approval, remediation. |
| Intelligence | Retrieval, summarization, tool calling, evaluation, anomaly explanation. |
| Evidence | Tests, query output, deployment inventory, incident report. |

A lab composes a small number of these blocks. A capstone composes several verified labs.

## Content comparable to the inspiration repositories

### Cloud Architecture Field Guide

A cited system-design library focused on cloud and platform-engineering patterns, including a sandbox adaptation for each pattern.

### Multi-Cloud AI System Design Guide

A practical guide covering model access, RAG, agents, memory, tool use, evaluation, observability, security, and cost. Each topic links theory to a small cloud or local exercise.

### Observable Reference Application

A deliberately small application that emits realistic logs, metrics, traces, queue behavior, and errors. It replaces generic guestbook examples with a workload that supports multiple later labs.

### Kubernetes AI Inference Patterns

Sandbox mode uses a lightweight OpenAI-compatible simulator to teach deployments, probes, scaling, routing, and observability without a GPU. Full-cloud extensions add real vLLM and GPU node pools.

### Multi-Cloud AIOps Playbook

A diagnostic loop that collects evidence, correlates telemetry, recommends a change, requires approval, verifies the outcome, and produces a post-incident report.

### Architecture Sandbox Compatibility Mapper

A catalog that maps authoritative reference architectures to required capabilities, evaluates sandbox feasibility, and proposes smaller adaptations.

## Publication formats

- Repository README for orientation.
- Architecture card for fast reference.
- Guided lab for hands-on use.
- Challenge mode for self-assessment.
- Troubleshooting card based on verified failure modes.
- Production extension for architectural depth.
- Comparison table when two or more cloud implementations exist.
- Short article or LinkedIn post derived from an original lab result.
- Generated GitHub Pages catalog for discovery.

## Editorial standards

- Lead with the learning outcome.
- State what is and is not actually implemented.
- Separate observed facts from design recommendations.
- Prefer diagrams when relationships are more important than commands.
- Keep commands copyable and explain dangerous operations.
- Show expected results without pretending cloud output is perfectly deterministic.
- Include troubleshooting learned from real execution.
- Record a verification date and environment profile.

## Avoiding repository sprawl

New ideas begin as backlog items or folders in this library. A content family becomes a standalone repository only when it has:

- A clear independent audience.
- At least one verified vertical slice.
- Reusable value outside this library.
- Its own maintenance cadence.
- Enough content to justify independent discovery and versioning.
