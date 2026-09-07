# ADR 0002: Use Capability-Driven Lab Manifests

- Status: Accepted
- Date: 2026-09-06

## Context

A title or README does not provide enough information to determine whether a lab fits a temporary sandbox. Compatibility depends on required services, identity features, GPU access, resource-group behavior, duration, and concurrent environment needs.

## Decision

Every lab has a JSON manifest containing:

- Portable learning capabilities.
- Difficulty and time tier.
- Cloud implementation status.
- Required cloud services.
- Environmental requirements.
- Expected evidence.
- Verification records.

Platform profiles use stable service identifiers and explicit status values. A script computes compatibility.

## Consequences

- Compatibility can be validated before deployment.
- A generated site can filter labs without parsing prose.
- Schema evolution must be managed deliberately.
- Human-readable documentation remains necessary for nuance and tradeoffs.
