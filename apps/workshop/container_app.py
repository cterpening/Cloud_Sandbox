"""Self-contained workload: local Python, Docker, or an isolated Azure container."""
from http.server import BaseHTTPRequestHandler, HTTPServer
import json
import os
import threading
from urllib.request import urlopen

PAGE = '''<!doctype html><html lang="en"><meta charset="utf-8"><title>Container playground</title>
<h1>Container playground</h1><p>The same small Python application can run locally or inside a container.</p>
<button id="check">Check version and health</button><pre id="result"></pre>
<script>document.querySelector('#check').onclick=async()=>{const r=await fetch('/api/container');
document.querySelector('#result').textContent=JSON.stringify(await r.json(),null,2)}</script></html>'''


def make_container_server(port=7071, host="127.0.0.1", version="v1"):
    if version not in ("v1", "v2"):
        raise ValueError("Choose version v1 or v2")

    class Handler(BaseHTTPRequestHandler):
        def do_GET(self):
            route = self.path.split("?")[0]
            status, content_type = 200, "application/json"
            if route in ("/api/health", "/api/container"):
                content = json.dumps({"project": "container-playground", "status": "healthy", "version": version}).encode()
            elif route in ("/", "/api/ui"):
                content, content_type = PAGE.encode(), "text/html; charset=utf-8"
            else:
                status, content = 404, b'{"error":"unknown_route"}'
            self.send_response(status)
            self.send_header("Content-Type", content_type)
            self.send_header("Content-Length", str(len(content)))
            self.send_header("Cache-Control", "no-store")
            self.end_headers()
            self.wfile.write(content)

        def log_message(self, *_):
            pass

    return HTTPServer((host, port), Handler)


if __name__ == "__main__":
    if os.environ.get("BROKEN_STARTUP", "false").lower() == "true":
        print(json.dumps({"event": "intentional_startup_failure"}), flush=True)
        raise SystemExit(2)
    port = int(os.environ.get("PORT", "8080"))
    version = os.environ.get("APP_VERSION", "v1")
    server = make_container_server(port, "0.0.0.0", version)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    with urlopen(f"http://127.0.0.1:{port}/api/health", timeout=3) as response:
        assert json.load(response)["status"] == "healthy"
    print(json.dumps({"event": "container_started", "project": "container-playground", "version": version, "startup_probe": "passed"}), flush=True)
    try:
        thread.join()
    except KeyboardInterrupt:
        server.shutdown()
    finally:
        server.server_close()
