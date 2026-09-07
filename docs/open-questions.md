# Open Questions

These questions should be answered as implementation exposes real tradeoffs. They do not block the initial repository scaffold.

## First lab

- Should the Azure Function application use Python or PowerShell?
- Should the first lab provision its own resource group when allowed, or always require a supplied group?
- Which Azure region provisions the selected services most reliably in an actual Pluralsight session?
- How quickly do Application Insights data and log alerts become queryable in the sandbox?
- Can every required resource provider be registered, or must the lab detect pre-registration?
- Which evidence can be exported consistently from Cloud Shell and a local Windows workstation?

## Identity and security

- Which authentication patterns remain available when managed identity and Entra administration are unavailable?
- Can Key Vault add meaningful learning value without normal production identity patterns, or should it remain an optional extension?
- How should the repository present unavoidable key/connection-string use without normalizing it as good practice?

## Tooling

- Should PowerShell remain the only repository tool dependency, or should Python be added for catalog/site generation?
- Should JSON Schema validation use a pinned standalone tool or a small repository-owned validator?
- When should Bicep variants be introduced?
- Which Terraform provider version should the first lab pin after checking current service compatibility?
- Should the compatibility evaluator return exit codes for `unknown` and `conditional` results in CI?

## Content and publication

- Should the generated GitHub Pages catalog live in this repository or integrate with the existing certification study library?
- Which content families should eventually become standalone repositories?
- What evidence can be published without exposing ephemeral account identifiers?
- Should verified lab results include screenshots, sanitized JSON, or both?
- How often should sandbox profiles be re-reviewed?

## Multi-cloud

- Which lab provides the fairest first comparison across Azure, AWS, and GCP?
- How should provider-neutral capabilities be named without implying false service equivalence?
- Should cloud-native IaC be offered beside Terraform for comparison or kept in separate advanced labs?
- How much implementation should be shared versus deliberately cloud-specific?

## Additional platforms

- What precise permissions and duration does the current Whizlabs Azure sandbox expose?
- Which O'Reilly experiences provide a blank Azure environment versus only a guided or preconfigured environment?
- Can the same bootstrap process work from all platform-provided terminals?
