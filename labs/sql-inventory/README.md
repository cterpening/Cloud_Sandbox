# Tiny SQL Inventory

Create inventory, purchase stock transactionally and prove an oversell is rejected; use local SQLite or workstation-to-Azure-SQL TLS.

**Implemented and offline-tested; not live-sandbox verified.** Normal Pluralsight
Azure is the first target. Use synthetic data and run one project at a time.

## Architecture card

Loopback browser/API → parameterized transaction → SQLite (local) or TLS/workstation /32 → Azure SQL → joined inventory/order ledger

One Azure SQL logical server and one Basic 2 GiB database; one workstation-only firewall rule. The app runs locally, not in a cloud Function.

Estimate: 15 minutes locally, 60 minutes for the Azure exercise including
inspection and cleanup. These are planning estimates, not measured durations.

## Start

From the repository root, use Python 3.11+:

```powershell
python apps/workshop/local.py --project sql-inventory
```

Open **http://127.0.0.1:7071/api/ui**. In another terminal:

```powershell
python scripts/check_project.py --project sql-inventory --evidence evidence/sql-inventory-local.json
```

For Azure prerequisites and deployment, use the [implementation guide](implementations/azure/README.md)
and [shared runbook](../../docs/run-a-project.md). A local pass is not cloud proof.

## Try

Add SKU `demo` with stock 3 in the page. Purchase quantity 2, then list inventory:
remaining stock is 1 and joined sold quantity is 2. The checker creates its own
unique synthetic SKU. The local version uses a real in-memory SQLite database.

After the Azure deployment, install the SQL-specific dependencies and launch with
`Start-SqlInventory.ps1`. Its startup creates two tables if absent, without dropping
anything. Use checker mode `azure-sql` to ensure the backend really is Azure SQL,
not the SQLite stand-in.

## Break

Purchase 2 again: HTTP 409 and unchanged stock/order totals demonstrate oversell
rejection. Try quantity 0 or a non-identifier SKU: HTTP 400. The tests inject a
ledger-insert failure and verify that the stock decrement rolls back.

The purchase uses a conditional UPDATE and an INSERT in the same transaction;
stock must not be decremented without recording the order.

## Remix

Add a small category column and grouped report, compare the table model with
Tiny Notes, or design a purchase idempotency key. Duplicate HTTP purchase requests
are currently separate orders: **do not treat this as payment-ready logic**.

## Tradeoffs and production extension

The firewall allows only the current workstation IPv4 /32. The special all-Azure-
services 0.0.0.0 rule is rejected. TLS encrypts the full session and validates the
server certificate/hostname. No public web app or broad dynamic outbound firewall
exception is needed.

A generated SQL admin password is sensitive Terraform state. The launcher passes
it through a child process environment, never command-line arguments or evidence.
This is a temporary sandbox compromise. Production needs least-privilege database
users/workload identity, protected remote state, private connectivity, migration
management, retry/idempotency design, backups and recovery tests.

## Evidence and cleanup

Keep the checker's allowlisted summary and a short synthetic observation about
failure and recovery. Do not publish raw state, identifiers, secrets or portal
exports. Local mode stops with Ctrl+C; Docker's --rm removes its stopped container.

After Azure work, inspect the scope and confirm the resource name when prompted:

```powershell
pwsh scripts/Remove-Lab.ps1 -Lab sql-inventory
```

This removes the selected project's resources and cloud data, not the assigned
resource group. State, plans and evidence remain ignored local files; protect
them. Record deployment, verification and cleanup outcomes before adding a live
verification record.

## Troubleshooting

If SQL startup fails, inspect the selected subscription, server readiness, workstation egress /32 and outbound TCP 1433 privately. Install requirements-sql.txt into the Python environment actually used by the launcher. Never print the password to diagnose a connection.

## Primary sources

Reviewed 2026-09-07; documented fit does not guarantee session permissions/capacity.

- [Pluralsight Azure sandbox restrictions](https://help.pluralsight.com/hc/en-us/articles/24392988447636-Azure-cloud-sandbox)
- [Azure SQL server firewall rules](https://learn.microsoft.com/en-us/azure/azure-sql/database/firewall-configure?view=azuresql)
- [Azure SQL connectivity and Proxy policy](https://learn.microsoft.com/en-us/azure/azure-sql/database/connectivity-architecture?view=azuresql)
- [python-tds source and TLS API](https://github.com/denisenkom/pytds)
