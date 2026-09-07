# Contributing

Contributions should make the library more accurate, more portable, or easier to complete safely in a temporary sandbox.

## Propose before building

For a substantial lab, start with a proposal containing:

- Problem and audience.
- Portable capabilities being taught.
- First cloud implementation.
- Intended sandbox platform.
- Expected duration.
- Required services, permissions, SKUs, and quotas.
- Known sandbox compromises.
- Production-grade extension.
- Primary sources.

The lab proposal issue template can be used once the project is hosted on GitHub.

## Lab lifecycle

| State | Meaning |
| --- | --- |
| `idea` | Captured but not designed. |
| `designed` | Architecture, requirements, and success criteria are documented. |
| `implemented` | Code and instructions exist. |
| `verified` | Successfully run in the declared sandbox profile. |
| `published` | Ready for public use. |
| `maintenance` | Published and periodically revalidated. |
| `retired` | Retained for history but no longer recommended. |

Public GitHub availability alone does not promote a project to `verified` or
`published` maturity. The current five projects remain `implemented` until their
live run records exist.

## Implementation checks

Run `pwsh scripts/Test-Tooling.ps1` as well as catalog/compatibility checks.
Install `apps/workshop/requirements.txt` in a virtual environment and run
`python -m unittest discover -s tests -v`. Shared workload/module changes must test
all five projects. In each changed Terraform root, run `terraform init -backend=false`,
`terraform fmt -check`, `terraform validate` and `terraform test` (mock providers).
The GitHub workflow performs these checks without cloud credentials; passing it
does not prove a live deployment works.

## Adding a lab

1. Copy `templates/lab/` into `labs/<lab-id>/`.
2. Complete `lab.json` before writing infrastructure.
3. Add the lab to `docs/backlog.md` or update its existing item.
4. Run `scripts/Test-Catalog.ps1`.
5. Check the target platform using `scripts/Test-LabCompatibility.ps1`.
6. Add infrastructure, application code, tests, and evidence collection incrementally.
7. Record the date and outcome of real sandbox verification.

## Sources and copyright

- Link to the original vendor page instead of copying large portions.
- Summarize architectures in original language.
- Do not republish vendor diagrams unless their license explicitly permits it.
- Record a profile `reviewed_on` date for sandbox limits and reserve `verified_on` for completed lab runs.
- Mark assumptions and inferences as such.
- Avoid secondary sources when authoritative documentation exists.

## Security

See [SECURITY.md](SECURITY.md). Never submit credentials, Terraform state, exported sandbox profiles containing identifiers, or logs containing personal or customer information.
