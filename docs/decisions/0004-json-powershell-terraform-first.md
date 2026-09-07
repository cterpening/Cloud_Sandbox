# ADR 0004: Use JSON, PowerShell, and Terraform First

- Status: Accepted
- Date: 2026-09-06

## Context

The first implementation target is Azure, while AWS and GCP are expected later. The repository needs machine-readable metadata and tooling that works well from Windows without creating unnecessary bootstrap dependencies.

## Decision

- Use JSON for canonical manifests and profiles because PowerShell can parse it without an extra module.
- Use PowerShell 7 for repository tooling and sandbox orchestration.
- Use Terraform as the first infrastructure implementation language.
- Allow cloud-native IaC variants after a lab is stable.

## Consequences

- Windows and cross-platform PowerShell users have a low-friction starting point.
- JSON is more verbose than YAML but easier to validate consistently in the initial toolchain.
- Terraform enables similar workflows across three clouds without requiring identical architectures.
- Bicep, CloudFormation/CDK, and Google-native approaches remain valid future extensions.
