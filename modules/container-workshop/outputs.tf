output "project" { value = "container-playground" }
output "resource_name" { value = azurerm_container_group.workshop.name }
output "resource_group_name" { value = data.azurerm_resource_group.sandbox.name }
output "app_version" { value = var.app_version }
output "broken_startup" { value = var.broken_startup }
