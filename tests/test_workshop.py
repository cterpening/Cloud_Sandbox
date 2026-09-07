import json
from pathlib import Path
import sys
import threading
import time
import unittest
from urllib.error import HTTPError
from urllib.request import Request, urlopen

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "apps/workshop"))
from core import CORPUS, Workshop
from local import make_server
from local_adapters import MemoryStore, MemoryQueue, MemorySearch


class WorkshopTests(unittest.TestCase):
    def make(self, project, table="missingitems"):
        return Workshop(project, MemoryStore(), MemoryQueue(), MemorySearch(), table)

    def test_api_modes_and_correlation(self):
        app = self.make("observable-serverless-api")
        normal = app.handle("GET", "/api/work")
        self.assertEqual(normal.status, 200)
        started = time.monotonic()
        self.assertEqual(app.handle("GET", "/api/work", {"mode": "slow"}).status, 200)
        self.assertGreaterEqual(time.monotonic() - started, .2)
        failed = app.handle("GET", "/api/work", {"mode": "fail"})
        self.assertEqual(failed.status, 500)
        self.assertNotEqual(normal.body["correlation_id"], failed.body["correlation_id"])

    def test_notes_round_trip_and_invalid_payloads(self):
        app = self.make("tiny-notes")
        result = app.handle("POST", "/api/notes", raw_body=json.dumps({"text": "synthetic note"}).encode())
        self.assertEqual(result.status, 201)
        self.assertIn({"id": result.body["id"], "text": "synthetic note"}, app.handle("GET", "/api/notes").body["notes"])
        for body in (b"{", b"[]", b'{"text":""}', b'{"text":12}', b'"text"'):
            self.assertEqual(app.handle("POST", "/api/notes", raw_body=body).status, 400)
        self.assertEqual(app.handle("POST", "/api/notes", raw_body=b"x" * 8193).status, 413)

    def test_duplicate_orders_poison_and_resubmission(self):
        app = self.make("queue-worker")
        for kind, order_id in (("normal", "one"), ("normal", "one"), ("poison", "two")):
            response = app.handle("POST", "/api/messages", raw_body=json.dumps({"id": order_id, "kind": kind}).encode())
            self.assertEqual(response.status, 202)
        outcomes = [app.handle("POST", "/api/tick").body["status"] for _ in range(5)]
        self.assertEqual(outcomes, ["processed", "duplicate", "retrying", "retrying", "deadlettered"])
        self.assertEqual(app.store.receipts(), ["one"])
        self.assertEqual(app.queue.deadletters()[0]["attempts"], 3)
        app.handle("POST", "/api/messages", raw_body=b'{"id":"two","kind":"normal"}')
        app.handle("POST", "/api/tick")
        self.assertEqual(app.store.receipts(), ["one", "two"])
        self.assertEqual(len(app.queue.deadletters()), 1)

    def test_broken_dependency_recovers_after_configuration_change(self):
        app = self.make("broken-dependency")
        self.assertEqual(app.handle("GET", "/api/health").status, 200)
        self.assertEqual(app.handle("GET", "/api/checkout").status, 503)
        app.dependency_table = "items"
        self.assertEqual(app.handle("GET", "/api/checkout").status, 200)

    def test_retrieval_grounding_and_abstention(self):
        app = self.make("search-playground")
        app.handle("POST", "/api/seed")
        for query, expected in (("poison", "queues"), ("DNS", "dns"), ("latency", "latency"), ("identities", "identity")):
            result = app.handle("GET", "/api/search", {"q": query}).body
            self.assertEqual(result["matches"][0]["id"], expected)
            self.assertEqual(result["answer"], next(doc["content"] for doc in CORPUS if doc["id"] == expected))
            self.assertEqual(result["answer_mode"], "extractive_demo")
        unknown = app.handle("GET", "/api/search", {"q": "quasarzzzz"}).body
        self.assertEqual(unknown["matches"], [])
        self.assertIsNone(unknown["answer"])

    def test_only_selected_project_routes_are_available(self):
        self.assertEqual(self.make("tiny-notes").handle("GET", "/api/work").status, 404)
        self.assertEqual(self.make("observable-serverless-api").handle("POST", "/api/work").status, 404)

    def test_public_page_contains_no_injected_note_html(self):
        result = self.make("tiny-notes").handle("GET", "/api/ui")
        self.assertEqual(result.status, 200)
        self.assertIn("result.textContent", result.body)
        self.assertNotIn("innerHTML", result.body)

    def test_actual_http_server_round_trip(self):
        server = make_server("tiny-notes", port=0)
        thread = threading.Thread(target=server.serve_forever, daemon=True)
        thread.start()
        try:
            base = f"http://127.0.0.1:{server.server_port}"
            request = Request(base + "/api/notes", data=b'{"text":"from HTTP"}', headers={"Content-Type": "application/json"})
            with urlopen(request, timeout=3) as response:
                self.assertEqual(response.status, 201)
            with urlopen(base + "/api/notes", timeout=3) as response:
                self.assertEqual(json.load(response)["notes"][0]["text"], "from HTTP")
            with self.assertRaises(HTTPError) as error:
                urlopen(Request(base + "/api/notes", data=b"["), timeout=3)
            self.assertEqual(error.exception.code, 400)
            error.exception.close()
        finally:
            server.shutdown()
            server.server_close()
            thread.join(timeout=3)


if __name__ == "__main__":
    unittest.main()
