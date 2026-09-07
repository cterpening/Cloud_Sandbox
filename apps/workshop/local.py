"""Run a single project on loopback without cloud credentials or packages."""
import argparse
from http.server import BaseHTTPRequestHandler, HTTPServer
import logging
from urllib.parse import parse_qs, urlsplit
from core import PROJECTS, Workshop
from local_adapters import MemoryQueue, MemorySearch, MemoryStore


def make_server(project, port=7071, dependency_table="missingitems", backend="local", container_version="v1"):
    if backend == "azure-sql" and project != "sql-inventory":
        raise ValueError("The azure-sql backend is only for sql-inventory")
    if project == "container-playground":
        from container_app import make_container_server
        return make_container_server(port=port, version=container_version)
    from experiments import MemoryFiles, MemoryFlags
    from inventory import Inventory, AzureSqlInventory
    inventory = (AzureSqlInventory() if backend == "azure-sql" else Inventory()) if project == "sql-inventory" else None
    experiment = Workshop(project, MemoryStore(), MemoryQueue(), MemorySearch(), dependency_table,
                          files=MemoryFiles(), flags=MemoryFlags(), inventory=inventory)

    class Handler(BaseHTTPRequestHandler):
        def do_GET(self):
            self.respond()

        def do_POST(self):
            self.respond()

        def respond(self):
            url = urlsplit(self.path)
            try:
                size = int(self.headers.get("Content-Length", "0"))
            except ValueError:
                self.send_error(400)
                return
            if not 0 <= size <= 8192:
                self.send_error(413)
                return
            self.connection.settimeout(10)
            response = experiment.handle(self.command, url.path,
                                         {k: v[-1] for k, v in parse_qs(url.query).items()}, self.rfile.read(size))
            content = response.encode()
            self.send_response(response.status)
            self.send_header("Content-Type", response.content_type)
            self.send_header("Content-Length", str(len(content)))
            self.send_header("Cache-Control", "no-store")
            self.end_headers()
            self.wfile.write(content)

        def log_message(self, *_):
            pass  # Domain logs deliberately omit query strings and request bodies.

    class WorkshopServer(HTTPServer):
        def server_close(self):
            super().server_close()
            if inventory is not None:
                inventory.close()

    return WorkshopServer(("127.0.0.1", port), Handler)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project", choices=PROJECTS, required=True)
    parser.add_argument("--port", type=int, default=7071)
    parser.add_argument("--dependency-table", choices=("items", "missingitems"), default="missingitems")
    parser.add_argument("--backend", choices=("local", "azure-sql"), default="local")
    parser.add_argument("--container-version", choices=("v1", "v2"), default="v1")
    args = parser.parse_args()
    logging.basicConfig(level=logging.INFO, format="%(message)s")
    try:
        server = make_server(args.project, args.port, args.dependency_table, args.backend, args.container_version)
    except Exception as error:
        print(f"Startup failed ({type(error).__name__}); inspect settings privately. No credentials are printed.", flush=True)
        raise SystemExit(1)
    print(f"{args.project}: http://127.0.0.1:{server.server_port}/api/ui", flush=True)
    print("Azure SQL backend; data persists until cloud cleanup." if args.backend == "azure-sql" else "Local adapters/simulation only; not Azure emulation. Data resets on restart.", flush=True)
    print("Ctrl+C stops the server.", flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()
