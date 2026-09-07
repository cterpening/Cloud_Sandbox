# Container Playground

Run the same small HTTP application in Python, Docker or an isolated Azure container; change versions and reproduce a startup failure.

**Implemented and offline-tested; not live-sandbox verified.** Normal Pluralsight
Azure is the first target. Use synthetic data and run one project at a time.

## Architecture card

Python source → local Python or Docker; same source → isolated ACI container → startup/liveness HTTP checks → logs

One Linux ACI group with one container, one vCPU and 1 GiB memory. No public IP, registry, AKS cluster or managed identity.

Estimate: 10 minutes locally, 45 minutes for the Azure exercise including
inspection and cleanup. These are planning estimates, not measured durations.

## Start

From the repository root, use Python 3.11+:

```powershell
python apps/workshop/local.py --project container-playground
```

Open **http://127.0.0.1:7071/api/ui**. In another terminal:

```powershell
python scripts/check_project.py --project container-playground --evidence evidence/container-playground-local.json
```

For Azure prerequisites and deployment, use the [implementation guide](implementations/azure/README.md)
and [shared runbook](../../docs/run-a-project.md). A local pass is not cloud proof.

## Try

Run locally and inspect the response version. To use Docker from the repository root:

```powershell
docker build -f apps/workshop/Dockerfile.container -t cloud-sandbox-container:local apps/workshop
docker run --rm -p 127.0.0.1:7071:8080 -e APP_VERSION=v1 cloud-sandbox-container:local
```

The image runs as a non-root user. The Python-only local runner does not prove a
Docker build works. In Azure, Terraform starts the same source on an official
Python base image using an explicit command. The native checker reads container
state and its startup health-probe log; ACI has no workstation-facing endpoint.

## Break

For Docker, add `-e BROKEN_STARTUP=true` and observe exit code 2. In Azure, set
`broken_startup = true`, review/apply, and inspect the expected startup failure
with the checker. Restore false. Set `app_version = "v2"`, apply/check, then return
to v1. ACI can recreate/restart the workload: this is **not** traffic splitting,
zero-downtime rollout or a Container Apps revision deployment.

## Remix

Add a small version-specific response or another synthetic health condition.
Rebuild the local image and retest. Publishing your own image to a registry is
an optional future extension, not a prerequisite for this recipe.

## Tradeoffs and production extension

No unauthenticated cloud HTTP endpoint is exposed. The healthy cloud check proves
running state, requested version and a successful startup HTTP probe, not a load
test or continuous availability. ACI additionally has a liveness probe.

For simplicity Terraform embeds the original Python source in the container command;
production should build, scan, sign and deploy an immutable application image.
The example base tag is mutable; use an approved digest through `container_image`
for repeatable cloud runs. Coordinate changes with the Dockerfile.

## Evidence and cleanup

Keep the checker's allowlisted summary and a short synthetic observation about
failure and recovery. Do not publish raw state, identifiers, secrets or portal
exports. Local mode stops with Ctrl+C; Docker's --rm removes its stopped container.

After Azure work, inspect the scope and confirm the resource name when prompted:

```powershell
pwsh scripts/Remove-Lab.ps1 -Lab container-playground
```

This removes the selected project's resources and cloud data, not the assigned
resource group. State, plans and evidence remain ignored local files; protect
them. Record deployment, verification and cleanup outcomes before adding a live
verification record.

## Troubleshooting

If image pull is denied or rate-limited, inspect ACI events. Do not claim cloud success from a passing local Python check. Wait for the new container instance and version marker after changes.

## Primary sources

Reviewed 2026-09-07; documented fit does not guarantee session permissions/capacity.

- [Pluralsight Azure sandbox restrictions](https://help.pluralsight.com/hc/en-us/articles/24392988447636-Azure-cloud-sandbox)
- [ACI liveness probes](https://learn.microsoft.com/en-us/azure/container-instances/container-instances-liveness-probe)
- [Pinned AzureRM container group schema](https://registry.terraform.io/providers/hashicorp/azurerm/4.64.0/docs/resources/container_group)
