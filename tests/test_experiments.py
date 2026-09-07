"""New workload behavior and pinned cloud boundaries; no cloud credentials."""
import base64
from concurrent.futures import ThreadPoolExecutor
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
import unittest
from unittest.mock import MagicMock, patch

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "apps/workshop"))
sys.path.insert(0, str(ROOT / "scripts"))
from core import Workshop, PROJECTS
from local_adapters import MemoryStore
from experiments import MemoryFiles, MemoryFlags, decode_file_event, summarize_file
from inventory import Inventory, AzureSqlInventory
from check_project import check


class ExperimentTests(unittest.TestCase):
    def test_catalog_and_python_projects_match(self):
        ids = {json.loads(p.read_text())["id"] for p in (ROOT / "labs").glob("*/lab.json")}
        self.assertEqual(ids, set(PROJECTS))

    def test_file_processing_validation_and_duplicates(self):
        files = MemoryFiles()
        files.upload("demo", '{"items":[{"sku":"part","quantity":3}]}')
        files.process("demo")
        files.process("demo")
        self.assertEqual(files.results(), [{"id": "demo", "disposition": "processed", "total_quantity": 3}])
        for invalid in ('[]', '{}', '{"items":[{"sku":"x","quantity":true}]}', '{"items":[{"sku":"../x","quantity":2}]}', "broken"):
            self.assertEqual(summarize_file(invalid)["disposition"], "rejected")

    def test_event_encoding_is_explicit_and_bounded(self):
        event = {"eventType": "Microsoft.Storage.BlobCreated", "subject": "/blobServices/default/containers/inbox/blobs/demo.json"}
        raw = json.dumps(event).encode()
        for payload in (raw, base64.b64encode(raw)):
            self.assertEqual(decode_file_event(payload), event)
        for payload in (b"[]", b"null", b"invalid!", b"x" * 65537):
            with self.assertRaises(ValueError):
                decode_file_event(payload)
        host = json.loads((ROOT / "apps/workshop/host.json").read_text())
        self.assertEqual(host["extensions"]["queues"]["messageEncoding"], "none")

    def test_object_body_and_sql_identifiers_are_validated(self):
        for project in ("file-pipeline", "feature-flags", "sql-inventory"):
            inventory = Inventory()
            self.addCleanup(inventory.close)
            app = Workshop(project, MemoryStore(), files=MemoryFiles(), flags=MemoryFlags(), inventory=inventory)
            self.assertEqual(app.handle("POST", "/api/files", raw_body=b"[]").status, 400)
        inventory = Inventory()
        self.addCleanup(inventory.close)
        app = Workshop("sql-inventory", MemoryStore(), inventory=inventory)
        self.assertEqual(app.handle("POST", "/api/inventory/items", raw_body=b'{"sku":"x;DROP TABLE workshop_items","stock":3}').status, 400)

    def test_sql_overselling_and_joined_ledger(self):
        inventory = Inventory()
        self.addCleanup(inventory.close)
        self.assertTrue(inventory.add("demo", 5))
        self.assertFalse(inventory.add("demo", 99))
        with ThreadPoolExecutor(max_workers=10) as pool:
            results = list(pool.map(lambda _: inventory.purchase("demo", 1), range(10)))
        self.assertEqual(sum(r is not None for r in results), 5)
        self.assertEqual(inventory.items(), [{"sku": "demo", "stock": 0, "sold": 5}])
        self.assertEqual(len(inventory.orders()), 5)

    def test_failed_ledger_insert_rolls_back_stock(self):
        inventory = Inventory()
        self.addCleanup(inventory.close)
        inventory.add("demo", 3)
        inventory.connection.execute("CREATE TRIGGER reject_order BEFORE INSERT ON workshop_orders BEGIN SELECT RAISE(ABORT, 'synthetic failure'); END")
        with self.assertRaises(Exception):
            inventory.purchase("demo", 2)
        self.assertEqual(inventory.items()[0]["stock"], 3)
        self.assertEqual(inventory.orders(), [])

    def test_container_startup_failure_is_executable(self):
        result = subprocess.run([sys.executable, str(ROOT / "apps/workshop/container_app.py")],
                                env={**os.environ, "BROKEN_STARTUP": "true"}, capture_output=True, text=True, timeout=10)
        self.assertEqual(result.returncode, 2)
        self.assertEqual(json.loads(result.stdout)["event"], "intentional_startup_failure")

    def test_cloud_modes_cannot_claim_local_network_or_sql_proof(self):
        with self.assertRaises(ValueError):
            check("network-detective", "https://synthetic.azurewebsites.net", "azure")
        with self.assertRaises(ValueError):
            check("sql-inventory", "http://synthetic.invalid", "azure-sql")

    def test_network_probe_uses_expected_server_body(self):
        import network_probe
        response = MagicMock()
        response.status = 200
        response.read.return_value = b'{"status":"healthy","synthetic":true}'
        response.__enter__.return_value = response
        with patch.object(network_probe.opener, "open", return_value=response):
            self.assertTrue(network_probe.reachable("10.42.2.4"))
            response.read.return_value = b'{"status":"unrelated"}'
            self.assertFalse(network_probe.reachable("10.42.2.4"))


@unittest.skipUnless(importlib.util.find_spec("azure") is not None, "Install the pinned Azure requirements")
class ExtraAzureContractTests(unittest.TestCase):
    def test_file_event_never_fetches_untrusted_url(self):
        import azure_extras
        adapter = object.__new__(azure_extras.AzureFiles)
        adapter.service = MagicMock()
        blob = adapter.service.get_blob_client.return_value
        blob.get_blob_properties.return_value.size = 42
        blob.download_blob.return_value.readall.return_value = b'{"items":[{"sku":"demo","quantity":2}]}'
        adapter.process_event({"eventType": "Microsoft.Storage.BlobCreated",
                               "subject": "/blobServices/default/containers/inbox/blobs/demo.json",
                               "data": {"url": "https://synthetic.invalid/untrusted"}})
        self.assertEqual(adapter.service.get_blob_client.call_args_list[0].args, ("inbox", "demo.json"))
        self.assertEqual(adapter.service.get_blob_client.call_args_list[1].args, ("processed", "demo.json"))
        with self.assertRaises(ValueError):
            adapter.process_event({"eventType": "Microsoft.Storage.BlobCreated",
                                   "subject": "/blobServices/default/containers/inbox/blobs/../escape.json"})

    def test_app_configuration_setting_contract(self):
        import azure_extras
        adapter = object.__new__(azure_extras.AzureFlags)
        adapter.client = MagicMock()
        adapter.write('{"enabled":true}')
        setting = adapter.client.set_configuration_setting.call_args.args[0]
        self.assertEqual(setting.key, "workshop:beta-offer")
        self.assertEqual(json.loads(setting.value), {"enabled": True})


@unittest.skipUnless(importlib.util.find_spec("pytds") is not None, "Install the SQL requirements")
class SqlTlsContractTests(unittest.TestCase):
    def test_pinned_tls_context_constructs_without_network(self):
        import certifi
        import pytds.tls
        from OpenSSL import SSL
        context = pytds.tls.create_context(certifi.where())
        self.assertEqual(context.get_verify_mode(), SSL.VERIFY_PEER)

    def test_tls_encryption_and_transactions_are_required(self):
        import inspect
        import pytds
        signature = inspect.signature(pytds.connect)
        with patch.dict(os.environ, {"WORKSHOP_SQL_HOST": "synthetic.database.windows.net", "WORKSHOP_SQL_PASSWORD": "synthetic-test-value"}):
            with patch.object(pytds, "connect") as connect:
                adapter = AzureSqlInventory()
                arguments = connect.call_args.kwargs
                signature.bind(**arguments)
                self.assertTrue(arguments["validate_host"])
                self.assertFalse(arguments["enc_login_only"])
                self.assertFalse(arguments["autocommit"])
                self.assertTrue(Path(arguments["cafile"]).is_file())
                connect.return_value.commit.assert_called_once()
                connect.return_value.close.assert_called_once()
                self.assertEqual(adapter.statement("SELECT * FROM workshop_items WHERE sku=?"), "SELECT * FROM dbo.workshop_items WHERE sku=%s")

    def test_invalid_sql_host_rejected_before_login(self):
        with patch.dict(os.environ, {"WORKSHOP_SQL_HOST": "synthetic.invalid"}):
            with self.assertRaises(ValueError):
                AzureSqlInventory()
