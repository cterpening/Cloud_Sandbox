"""Cloud adapters for the file pipeline and feature-flag experiments."""
from itertools import islice
import json
import os
from azure.core.exceptions import ResourceExistsError, ResourceNotFoundError
from azure.storage.blob import BlobServiceClient
from azure.appconfiguration import AzureAppConfigurationClient, ConfigurationSetting
from experiments import AssetExists, identifier, summarize_file


class AzureFiles:
    def __init__(self):
        self.service = BlobServiceClient.from_connection_string(os.environ["AzureWebJobsStorage"])

    def upload(self, name, content):
        try:
            self.service.get_blob_client("inbox", identifier(name) + ".json").upload_blob(content, overwrite=False)
        except ResourceExistsError as error:
            raise AssetExists() from error

    def process_event(self, event):
        # Never fetch an event-supplied URL. Only read our own inbox and strict IDs.
        prefix = "/blobServices/default/containers/inbox/blobs/"
        subject = event.get("subject", "")
        if event.get("eventType") != "Microsoft.Storage.BlobCreated" or not subject.startswith(prefix) or not subject.endswith(".json"):
            raise ValueError("Unexpected event")
        name = identifier(subject[len(prefix):-5])
        blob = self.service.get_blob_client("inbox", name + ".json")
        if blob.get_blob_properties().size > 4096:
            result = {"disposition": "rejected", "reason": "oversized_document"}
        else:
            result = summarize_file(blob.download_blob().readall())
        result = {"id": name, **result}
        self.service.get_blob_client(result["disposition"], name + ".json").upload_blob(json.dumps(result), overwrite=True)

    def results(self):
        results = []
        for container in ("processed", "rejected"):
            client = self.service.get_container_client(container)
            for blob in islice(client.list_blobs(), 50):
                result = json.loads(client.download_blob(blob.name).readall())
                results.append({k: result[k] for k in ("id", "disposition", "reason", "total_quantity") if k in result})
        return results


class AzureFlags:
    key = "workshop:beta-offer"

    def __init__(self):
        self.client = AzureAppConfigurationClient.from_connection_string(os.environ["APP_CONFIGURATION_CONNECTION"])

    def read(self):
        try:
            return self.client.get_configuration_setting(key=self.key).value
        except ResourceNotFoundError:
            return None

    def write(self, value):
        self.client.set_configuration_setting(ConfigurationSetting(key=self.key, value=value))
