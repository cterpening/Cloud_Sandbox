mock_provider "azurerm" {}
mock_provider "random" {}
variables {
  resource_group_name = "synthetic-group"
  location            = "eastus"
  client_cidr         = "192.0.2.10/32"
}
run "basic_workstation_only_sql" {
  command = plan
  assert {
    condition     = azurerm_mssql_database.workshop.sku_name == "Basic" && azurerm_mssql_server.workshop.minimum_tls_version == "1.2"
    error_message = "Require Basic SQL with TLS."
  }
  assert {
    condition     = azurerm_mssql_firewall_rule.workstation.start_ip_address == "192.0.2.10" && azurerm_mssql_firewall_rule.workstation.end_ip_address == "192.0.2.10"
    error_message = "Only the workstation IP should be allowed."
  }
}
run "reject_broad_network" {
  command = plan
  variables { client_cidr = "0.0.0.0/0" }
  expect_failures = [var.client_cidr]
}
run "reject_azure_services_exception" {
  command = plan
  variables { client_cidr = "0.0.0.0/32" }
  expect_failures = [var.client_cidr]
}
