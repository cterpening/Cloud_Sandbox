data "azurerm_resource_group" "sandbox" { name = var.resource_group_name }
resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

resource "random_password" "sql" {
  length           = 32
  special          = true
  override_special = "_%@!"
  min_upper        = 1
  min_lower        = 1
  min_numeric      = 1
  min_special      = 1
}
locals {
  tags = { project = "sql-inventory", purpose = "disposable-learning", managed_by = "terraform" }
}
resource "azurerm_mssql_server" "workshop" {
  name                          = "ws-sql-${random_string.suffix.result}"
  resource_group_name           = data.azurerm_resource_group.sandbox.name
  location                      = var.location
  version                       = "12.0"
  administrator_login           = "workshopadmin"
  administrator_login_password  = random_password.sql.result
  minimum_tls_version           = "1.2"
  connection_policy             = "Proxy"
  public_network_access_enabled = true
  tags                          = local.tags
}
resource "azurerm_mssql_database" "workshop" {
  name                 = "inventory"
  server_id            = azurerm_mssql_server.workshop.id
  sku_name             = "Basic"
  max_size_gb          = 2
  storage_account_type = "Local"
  tags                 = local.tags
}
resource "azurerm_mssql_firewall_rule" "workstation" {
  name             = "workstation-only"
  server_id        = azurerm_mssql_server.workshop.id
  start_ip_address = cidrhost(var.client_cidr, 0)
  end_ip_address   = cidrhost(var.client_cidr, 0)
}
