# No incoming webhook exception: Event Grid writes a storage queue, which the
# Functions host polls. Storage remains key-authenticated with public endpoints.
resource "azurerm_storage_container" "pipeline" {
  for_each              = local.is_files ? toset(["inbox", "processed", "rejected", "event-deadletters"]) : toset([])
  name                  = each.key
  storage_account_id    = azurerm_storage_account.workshop.id
  container_access_type = "private"
}

resource "azurerm_storage_queue" "file_events" {
  count                = local.is_files ? 1 : 0
  name                 = "file-events"
  storage_account_name = azurerm_storage_account.workshop.name
}

resource "azurerm_eventgrid_system_topic" "files" {
  count                  = local.is_files ? 1 : 0
  name                   = "${local.name}-files"
  resource_group_name    = data.azurerm_resource_group.sandbox.name
  location               = var.location
  source_arm_resource_id = azurerm_storage_account.workshop.id
  topic_type             = "Microsoft.Storage.StorageAccounts"
  tags                   = local.tags
}

resource "azurerm_eventgrid_system_topic_event_subscription" "files" {
  count                 = local.is_files ? 1 : 0
  name                  = "inbox-created"
  system_topic          = azurerm_eventgrid_system_topic.files[0].name
  resource_group_name   = data.azurerm_resource_group.sandbox.name
  included_event_types  = ["Microsoft.Storage.BlobCreated"]
  event_delivery_schema = "EventGridSchema"
  subject_filter {
    subject_begins_with = "/blobServices/default/containers/inbox/blobs/"
    subject_ends_with   = ".json"
  }
  storage_queue_endpoint {
    storage_account_id                    = azurerm_storage_account.workshop.id
    queue_name                            = azurerm_storage_queue.file_events[0].name
    queue_message_time_to_live_in_seconds = 3600
  }
  storage_blob_dead_letter_destination {
    storage_account_id          = azurerm_storage_account.workshop.id
    storage_blob_container_name = azurerm_storage_container.pipeline["event-deadletters"].name
  }
  retry_policy {
    max_delivery_attempts = 5
    event_time_to_live    = 60
  }
}

resource "azurerm_app_configuration" "workshop" {
  count                    = local.is_flags ? 1 : 0
  name                     = "${local.name}-flags"
  resource_group_name      = data.azurerm_resource_group.sandbox.name
  location                 = var.location
  sku                      = "free"
  local_auth_enabled       = true
  purge_protection_enabled = false
  tags                     = local.tags
}
