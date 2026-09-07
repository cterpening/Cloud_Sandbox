"""Run the same user-facing checker against all five real loopback servers."""
from pathlib import Path
import sys
import threading
import unittest

repo = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(repo / "apps/workshop"))
sys.path.insert(0, str(repo / "scripts"))
from local import make_server
from check_project import NoRedirects, check
from core import PROJECTS


class LocalProjectTests(unittest.TestCase):
    def test_all_project_scenarios(self):
        for project in PROJECTS:
            with self.subTest(project=project):
                self.run_project(project)

    def test_repaired_project(self):
        self.run_project("broken-dependency", repaired=True)

    def run_project(self, project, repaired=False):
        server = make_server(project, port=0, dependency_table="items" if repaired else "missingitems")
        thread = threading.Thread(target=server.serve_forever, daemon=True)
        thread.start()
        try:
            result = check(project, f"http://127.0.0.1:{server.server_port}", repaired=repaired)
            self.assertTrue(result["passed"])
            self.assertTrue(result["checks"])
        finally:
            server.shutdown()
            server.server_close()
            thread.join(timeout=3)

    def test_cloud_key_cannot_be_sent_to_arbitrary_host(self):
        with self.assertRaises(ValueError):
            check("tiny-notes", "https://synthetic.invalid", "azure")

    def test_redirects_cannot_forward_a_function_key(self):
        self.assertIsNone(NoRedirects().redirect_request(None, None, 302, "redirect", {}, "https://synthetic.invalid"))


if __name__ == "__main__":
    unittest.main()
