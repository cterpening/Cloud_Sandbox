# GitHub publication

The existing destination is [cterpening/Cloud_Sandbox](https://github.com/cterpening/Cloud_Sandbox).
Do not create a second repository or change visibility as part of normal updates.

## Before pushing

1. Review `git remote -v` and `git status`.
2. Run catalog, compatibility, tooling, Python and Terraform offline checks.
3. Inspect the staged file list. Never include the historical `SandboxPluralSight-main/`,
   generated artifacts, credentials, real environment identifiers or Terraform state.
4. Review the MIT license and original content. Check third-party licenses before copying code.
5. Commit the intended changes and push to the existing remote with an authorized account.

## Continuous integration

The included workflow checks catalog contracts, all ten application scenarios,
SDK contracts and mock Terraform plans. It does not use sandbox credentials,
perform `apply`, or certify live Azure compatibility.

Recommended future settings: require passing checks when collaborators are added,
enable available secret scanning, and keep sandbox credentials out of Actions secrets.
Repository settings have not been changed by the workshop implementation.

## First live verification

Choose Tiny Notes or Observable API, start a fresh Pluralsight sandbox, and follow
[Run a project](run-a-project.md). Record deployment/publishing time, functional
checks, telemetry/alert behavior and cleanup. Only then add a sanitized
`verification_records` entry and promote that implementation to verified.
