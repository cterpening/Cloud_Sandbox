"""Run a single project on loopback without cloud credentials or packages."""
import argparse
from http.server import BaseHTTPRequestHandler, HTTPServer
import logging
from urllib.parse import parse_qs, urlsplit
from core import PROJECTS, Workshop
from local_adapters import MemoryQueue, MemorySearch, MemoryStore


def make_server(project, port=7071, dependency_table="missingitems"):
    experiment = Workshop(project, MemoryStore(), MemoryQueue(), MemorySearch(), dependency_table)

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

    return HTTPServer(("127.0.0.1", port), Handler)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project", choices=PROJECTS, required=True)
    parser.add_argument("--port", type=int, default=7071)
    parser.add_argument("--dependency-table", choices=("items", "missingitems"), default="missingitems")
    args = parser.parse_args()
    logging.basicConfig(level=logging.INFO, format="%(message)s")
    server = make_server(args.project, args.port, args.dependency_table)
    print(f"{args.project}: http://127.0.0.1:{server.server_port}/api/ui", flush=True)
    print("Local stand-ins only. Data resets on restart. Ctrl+C stops the server.", flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()
