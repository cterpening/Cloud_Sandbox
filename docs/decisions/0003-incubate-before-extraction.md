# ADR 0003: Incubate Content Before Creating Standalone Repositories

- Status: Accepted
- Date: 2026-09-06

## Context

The project has several promising content families: architecture guides, AI design guidance, reference applications, Kubernetes inference patterns, AIOps playbooks, and compatibility mapping. Creating an independent repository for every idea immediately would duplicate scaffolding and create empty maintenance surfaces.

## Decision

Begin in one `cloud-sandbox-lab-library` repository. Extract a content family only after it has a clear audience, a verified vertical slice, reusable value, and enough material to justify independent maintenance.

## Consequences

- Shared conventions can evolve quickly during the first labs.
- Ideas remain visible in one backlog.
- Mature projects can later optimize their own structure and release cadence.
- Extraction requires link redirects and deliberate history preservation.
