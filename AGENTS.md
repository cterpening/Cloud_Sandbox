# Repository Instructions for AI Coding Agents

## Mission

Help maintain a safe, accurate, sandbox-first library of cloud architecture labs. Azure plus Pluralsight is the first supported combination. Preserve the separation between cloud providers, sandbox platforms, lab concepts, and cloud implementations.

## Required behavior

- Read the relevant lab manifest and sandbox profile before changing a lab.
- Prefer primary cloud-provider and sandbox-provider documentation.
- Add a source URL and verification date for new capability claims.
- Never reproduce paid course text, proprietary lab steps, certification dumps, or hidden assessment material.
- Never add real credentials, tenant IDs, subscription IDs, account IDs, private endpoints, customer names, or production data.
- Treat all example identifiers as synthetic.
- Default infrastructure examples to safe, reversible operations.
- Never add unattended apply or destroy behavior.
- Require an explicit confirmation immediately before destructive cleanup.
- Clearly label a workaround that is acceptable only in a temporary sandbox.
- Explain the production-grade alternative to each material sandbox compromise.
- Keep Azure implementations within documented Pluralsight limits unless the manifest marks them as design-only.
- Prefer PowerShell 7 for repository tooling and Terraform for the first infrastructure implementations.
- Keep scripts cross-platform where practical.
- Update the backlog, decision records, and manifest status when work changes project scope.

## Content quality

Every deployable lab should eventually include:

1. Learning objectives.
2. Architecture and tradeoffs.
3. Supported cloud/platform combinations.
4. Prerequisites and preflight checks.
5. Deployment instructions.
6. A synthetic workload or failure scenario.
7. Verification steps.
8. Evidence collection.
9. Cleanup.
10. Production extension.
11. Troubleshooting.
12. Primary sources.

## Validation

Run before proposing a completed change:

```powershell
pwsh ./scripts/Test-Catalog.ps1
pwsh ./scripts/Get-LabCatalog.ps1
```

If a lab implementation changes, also run its compatibility check and its implementation-specific validation commands.
