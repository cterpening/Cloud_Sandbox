# Network Detective

Diagnose DNS and NSG faults between two private small VMs; compare the local conceptual simulation with real probes.

**Implemented and offline-tested; not live-sandbox verified.** Normal Pluralsight
Azure is the first target. Use synthetic data and run one project at a time.

## Architecture card

Run Command → private client VM → private DNS / TCP 8080 → private server VM; both subnets → NAT → Azure control endpoints

Two Standard_B1s VMs (two total vCPUs), two subnets/NICs/NSGs, one private DNS zone/link/record, and one Standard NAT gateway with an egress-only public IP.

Estimate: 10 minutes locally, 90 minutes for the Azure exercise including
inspection and cleanup. These are planning estimates, not measured durations.

## Start

From the repository root, use Python 3.11+:

```powershell
python apps/workshop/local.py --project network-detective
```

Open **http://127.0.0.1:7071/api/ui**. In another terminal:

```powershell
python scripts/check_project.py --project network-detective --evidence evidence/network-detective-local.json
```

For Azure prerequisites and deployment, use the [implementation guide](implementations/azure/README.md)
and [shared runbook](../../docs/run-a-project.md). A local pass is not cloud proof.

## Try

Locally, choose the three Network operations and compare predictions. These are
**conceptual simulations**, not actual DNS or packet filtering.

In Azure, deploy with `fault = "healthy"`, let cloud-init finish, then run the
native checker. It executes the repository-owned read-only Python probe on the
client VM through Run Command. DNS must match the server; both direct-IP and
hostname HTTP requests must return the expected synthetic body.

## Break

After a passing healthy baseline, change `fault` in the ignored tfvars file to
`"nsg"`, review/apply Terraform, and rerun the checker. DNS still matches; direct
and named connections fail. Then change to `"dns"`: direct IP succeeds, DNS points
to the wrong address, and named access fails. Restore `"healthy"` and check again.

A checker matching an injected failure does not independently prove its cause:
compare with the healthy baseline and successful repair.

## Remix

Change the synthetic API port consistently in server code, NSG and probe, or
add an investigation worksheet predicting each connection. A third VM, gateway,
peering or private endpoint is a separate quota-reviewed extension.

## Tradeoffs and production extension

Neither VM has a public IP or a public SSH listener. Both use explicit outbound
NAT so the VM agent can return Run Command results. NSGs allow AzureCloud HTTPS
egress and deny other Internet traffic; this is a broad Azure service tag, not a
precise per-service allowlist. No apt installs are needed.

Private DNS support is an inference from the sandbox's published Azure DNS
category; live validation is still required. Production needs a deliberate
administrative access path, egress policy, patched/pinned images, diagnostic
retention and least-privilege access. NAT adds a metered resource outside sandboxes.

## Evidence and cleanup

Keep the checker's allowlisted summary and a short synthetic observation about
failure and recovery. Do not publish raw state, identifiers, secrets or portal
exports. Local mode stops with Ctrl+C; Docker's --rm removes its stopped container.

After Azure work, inspect the scope and confirm the resource name when prompted:

```powershell
pwsh scripts/Remove-Lab.ps1 -Lab network-detective
```

This removes the selected project's resources and cloud data, not the assigned
resource group. State, plans and evidence remain ignored local files; protect
them. Record deployment, verification and cleanup outcomes before adding a live
verification record.

## Troubleshooting

A missing probe marker can mean unavailable Run Command permissions, VM agent health, or outbound connectivity—not an NSG application fault. Use a fresh session with no existing VMs. Do not open SSH to everyone as a workaround.

## Primary sources

Reviewed 2026-09-07; documented fit does not guarantee session permissions/capacity.

- [Pluralsight Azure sandbox restrictions](https://help.pluralsight.com/hc/en-us/articles/24392988447636-Azure-cloud-sandbox)
- [Run Command requirements and outbound HTTPS](https://learn.microsoft.com/en-us/azure/virtual-machines/linux/run-command)
- [Azure NAT Gateway overview](https://learn.microsoft.com/en-us/azure/nat-gateway/nat-overview)
- [Private DNS virtual network links](https://learn.microsoft.com/en-us/azure/dns/private-dns-virtual-network-links)
