mock_provider "azurerm" {}
mock_provider "random" {}
variables {
  resource_group_name = "synthetic-sandbox-group"
  location            = "eastus"
  client_cidr         = "192.0.2.10/32"
  project             = "tiny-notes"
  short_name          = "notes"
}
run "safe_defaults" {
  command = plan
  assert {
    condition     = azurerm_service_plan.workshop.sku_name == "Y1"
    error_message = "The sandbox plan must use an allowed consumption SKU."
  }
  assert {
    condition     = azurerm_linux_function_app.workshop.site_config[0].ip_restriction_default_action == "Deny"
    error_message = "Function access must be restricted by default."
  }
  assert {
    condition     = length(azurerm_servicebus_namespace.workshop) == 0 && length(azurerm_search_service.workshop) == 0
    error_message = "Non-queue/search projects must not provision those services."
  }
}
run "reject_region" {
  command = plan
  variables { location = "unlisted-region" }
  expect_failures = [var.location]
}
run "reject_broad_network" {
  command = plan
  variables { client_cidr = "0.0.0.0/0" }
  expect_failures = [var.client_cidr]
}
run "reject_unknown_dependency" {
  command = plan
  variables { dependency_table = "unapproved-table" }
  expect_failures = [var.dependency_table]
}
run "file_event_pipeline" {
  command = plan
  variables { project = "file-pipeline" }
  assert {
    condition     = length(azurerm_storage_container.pipeline) == 4 && length(azurerm_eventgrid_system_topic_event_subscription.files) == 1 && azurerm_storage_queue.file_events[0].name == "file-events"
    error_message = "File processing needs its private containers and Event Grid queue path."
  }
}
run "free_configuration" {
  command = plan
  variables { project = "feature-flags" }
  assert {
    condition     = azurerm_app_configuration.workshop[0].sku == "free" && !azurerm_app_configuration.workshop[0].purge_protection_enabled
    error_message = "Keep the configuration experiment small and disposable."
  }
}
