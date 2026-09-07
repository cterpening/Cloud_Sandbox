"""In-memory stand-ins, not emulators of Azure quotas, scaling or delivery."""
from collections import deque
import re
import threading
import uuid
from core import BackendUnavailable, process_order


class MemoryStore:
    def __init__(self):
        self._notes, self._receipts = [], set()
        self._lock = threading.Lock()

    def notes(self):
        with self._lock:
            return list(self._notes[-100:])

    def add_note(self, text):
        note = {"id": str(uuid.uuid4()), "text": text}
        with self._lock:
            self._notes.append(note)
        return note

    def receipt(self, order_id):
        with self._lock:
            if order_id in self._receipts:
                return False
            self._receipts.add(order_id)
            return True

    def receipts(self):
        with self._lock:
            return sorted(self._receipts)[:100]

    def probe(self, table):
        if table != "items":
            raise BackendUnavailable()


class MemoryQueue:
    def __init__(self):
        self.pending, self.failed = deque(), []

    def send(self, order):
        self.pending.append({"order": order, "attempts": 0})

    def tick(self, store):
        if not self.pending:
            return {"status": "empty"}
        message = self.pending.popleft()
        message["attempts"] += 1
        try:
            return {"status": process_order(message["order"], store)}
        except ValueError:
            if message["attempts"] >= 3:
                self.failed.append(message)
                return {"status": "deadlettered"}
            self.pending.append(message)
            return {"status": "retrying", "attempt": message["attempts"]}

    def deadletters(self):
        return list(self.failed[:10])


class MemorySearch:
    engine = "local_token_overlap"

    def __init__(self):
        self.documents = []

    def seed(self, documents):
        self.documents = list(documents)

    def query(self, question):
        tokens = set(re.findall(r"[a-z0-9]+", question.lower()))
        scored = []
        for doc in self.documents:
            words = set(re.findall(r"[a-z0-9]+", (doc["title"] + " " + doc["content"]).lower()))
            score = len(tokens & words)
            if score:
                scored.append((score, doc))
        return [doc for _, doc in sorted(scored, key=lambda pair: (-pair[0], pair[1]["id"]))[:3]]
