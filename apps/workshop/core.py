"""Small experiments shared by the local runner and Azure Functions.

Cloud adapters are injected; the domain code can be tested without credentials.
"""
from dataclasses import dataclass
import json
import logging
from pathlib import Path
import re
import time
import uuid

PROJECTS = ("observable-serverless-api", "tiny-notes", "queue-worker",
            "broken-dependency", "search-playground")
CORPUS = json.loads(Path(__file__).with_name("corpus.json").read_text(encoding="utf-8"))


class BackendUnavailable(Exception):
    """A deliberately misconfigured or unavailable backing service."""


@dataclass
class Response:
    status: int
    body: object
    content_type: str = "application/json"

    def encode(self):
        if self.content_type == "application/json":
            return json.dumps(self.body).encode("utf-8")
        return str(self.body).encode("utf-8")


def valid_order(body):
    if not isinstance(body, dict) or body.get("kind") not in ("normal", "poison"):
        raise ValueError("Expected kind: normal or poison.")
    order_id = body.get("id", str(uuid.uuid4()))
    if not isinstance(order_id, str) or not re.fullmatch(r"[a-zA-Z0-9-]{1,64}", order_id):
        raise ValueError("Use a synthetic order id of 1-64 letters, digits, or hyphens.")
    return {"id": order_id, "kind": body["kind"]}


def process_order(order, store):
    order = valid_order(order)
    if order["kind"] == "poison":
        raise ValueError("Intentional poison message: correct its kind before resubmitting.")
    # The receipt is the complete effect of this toy worker. An atomic insert
    # makes duplicates harmless; this is NOT a transactional payment processor.
    return "processed" if store.receipt(order["id"]) else "duplicate"


class Workshop:
    def __init__(self, project, store, queue=None, search=None, dependency_table="missingitems"):
        if project not in PROJECTS:
            raise ValueError("Unknown project")
        self.project, self.store = project, store
        self.queue, self.search = queue, search
        self.dependency_table = dependency_table

    def handle(self, method, path, query=None, raw_body=b""):
        query = query or {}
        correlation = str(uuid.uuid4())
        started = time.monotonic()
        try:
            if len(raw_body) > 8192:
                result = Response(413, {"error": "Request exceeds 8 KiB."})
            else:
                body = json.loads(raw_body) if raw_body else {}
                result = self.route(method, path.rstrip("/") or "/", query, body)
        except (ValueError, UnicodeDecodeError, TypeError):
            result = Response(400, {"error": "Invalid input; see this project's README."})
        except BackendUnavailable:
            result = Response(503, {"error": "dependency_unavailable", "hint": "Check the configured table against the provisioned table."})
        except Exception:
            # SDK errors can contain resource URLs. Keep those out of shared logs.
            result = Response(502, {"error": "backend_request_failed", "hint": "Check credentials, deployment, and service access locally."})
        if isinstance(result.body, dict):
            result.body = {**result.body, "correlation_id": correlation}
        event = {"event": "workshop_request", "project": self.project,
                 "correlation_id": correlation, "status": result.status,
                 "duration_ms": round((time.monotonic() - started) * 1000)}
        logging.getLogger("workshop").log(logging.ERROR if result.status >= 500 else logging.INFO, json.dumps(event))
        return result

    def route(self, method, path, query, body):
        if method == "GET" and path in ("/", "/api/ui"):
            return Response(200, Path(__file__).with_name("index.html").read_text(encoding="utf-8"), "text/html; charset=utf-8")
        if method == "GET" and path == "/api/health":
            return Response(200, {"status": "healthy", "project": self.project})
        if self.project == "observable-serverless-api" and path == "/api/work" and method == "GET":
            mode = query.get("mode", "normal")
            if mode not in ("normal", "slow", "fail"):
                raise ValueError("Unknown mode")
            if mode == "slow":
                time.sleep(0.25)
            return Response(500 if mode == "fail" else 200, {"mode": mode, "synthetic": True})
        if self.project == "tiny-notes" and path == "/api/notes":
            if method == "GET":
                return Response(200, {"notes": self.store.notes()})
            if method == "POST":
                text = body.get("text") if isinstance(body, dict) else None
                if not isinstance(text, str) or not 1 <= len(text.strip()) <= 500:
                    raise ValueError("Note must contain 1-500 characters")
                return Response(201, self.store.add_note(text.strip()))
        if self.project == "queue-worker":
            if path == "/api/messages" and method == "POST":
                order = valid_order(body)
                self.queue.send(order)
                return Response(202, {"accepted": order})
            if path == "/api/receipts" and method == "GET":
                return Response(200, {"receipts": self.store.receipts()})
            if path == "/api/deadletters" and method == "GET":
                return Response(200, {"messages": self.queue.deadletters()})
            if path == "/api/tick" and method == "POST" and hasattr(self.queue, "tick"):
                return Response(200, self.queue.tick(self.store))
        if self.project == "broken-dependency" and path == "/api/checkout" and method == "GET":
            self.store.probe(self.dependency_table)
            return Response(200, {"status": "checkout_ready", "synthetic": True})
        if self.project == "search-playground":
            if path == "/api/seed" and method == "POST":
                self.search.seed(CORPUS)
                return Response(200, {"documents": len(CORPUS)})
            if path == "/api/search" and method == "GET":
                question = query.get("q", "")
                if not isinstance(question, str) or not 1 <= len(question) <= 200:
                    raise ValueError("Supply a short query")
                matches = self.search.query(question)
                return Response(200, {"matches": matches, "answer": matches[0]["content"] if matches else None,
                                      "answer_mode": "extractive_demo", "engine": self.search.engine})
        return Response(404, {"error": "Route is not part of this project."})
