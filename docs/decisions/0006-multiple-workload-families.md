# ADR 0006: Multiple workload families and discoverable experiments

- Status: Accepted
- Date: 2026-09-07
- Extends [ADR 0005](0005-five-small-runnable-projects.md)

## Context

The owner wants the repository to create many different small things, not just
Terraform variations of one serverless application. Breadth must remain bounded
by the sandbox, executable workload behavior and honest verification status.

## Decision

Add file processing, private-VM networking, isolated containers, SQL inventory
and configuration-driven flags. Reuse Functions where useful; introduce separate
network/container/SQL modules where their execution models genuinely differ.

Discover projects from manifests with a local/Azure picker and time/domain
filters. Keep Try / Break / Remix sections, architecture cards and a generated
service coverage matrix. Include dependency proposals and read-only maintenance
checks; no automatic cloud apply, destruction or dependency merge.

Networking keeps VM NICs private but includes explicit outbound NAT for Run
Command results. ACI has no public endpoint. SQL uses a workstation app plus a
/32 SQL firewall rule, full-session TLS and a process-environment password.
File events use a Storage Queue delivery path to retain Function ingress
restrictions. Feature flags use one explicit JSON setting with an acknowledged
store-key sandbox compromise, not a full Feature Management SDK implementation.

## Consequences

There are ten independent experiments and four Terraform module families.
Shared tools must dispatch by execution kind and validate state before publishing,
checking live deployments or cleanup. Local-mode success is not proof of Azure
networking, policy, quotas or event delivery. All live records remain empty until
a real sandbox deployment/experiment/cleanup is documented.

Image publication, Container Apps revisions, AKS, multi-cloud implementations,
and a composed order-system capstone remain separate future work. A broader
catalog does not mean all Azure capabilities are covered or all roots can run
together. Live validation is still the highest-priority next gate.

Primary dependency reviewed 2026-09-07:
[Run Command outbound requirements](https://learn.microsoft.com/en-us/azure/virtual-machines/linux/run-command).
