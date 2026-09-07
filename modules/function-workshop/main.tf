data "azurerm_resource_group" "sandbox" {
  name = var.resource_group_name
}

resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

locals {
  name      = "ws-${var.short_name}-${random_string.suffix.result}"
  is_queue  = var.project == "queue-worker"
  is_search = var.project == "search-playground"
  is_files  = var.project == "file-pipeline"
  is_flags  = var.project == "feature-flags"
  tags = {
    project    = var.project
    purpose    = "disposable-learning"
    managed_by = "terraform"
  }
}

resource "azurerm_storage_account" "workshop" {
  name                            = "ws${var.short_name}${random_string.suffix.result}"
  resource_group_name             = data.azurerm_resource_group.sandbox.name
  location                        = var.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = true
  tags                            = local.tags
}

resource "azurerm_storage_table" "items" {
  name                 = "items"
  storage_account_name = azurerm_storage_account.workshop.name
}

resource "azurerm_service_plan" "workshop" {
  name                = local.name
  resource_group_name = data.azurerm_resource_group.sandbox.name
  location            = var.location
  os_type             = "Linux"
  sku_name            = "Y1"
  tags                = local.tags
}

resource "azurerm_log_analytics_workspace" "workshop" {
  name                = local.name
  resource_group_name = data.azurerm_resource_group.sandbox.name
  location            = var.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
  daily_quota_gb      = 0.1
  tags                = local.tags
}

resource "azurerm_application_insights" "workshop" {
  name                = local.name
  resource_group_name = data.azurerm_resource_group.sandbox.name
  location            = var.location
  workspace_id        = azurerm_log_analytics_workspace.workshop.id
  application_type    = "web"
  tags                = local.tags
}

resource "azurerm_servicebus_namespace" "workshop" {
  count               = local.is_queue ? 1 : 0
  name                = local.name
  resource_group_name = data.azurerm_resource_group.sandbox.name
  location            = var.location
  sku                 = "Basic"
  minimum_tls_version = "1.2"
  tags                = local.tags
}

resource "azurerm_servicebus_queue" "orders" {
  count               = local.is_queue ? 1 : 0
  name                = "orders"
  namespace_id        = azurerm_servicebus_namespace.workshop[0].id
  max_delivery_count  = 3
  default_message_ttl = "PT1H"
  lock_duration       = "PT30S"
}

resource "azurerm_servicebus_queue_authorization_rule" "workshop" {
  count    = local.is_queue ? 1 : 0
  name     = "workshop-send-receive"
  queue_id = azurerm_servicebus_queue.orders[0].id
  listen   = true
  send     = true
  manage   = false
}

resource "azurerm_search_service" "workshop" {
  count                        = local.is_search ? 1 : 0
  name                         = local.name
  resource_group_name          = data.azurerm_resource_group.sandbox.name
  location                     = var.location
  sku                          = "free"
  replica_count                = 1
  partition_count              = 1
  local_authentication_enabled = true
  tags                         = local.tags
}

resource "azurerm_linux_function_app" "workshop" {
  name                                           = local.name
  resource_group_name                            = data.azurerm_resource_group.sandbox.name
  location                                       = var.location
  service_plan_id                                = azurerm_service_plan.workshop.id
  storage_account_name                           = azurerm_storage_account.workshop.name
  storage_account_access_key                     = azurerm_storage_account.workshop.primary_access_key
  https_only                                     = true
  functions_extension_version                    = "~4"
  builtin_logging_enabled                        = false
  ftp_publish_basic_authentication_enabled       = false
  webdeploy_publish_basic_authentication_enabled = false
  site_config {
    application_stack { python_version = "3.11" }
    application_insights_connection_string = azurerm_application_insights.workshop.connection_string
    application_insights_key               = azurerm_application_insights.workshop.instrumentation_key
    ftps_state                             = "Disabled"
    minimum_tls_version                    = "1.2"
    scm_minimum_tls_version                = "1.2"
    ip_restriction_default_action          = "Deny"
    scm_use_main_ip_restriction            = true
    ip_restriction {
      name       = "workshop-client"
      priority   = 100
      action     = "Allow"
      ip_address = var.client_cidr
    }
  }
  app_settings = merge({
    WORKSHOP_PROJECT                          = var.project
    DEPENDENCY_TABLE                          = var.dependency_table
    SCM_DO_BUILD_DURING_DEPLOYMENT            = "true"
    ENABLE_ORYX_BUILD                         = "true"
    WEBSITE_MAX_DYNAMIC_APPLICATION_SCALE_OUT = "1"
    }, local.is_queue ? {
    SERVICE_BUS_CONNECTION = azurerm_servicebus_queue_authorization_rule.workshop[0].primary_connection_string
    } : {}, local.is_search ? {
    SEARCH_ENDPOINT = "https://${azurerm_search_service.workshop[0].name}.search.windows.net"
    SEARCH_KEY      = azurerm_search_service.workshop[0].primary_key
    } : {}, local.is_flags ? {
    APP_CONFIGURATION_CONNECTION = azurerm_app_configuration.workshop[0].primary_write_key[0].connection_string
  } : {})
  tags       = local.tags
  depends_on = [azurerm_storage_table.items]
}

resource "azurerm_monitor_metric_alert" "errors" {
  name                = "${local.name}-http-errors"
  resource_group_name = data.azurerm_resource_group.sandbox.name
  scopes              = [azurerm_linux_function_app.workshop.id]
  description         = "Synthetic workshop HTTP errors; no external notification configured."
  severity            = 3
  frequency           = "PT1M"
  window_size         = "PT5M"
  criteria {
    metric_namespace = "Microsoft.Web/sites"
    metric_name      = "Http5xx"
    aggregation      = "Total"
    operator         = "GreaterThanOrEqual"
    threshold        = 1
  }
  tags = local.tags
}
