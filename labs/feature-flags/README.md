# Feature-flag Playground

Change application behavior through App Configuration, deliberately corrupt a flag, then repair it without redeploying.

**Implemented and offline-tested; not live-sandbox verified.** Normal Pluralsight
Azure is the first target. Use synthetic data and run one project at a time.

## Architecture card

Key-protected experiment API → App Configuration setting → offer evaluation → stable / beta / visible configuration error

One App Configuration Free store plus the shared Y1 Function, storage and telemetry foundation.

Estimate: 10 minutes locally, 45 minutes for the Azure exercise including
inspection and cleanup. These are planning estimates, not measured durations.

## Start

From the repository root, use Python 3.11+:

```powershell
python apps/workshop/local.py --project feature-flags
```

Open **http://127.0.0.1:7071/api/ui**. In another terminal:

```powershell
python scripts/check_project.py --project feature-flags --evidence evidence/feature-flags-local.json
```

For Azure prerequisites and deployment, use the [implementation guide](implementations/azure/README.md)
and [shared runbook](../../docs/run-a-project.md). A local pass is not cloud proof.

## Try

Choose **Flags: set on, off or broken**. With `{"mode":"on"}`, the offer returns
beta; off returns stable. The Azure adapter reads the actual store on each offer
request. A missing setting defaults to stable. Local mode keeps the same setting
in memory. Neither toggle requires Terraform apply or republishing the app.

## Break

Set mode broken and evaluate the offer: malformed configuration produces HTTP
503 with invalid_feature_flag. Set mode off and verify recovery. The checker
executes the complete on/off/broken/repaired sequence and finishes in the off state.

## Remix

Add a validated percentage or a synthetic region selector and explicit tests.
Keep the setting schema bounded and defaults documented. Then compare direct
reads with a cache and explain how stale values change failure behavior.

## Tradeoffs and production extension

This is a simple JSON configuration-driven flag, not an implementation of Azure's
Feature Management SDK or its standardized feature-flag schema. The teaching API
can write one fixed key; the application evaluates it without a deployment.

Because normal sandbox role assignments/managed identities are unavailable, a
store write key lives in Function app settings. The same API can mutate and read
configuration; Function key plus /32 access restrict the workshop, but production
must separate administrative writes from runtime reads and use least-privilege
identities, audit trails, approvals and a safe rollout/fallback policy.

## Evidence and cleanup

Keep the checker's allowlisted summary and a short synthetic observation about
failure and recovery. Do not publish raw state, identifiers, secrets or portal
exports. Local mode stops with Ctrl+C; Docker's --rm removes its stopped container.

After Azure work, inspect the scope and confirm the resource name when prompted:

```powershell
pwsh scripts/Remove-Lab.ps1 -Lab feature-flags
```

This removes the selected project's resources and cloud data, not the assigned
resource group. State, plans and evidence remain ignored local files; protect
them. Record deployment, verification and cleanup outcomes before adding a live
verification record.

## Troubleshooting

If toggles fail, check App Configuration store readiness, data-plane access and its app setting. Use a fresh session if a Free store already occupies the region. Never paste the connection string into an issue.

## Primary sources

Reviewed 2026-09-07; documented fit does not guarantee session permissions/capacity.

- [Pluralsight Azure sandbox restrictions](https://help.pluralsight.com/hc/en-us/articles/24392988447636-Azure-cloud-sandbox)
- [App Configuration Python client](https://learn.microsoft.com/en-us/python/api/overview/azure/appconfiguration-readme?view=azure-python)
- [App Configuration feature management concepts](https://learn.microsoft.com/en-us/azure/azure-app-configuration/concept-feature-management)
