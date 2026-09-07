"""Azure Functions Python v2 entry points; select one experiment per app."""
import json
import logging
import os
import azure.functions as func
from core import Workshop, process_order
from azure_adapters import AzureStore, AzureQueue, AzureSearch

project = os.environ["WORKSHOP_PROJECT"]
app = func.FunctionApp(http_auth_level=func.AuthLevel.FUNCTION)


def workshop():
    return Workshop(project, AzureStore(),
                    AzureQueue() if project == "queue-worker" else None,
                    AzureSearch() if project == "search-playground" else None,
                    os.environ.get("DEPENDENCY_TABLE", "missingitems"))


@app.route(route="ui", methods=["GET"], auth_level=func.AuthLevel.ANONYMOUS)
def ui(req: func.HttpRequest) -> func.HttpResponse:
    # The public page contains no data or secrets. All data API calls need a key.
    result = workshop().handle("GET", "/api/ui")
    return func.HttpResponse(result.encode(), status_code=result.status, headers={"Content-Type": result.content_type})


@app.route(route="{*path}", methods=["GET", "POST"])
def api(req: func.HttpRequest) -> func.HttpResponse:
    result = workshop().handle(req.method, "/api/" + req.route_params.get("path", ""), dict(req.params), req.get_body())
    return func.HttpResponse(result.encode(), status_code=result.status,
                             headers={"Content-Type": result.content_type, "Cache-Control": "no-store"})


if project == "queue-worker":
    @app.service_bus_queue_trigger(arg_name="message", queue_name="orders", connection="SERVICE_BUS_CONNECTION")
    def order_worker(message: func.ServiceBusMessage):
        # A raised exception leaves completion to the Functions host/Service Bus:
        # retry, then dead-letter after the queue's delivery limit.
        order = json.loads(message.get_body())
        result = process_order(order, AzureStore())
        logging.info(json.dumps({"event": "order_worker", "result": result}))
