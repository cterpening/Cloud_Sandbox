output "function_name" { value = azurerm_linux_function_app.workshop.name }
output "resource_group_name" { value = data.azurerm_resource_group.sandbox.name }
output "base_url" { value = "https://${azurerm_linux_function_app.workshop.default_hostname}" }
output "workspace_name" { value = azurerm_log_analytics_workspace.workshop.name }
output "project" { value = var.project }

# No keys/connection strings are outputs. State still contains secrets and is local/ignored.
