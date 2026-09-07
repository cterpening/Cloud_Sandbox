"""Exercise the pinned SDK boundary without connecting to an Azure account."""
import importlib
import json
import os
from pathlib import Path
import sys
import unittest
from unittest.mock import MagicMock, patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "apps/workshop"))
try:
    import azure.functions as func
    import azure_adapters
except ImportError:
    func = None


@unittest.skipIf(func is None, "Install apps/workshop/requirements.txt to check Azure SDK contracts")
class AzureContractTests(unittest.TestCase):
    def test_function_indexing_and_key_authentication(self):
        from core import FUNCTION_PROJECTS
        for project in FUNCTION_PROJECTS:
            with patch.dict(os.environ, {"WORKSHOP_PROJECT": project}):
                sys.modules.pop("function_app", None)
                entry = importlib.import_module("function_app")
                functions = entry.app.get_functions()
                self.assertEqual(len(functions), 3 if project in ("queue-worker", "file-pipeline") else 2)
                api = next(f for f in functions if f.get_function_name() == "api")
                trigger = next(b for b in api.get_bindings() if b.type == "httpTrigger")
                self.assertEqual(trigger.auth_level, func.AuthLevel.FUNCTION)
                from local_adapters import MemoryStore
                with patch.object(entry, "AzureStore", MemoryStore):
                    request = func.HttpRequest("GET", "https://synthetic.invalid/api/health", body=b"", route_params={"path": "health"})
                    # Search construction needs endpoint settings; mock it, not a network request.
                    with patch.object(entry, "AzureSearch"), patch.object(entry, "AzureFiles"), patch.object(entry, "AzureFlags"):
                        response = api.get_user_function()(request)
                    self.assertEqual(json.loads(response.get_body())["project"], project)

    def test_receipt_conflict_is_a_duplicate(self):
        from azure.core.exceptions import ResourceExistsError
        store = object.__new__(azure_adapters.AzureStore)
        store.table = MagicMock()
        self.assertTrue(store.receipt("synthetic-order"))
        store.table.create_entity.side_effect = ResourceExistsError("synthetic conflict")
        self.assertFalse(store.receipt("synthetic-order"))

    def test_missing_table_is_classified_as_dependency_failure(self):
        from azure.core.exceptions import ResourceNotFoundError
        from core import BackendUnavailable
        store = object.__new__(azure_adapters.AzureStore)
        store.service = MagicMock()
        store.service.get_table_client.return_value.list_entities.side_effect = ResourceNotFoundError("synthetic missing table")
        with self.assertRaises(BackendUnavailable):
            store.probe("missingitems")

    def test_search_index_model_and_upload_contract(self):
        from core import CORPUS
        with patch.dict(os.environ, {"SEARCH_ENDPOINT": "https://synthetic.invalid", "SEARCH_KEY": "synthetic-test-value"}):
            with patch.object(azure_adapters, "SearchClient") as client, patch.object(azure_adapters, "SearchIndexClient") as indexes:
                client.return_value.merge_or_upload_documents.return_value = [MagicMock(succeeded=True)] * len(CORPUS)
                search = azure_adapters.AzureSearch()
                search.seed(CORPUS)
                index = indexes.return_value.create_index.call_args.args[0]
                self.assertEqual(index.name, "workshop")
                self.assertEqual([field.name for field in index.fields], ["id", "title", "content"])
                client.return_value.merge_or_upload_documents.assert_called_once_with(CORPUS)


if __name__ == "__main__":
    unittest.main()
