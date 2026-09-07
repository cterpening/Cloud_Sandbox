"""Actual Azure clients. Keys/connection strings stay in runtime settings."""
from itertools import islice
import json
import os
import uuid
from azure.core.credentials import AzureKeyCredential
from azure.core.exceptions import ResourceExistsError, ResourceNotFoundError
from azure.data.tables import TableServiceClient
from azure.servicebus import ServiceBusClient, ServiceBusMessage, ServiceBusSubQueue, TransportType
from azure.search.documents import SearchClient
from azure.search.documents.indexes import SearchIndexClient
from azure.search.documents.indexes.models import SearchIndex, SimpleField, SearchableField
from core import BackendUnavailable


class AzureStore:
    def __init__(self):
        self.service = TableServiceClient.from_connection_string(os.environ["AzureWebJobsStorage"])
        self.table = self.service.get_table_client("items")

    def notes(self):
        return [{"id": row["RowKey"], "text": row["text"]} for row in islice(
            self.table.query_entities("PartitionKey eq 'notes'"), 100)]

    def add_note(self, text):
        note = {"id": str(uuid.uuid4()), "text": text}
        self.table.create_entity({"PartitionKey": "notes", "RowKey": note["id"], "text": text})
        return note

    def receipt(self, order_id):
        try:
            self.table.create_entity({"PartitionKey": "receipts", "RowKey": order_id})
            return True
        except ResourceExistsError:
            return False

    def receipts(self):
        return [row["RowKey"] for row in islice(self.table.query_entities("PartitionKey eq 'receipts'"), 100)]

    def probe(self, table):
        try:
            # Force a request: SDK iterators are lazy.
            next(iter(self.service.get_table_client(table).list_entities(results_per_page=1)), None)
        except ResourceNotFoundError as error:
            raise BackendUnavailable() from error


class AzureQueue:
    def client(self):
        return ServiceBusClient.from_connection_string(os.environ["SERVICE_BUS_CONNECTION"],
                                                       transport_type=TransportType.AmqpOverWebsocket)

    def send(self, order):
        with self.client() as client:
            with client.get_queue_sender("orders") as sender:
                sender.send_messages(ServiceBusMessage(json.dumps(order), message_id=order["id"]))

    def deadletters(self):
        with self.client() as client:
            with client.get_queue_receiver("orders", sub_queue=ServiceBusSubQueue.DEAD_LETTER) as receiver:
                return [{"order": json.loads(str(message)), "attempts": message.delivery_count}
                        for message in receiver.peek_messages(max_message_count=10)]


class AzureSearch:
    engine = "azure_ai_search_keyword"

    def __init__(self):
        self.endpoint = os.environ["SEARCH_ENDPOINT"]
        self.credential = AzureKeyCredential(os.environ["SEARCH_KEY"])
        self.client = SearchClient(self.endpoint, "workshop", self.credential)

    def seed(self, documents):
        index_client = SearchIndexClient(self.endpoint, self.credential)
        index = SearchIndex(name="workshop", fields=[SimpleField(name="id", type="Edm.String", key=True),
                          SearchableField(name="title", type="Edm.String"), SearchableField(name="content", type="Edm.String")])
        try:
            index_client.create_index(index)
        except ResourceExistsError:
            pass
        results = self.client.merge_or_upload_documents(documents)
        if not all(item.succeeded for item in results):
            raise BackendUnavailable()

    def query(self, question):
        return [{key: row[key] for key in ("id", "title", "content")}
                for row in self.client.search(search_text=question, top=3, query_type="simple")]
