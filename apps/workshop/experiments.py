"""Original, bounded experiments; local adapters are not cloud emulators."""
from collections import deque
import base64
import json
import re
import uuid
from core import Response


class AssetExists(Exception):
    pass


def identifier(value):
    if not isinstance(value, str) or not re.fullmatch(r"[a-zA-Z0-9-]{1,64}", value):
        raise ValueError("Use a short synthetic identifier.")
    return value


def summarize_file(content):
    try:
        document = json.loads(content)
        items = document["items"]
        if not isinstance(items, list) or not 1 <= len(items) <= 20:
            raise ValueError()
        for item in items:
            identifier(item["sku"])
            if type(item["quantity"]) is not int or not 1 <= item["quantity"] <= 100:
                raise ValueError()
        return {"disposition": "processed", "total_quantity": sum(i["quantity"] for i in items)}
    except (ValueError, TypeError, KeyError):
        return {"disposition": "rejected", "reason": "invalid_document"}


class MemoryFiles:
    def __init__(self):
        self.inbox, self.completed, self.pending = {}, {}, deque()

    def upload(self, name, content):
        if name in self.inbox:
            raise AssetExists()
        self.inbox[name] = content
        self.pending.append(name)

    def process(self, name):
        # Input IDs are immutable, so repeated delivery produces the same output.
        self.completed[name] = {"id": name, **summarize_file(self.inbox[name])}

    def tick(self):
        if self.pending:
            self.process(self.pending.popleft())

    def results(self):
        return list(self.completed.values())[:100]


class MemoryFlags:
    def __init__(self):
        self.value = None

    def read(self):
        return self.value

    def write(self, value):
        self.value = value


def network_model(fault):
    if fault not in ("healthy", "nsg", "dns"):
        raise ValueError("Unknown fault")
    return {"engine": "conceptual_simulation", "fault": fault,
            "dns_matches_server": fault != "dns", "direct_connection": fault != "nsg",
            "named_connection": fault == "healthy"}


def route_experiment(app, method, path, query, body):
    if method == "POST" and not isinstance(body, dict):
        raise ValueError("A JSON object is required")
    if app.project == "file-pipeline":
        if path == "/api/files" and method == "POST":
            name = identifier(body.get("id", str(uuid.uuid4())))
            content = body.get("content")
            if not isinstance(content, str) or len(content.encode("utf-8")) > 4096:
                raise ValueError("File content must be a string of at most 4 KiB")
            try:
                app.files.upload(name, content)
            except AssetExists:
                return Response(409, {"error": "immutable_id_already_exists"})
            return Response(202, {"id": name})
        if path == "/api/files/results" and method == "GET":
            return Response(200, {"results": app.files.results()})
        if path == "/api/files/tick" and method == "POST" and hasattr(app.files, "tick"):
            app.files.tick()
            return Response(200, {"results": app.files.results()})
    if app.project == "feature-flags":
        if path == "/api/flags" and method == "POST":
            mode = body.get("mode")
            if mode not in ("on", "off", "broken"):
                raise ValueError("Choose on, off or broken")
            app.flags.write("deliberately-invalid-json" if mode == "broken" else json.dumps({"enabled": mode == "on"}))
            return Response(200, {"mode": mode})
        if path == "/api/offer" and method == "GET":
            try:
                value = app.flags.read()
                flag = {"enabled": False} if value is None else json.loads(value)
                if type(flag["enabled"]) is not bool:
                    raise ValueError()
            except (ValueError, TypeError, KeyError):
                return Response(503, {"error": "invalid_feature_flag"})
            return Response(200, {"variant": "beta" if flag["enabled"] else "stable"})
    if app.project == "network-detective" and path == "/api/network" and method == "GET":
        return Response(200, network_model(query.get("fault", "healthy")))
    if app.project == "sql-inventory":
        if path == "/api/inventory" and method == "GET":
            return Response(200, {"items": app.inventory.items(), "engine": app.inventory.engine})
        if path == "/api/inventory/items" and method == "POST":
            sku = identifier(body.get("sku"))
            stock = body.get("stock")
            if type(stock) is not int or not 0 <= stock <= 100:
                raise ValueError("Stock must be 0-100")
            if not app.inventory.add(sku, stock):
                return Response(409, {"error": "sku_already_exists"})
            return Response(201, {"sku": sku, "stock": stock})
        if path == "/api/inventory/purchase" and method == "POST":
            sku, quantity = identifier(body.get("sku")), body.get("quantity")
            if type(quantity) is not int or not 1 <= quantity <= 100:
                raise ValueError("Quantity must be 1-100")
            result = app.inventory.purchase(sku, quantity)
            return Response(201, result) if result else Response(409, {"error": "insufficient_stock_or_missing_sku"})
        if path == "/api/inventory/orders" and method == "GET":
            return Response(200, {"orders": app.inventory.orders()})
    return Response(404, {"error": "Route is not part of this project."})


def decode_file_event(payload):
    """Accept raw JSON or one base64 envelope with the queue host set to none."""
    if len(payload) > 65536:
        raise ValueError("Event too large")
    try:
        event = json.loads(payload)
    except (ValueError, UnicodeError):
        event = json.loads(base64.b64decode(payload, validate=True))
    if not isinstance(event, dict):
        raise ValueError("Expected one Event Grid event")
    return event
