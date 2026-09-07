"""Bounded functional checks against the local runner or a deployed Function App."""
import argparse
import json
import os
from pathlib import Path
import time
from urllib.error import HTTPError
from urllib.parse import urlsplit
from urllib.request import HTTPRedirectHandler, Request, build_opener
import uuid
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "apps/workshop"))
from core import PROJECTS, FUNCTION_PROJECTS


class NoRedirects(HTTPRedirectHandler):
    def redirect_request(self, request, response, code, message, headers, new_url):
        # Never forward the Function key to a redirect destination.
        return None


def check(project, base, mode="local", repaired=False):
    parsed = urlsplit(base)
    local = parsed.hostname in ("127.0.0.1", "localhost")
    if parsed.username or parsed.password or parsed.query or parsed.fragment:
        raise ValueError("Base URL must not contain credentials, a query or a fragment.")
    if project not in PROJECTS or mode not in ("local", "azure", "azure-sql"):
        raise ValueError("Unknown project or execution mode")
    if mode == "azure" and project not in FUNCTION_PROJECTS:
        raise ValueError("Use the project-specific Azure checker for this workload")
    if mode == "azure-sql" and project != "sql-inventory":
        raise ValueError("Only SQL inventory supports the Azure SQL backend")
    if mode in ("local", "azure-sql") and (not local or parsed.scheme != "http"):
        raise ValueError("Local checks accept only loopback HTTP URLs.")
    if mode == "azure" and (parsed.scheme != "https" or not (parsed.hostname or "").endswith(".azurewebsites.net")):
        raise ValueError("Azure checks require the Function App's HTTPS azurewebsites.net URL.")
    key = os.environ.get("WORKSHOP_FUNCTION_KEY", "") if mode == "azure" else ""
    if mode == "azure" and not key:
        raise ValueError("Set WORKSHOP_FUNCTION_KEY in this process's environment.")
    checks = []
    opener = build_opener(NoRedirects())

    def request(path, status=200, body=None):
        headers = {"Content-Type": "application/json"}
        if key:
            headers["x-functions-key"] = key
        req = Request(base.rstrip("/") + path, headers=headers,
                      data=json.dumps(body).encode() if body is not None else None)
        try:
            response = opener.open(req, timeout=30)
        except HTTPError as error:
            response = error
        with response:
            actual = response.code
            data = json.load(response)
        if actual != status:
            raise AssertionError(f"Unexpected HTTP status: expected {status}, received {actual}.")
        return data

    def require(condition, label):
        if not condition:
            raise AssertionError(label)
        checks.append(label)

    require(request("/api/health")["project"] == project, "Selected project is running")
    if project == "observable-serverless-api":
        require(request("/api/work")["mode"] == "normal", "Normal response")
        start = time.monotonic()
        request("/api/work?mode=slow")
        require(time.monotonic() - start >= .2, "Controlled latency")
        require(request("/api/work?mode=fail", status=500)["mode"] == "fail", "Synthetic failure")
    elif project == "tiny-notes":
        note = request("/api/notes", status=201, body={"text": "Synthetic functional-check note"})
        require(any(row["id"] == note["id"] for row in request("/api/notes")["notes"]), "Created note can be read")
    elif project == "broken-dependency":
        result = request("/api/checkout", status=200 if repaired else 503)
        require(result.get("status") == "checkout_ready" if repaired else result.get("error") == "dependency_unavailable",
                "Repaired checkout" if repaired else "Expected dependency failure reproduced")
    elif project == "search-playground":
        request("/api/seed", body={})
        for query, expected in (("poison", "queues"), ("DNS", "dns"), ("latency", "latency"), ("identities", "identity")):
            for attempt in range(15):
                result = request("/api/search?q=" + query)
                if result["matches"] and result["matches"][0]["id"] == expected:
                    break
                time.sleep(2)
            require(bool(result["matches"]) and result["matches"][0]["id"] == expected, "Top result for " + query)
            require(result["answer"] == result["matches"][0]["content"], "Answer grounded in retrieved text for " + query)
        require(request("/api/search?q=quasarzzzz")["answer"] is None, "Unknown query abstains")
    elif project == "queue-worker":
        order_id, poison_id = str(uuid.uuid4()), str(uuid.uuid4())
        for kind, identity in (("normal", order_id), ("normal", order_id), ("poison", poison_id)):
            request("/api/messages", status=202, body={"id": identity, "kind": kind})
        for attempt in range(45):
            if mode == "local":
                request("/api/tick", body={})
            receipts = request("/api/receipts")["receipts"]
            failed = request("/api/deadletters")["messages"]
            if order_id in receipts and any(row["order"]["id"] == poison_id for row in failed):
                break
            time.sleep(0 if mode == "local" else 2)
        require(receipts.count(order_id) == 1, "Duplicate orders produce one receipt")
        require(any(row["order"]["id"] == poison_id for row in failed), "Poison message reached dead-letter queue")
    elif project == "file-pipeline":
        good, bad = str(uuid.uuid4()), str(uuid.uuid4())
        document = {"id": good, "content": json.dumps({"items": [{"sku": "demo", "quantity": 3}]})}
        request("/api/files", status=202, body=document)
        request("/api/files", status=409, body=document)
        request("/api/files", status=202, body={"id": bad, "content": "not-json"})
        for attempt in range(45):
            if mode == "local":
                request("/api/files/tick", body={})
            results = {r["id"]: r for r in request("/api/files/results")["results"]}
            if good in results and bad in results:
                break
            time.sleep(0 if mode == "local" else 2)
        require(results.get(good, {}).get("total_quantity") == 3, "Valid document processed")
        require(results.get(bad, {}).get("disposition") == "rejected", "Malformed document quarantined")
        require(True, "Duplicate input ID rejected")
    elif project == "feature-flags":
        for flag, variant in (("on", "beta"), ("off", "stable")):
            request("/api/flags", body={"mode": flag})
            require(request("/api/offer")["variant"] == variant, "Configuration changes response: " + flag)
        request("/api/flags", body={"mode": "broken"})
        require(request("/api/offer", status=503)["error"] == "invalid_feature_flag", "Invalid configuration fails visibly")
        request("/api/flags", body={"mode": "off"})
        require(request("/api/offer")["variant"] == "stable", "Configuration recovered")
    elif project == "network-detective":
        for fault, direct, named in (("healthy", True, True), ("nsg", False, False), ("dns", True, False)):
            result = request("/api/network?fault=" + fault)
            require(result["engine"] == "conceptual_simulation" and result["direct_connection"] == direct
                    and result["named_connection"] == named, "Conceptual network diagnosis: " + fault)
    elif project == "container-playground":
        require(request("/api/container")["version"] in ("v1", "v2"), "Versioned container application responds")
    elif project == "sql-inventory":
        require(request("/api/inventory")["engine"] == ("azure_sql" if mode == "azure-sql" else "sqlite_memory"), "Expected database backend")
        sku = "check-" + uuid.uuid4().hex[:12]
        request("/api/inventory/items", status=201, body={"sku": sku, "stock": 3})
        purchase = request("/api/inventory/purchase", status=201, body={"sku": sku, "quantity": 2})
        require(purchase["remaining"] == 1, "Purchase decrements stock")
        request("/api/inventory/purchase", status=409, body={"sku": sku, "quantity": 2})
        row = next(r for r in request("/api/inventory")["items"] if r["sku"] == sku)
        require(row["stock"] == 1 and row["sold"] == 2, "Overselling rejected and joined ledger consistent")
    # An allowlisted summary, never raw cloud responses or user data.
    return {"project": project, "mode": mode, "passed": True, "checks": checks}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project", choices=PROJECTS, required=True)
    parser.add_argument("--base-url", default="http://127.0.0.1:7071")
    parser.add_argument("--mode", choices=("local", "azure", "azure-sql"), default="local")
    parser.add_argument("--expect-repaired", action="store_true")
    parser.add_argument("--evidence", type=Path)
    args = parser.parse_args()
    try:
        result = check(args.project, args.base_url, args.mode, args.expect_repaired)
    except Exception as error:
        # Do not serialize remote error bodies, URLs, tokens or supplied notes.
        print(json.dumps({"project": args.project, "passed": False, "error_type": type(error).__name__}))
        raise SystemExit(1)
    output = json.dumps(result, indent=2)
    print(output)
    if args.evidence:
        args.evidence.parent.mkdir(parents=True, exist_ok=True)
        args.evidence.write_text(output + "\n", encoding="utf-8")
