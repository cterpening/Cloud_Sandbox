# Keeping the workshop usable

Run the local contracts before proposing a change:

```powershell
pwsh scripts/Test-Catalog.ps1
pwsh scripts/Get-LabCatalog.ps1
pwsh scripts/Test-Tooling.ps1
python scripts/maintain_catalog.py --check
```

The Python check validates inline relative documentation links (not heading
anchors/reference-style links), Try / Break / Remix sections, generated coverage,
and inclusion of every module/lab root in Terraform CI. It deliberately ignores
the historical v0.1 directory. Review-age notices identify profiles older than
90 days; they are warnings, not automatic claims that the content is incorrect.

To refresh the coverage document, inspect output from
`python scripts/maintain_catalog.py --coverage` and save it as `docs/coverage.md`.
The catalog is the source of truth for services, execution kind and estimates.

## Dependency proposals

The [Dependabot configuration](../.github/dependabot.yml) requests weekly Python,
Terraform and GitHub Actions update proposals. No auto-merge is configured.
Review coupled versions across modules, roots and lockfiles together. The
azure-functions 1.x pin is coupled to Python 3.11 in the cloud; a package major
upgrade needs a deliberate runtime migration, not a blind version bump.

SQL dependencies are separate so the standard-library local runner stays simple.
The container base tag and Ubuntu image version are mutable; review and pin an
approved image/digest for repeatability. Do not interpret a dependency update
proposal as an image vulnerability scan or a full supply-chain audit.

## Source and platform review

The [weekly workflow](../.github/workflows/maintenance.yml) runs read-only
repository checks and bounded requests to URLs in platform profiles. A failed
source request may mean a moved page, a transient outage or bot blocking; inspect
before editing the profile. URL availability does **not** detect semantic changes.
HTTP 403/429 results are explicitly unverified review notices, not missing-page
failures or successful URL verification. Other request failures fail the check.

Update reviewed_on only after reading the relevant primary documentation.
Do not refresh the date merely because an HTTP request succeeded. Live verified_on
records require actual deployment, application checks and cleanup; CI has no
cloud credentials and does not create those records.

## Release checklist

- Run catalog, tooling, application/SDK and Terraform mock tests.
- Inspect the Function ZIP allowlist, SQL credential handling and cleanup guards.
- Check the matrix/guide for every newly introduced service and runtime.
- Use a fresh sandbox for each live experiment; keep raw diagnostics private.
- Record sanitized evidence, failure/repair results and measured durations.
- Require human review before dependency upgrades, cloud apply and destruction.

Sources reviewed 2026-09-07:
[GitHub Dependabot options](https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-options-reference).
