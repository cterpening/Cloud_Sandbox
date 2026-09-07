output "project" { value = "sql-inventory" }
output "resource_name" { value = azurerm_mssql_server.workshop.name }
output "resource_group_name" { value = data.azurerm_resource_group.sandbox.name }
output "sql_host" { value = azurerm_mssql_server.workshop.fully_qualified_domain_name }
output "sql_password" {
  value     = random_password.sql.result
  sensitive = true
}
