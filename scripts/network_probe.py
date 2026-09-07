"""Read-only connectivity probe run on the private client VM via Run Command."""
import json
import socket
from urllib.request import ProxyHandler, build_opener

EXPECTED = "10.42.2.4"
NAME = "api.workshop.internal"
opener = build_opener(ProxyHandler({}))  # Test this VNet, never a workstation proxy.


def reachable(host):
    try:
        with opener.open("http://" + host + ":8080", timeout=4) as response:
            return response.status == 200 and json.loads(response.read(1024)) == {"status": "healthy", "synthetic": True}
    except Exception:
        return False


def probe():
    try:
        matches = socket.gethostbyname(NAME) == EXPECTED
    except OSError:
        matches = False
    return {"dns_matches_server": matches, "direct_connection": reachable(EXPECTED),
            "named_connection": reachable(NAME)}


if __name__ == "__main__":
    print("WORKSHOP_PROBE=" + json.dumps(probe(), separators=(",", ":")), flush=True)
