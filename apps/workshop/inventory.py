"""A real SQLite local store and an explicitly selected TLS Azure SQL adapter."""
from contextlib import contextmanager
import os
from pathlib import Path
import re
import sqlite3
import threading
import uuid


class Inventory:
    engine = "sqlite_memory"
    parameter = "?"
    table_prefix = ""

    def __init__(self):
        self.lock = threading.Lock()
        self.connection = sqlite3.connect(":memory:", check_same_thread=False)
        self.connection.executescript("""
          CREATE TABLE workshop_items (sku TEXT PRIMARY KEY, stock INTEGER NOT NULL CHECK(stock>=0));
          CREATE TABLE workshop_orders (id TEXT PRIMARY KEY, sku TEXT NOT NULL REFERENCES workshop_items(sku), quantity INTEGER NOT NULL CHECK(quantity>0));
        """)

    @contextmanager
    def transaction(self):
        with self.lock:
            try:
                yield self.connection
                self.connection.commit()
            except Exception:
                self.connection.rollback()
                raise

    def close(self):
        with self.lock:
            connection = getattr(self, "connection", None)
            if connection is not None:
                connection.close()
                self.connection = None

    def statement(self, text):
        return text.replace("?", self.parameter).replace("workshop_", self.table_prefix + "workshop_")

    def add(self, sku, stock):
        with self.transaction() as conn:
            cursor = conn.cursor()
            cursor.execute(self.statement("SELECT sku FROM workshop_items WHERE sku=?"), (sku,))
            if cursor.fetchone():
                return False
            cursor.execute(self.statement("INSERT INTO workshop_items(sku, stock) VALUES (?, ?)"), (sku, stock))
            return True

    def purchase(self, sku, quantity):
        with self.transaction() as conn:
            cursor = conn.cursor()
            cursor.execute(self.statement("UPDATE workshop_items SET stock=stock-? WHERE sku=? AND stock>=?"), (quantity, sku, quantity))
            if cursor.rowcount != 1:
                return None
            order_id = str(uuid.uuid4())
            cursor.execute(self.statement("INSERT INTO workshop_orders(id,sku,quantity) VALUES (?,?,?)"), (order_id, sku, quantity))
            cursor.execute(self.statement("SELECT stock FROM workshop_items WHERE sku=?"), (sku,))
            return {"id": order_id, "sku": sku, "quantity": quantity, "remaining": cursor.fetchone()[0]}

    def items(self):
        with self.transaction() as conn:
            cursor = conn.cursor()
            cursor.execute(self.statement("SELECT i.sku,i.stock,COALESCE(SUM(o.quantity),0) FROM workshop_items i LEFT JOIN workshop_orders o ON i.sku=o.sku GROUP BY i.sku,i.stock ORDER BY i.sku"))
            return [{"sku": row[0], "stock": row[1], "sold": row[2]} for row in cursor.fetchmany(100)]

    def orders(self):
        with self.transaction() as conn:
            cursor = conn.cursor()
            cursor.execute(self.statement("SELECT id,sku,quantity FROM workshop_orders ORDER BY id"))
            return [{"id": row[0], "sku": row[1], "quantity": row[2]} for row in cursor.fetchmany(100)]


class AzureSqlInventory(Inventory):
    engine = "azure_sql"
    parameter = "%s"
    table_prefix = "dbo."

    def __init__(self):
        self.lock = threading.Lock()
        host = os.environ.get("WORKSHOP_SQL_HOST", "")
        if not re.fullmatch(r"[a-z0-9-]+\.database\.windows\.net", host):
            raise ValueError("Azure SQL host must be a database.windows.net name")
        self.host = host
        with self.transaction() as conn:
            conn.cursor().execute(Path(__file__).with_name("inventory_schema.sql").read_text(encoding="utf-8"))

    @contextmanager
    def transaction(self):
        import certifi
        import pytds
        # Verify the server certificate and encrypt the full session, not just login.
        with self.lock:
            conn = pytds.connect(server=self.host, database="inventory", user="workshopadmin",
                                 password=os.environ["WORKSHOP_SQL_PASSWORD"], cafile=certifi.where(),
                                 validate_host=True, enc_login_only=False, autocommit=False,
                                 timeout=15, login_timeout=15)
            try:
                yield conn
                conn.commit()
            except Exception:
                conn.rollback()
                raise
            finally:
                conn.close()
