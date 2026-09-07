# ADR 0001: Separate Cloud Providers from Sandbox Platforms

- Status: Accepted
- Date: 2026-09-06

## Context

Azure, AWS, and GCP define cloud services. Pluralsight, Whizlabs, and O'Reilly define temporary learning environments that expose subsets of those services under different permissions, regions, quotas, and session durations.

Treating `Pluralsight Azure` as one inseparable target would make it difficult to add either another Azure sandbox platform or another Pluralsight cloud.

## Decision

Model cloud providers and sandbox platforms independently. A platform profile represents one combination, such as `pluralsight/azure`, while a lab implementation represents a cloud, such as `azure`.

## Consequences

- The same Azure implementation can be evaluated against several platforms.
- The same portable lab can have Azure, AWS, and GCP implementations.
- Catalogs require more explicit identifiers and validation.
- Compatibility remains a computed result rather than a label embedded in infrastructure code.
