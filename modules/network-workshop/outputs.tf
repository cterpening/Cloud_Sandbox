output "project" { value = "network-detective" }
output "resource_name" { value = azurerm_linux_virtual_machine.workshop["server"].name }
output "resource_group_name" { value = data.azurerm_resource_group.sandbox.name }
output "client_vm_name" { value = azurerm_linux_virtual_machine.workshop["client"].name }
output "server_private_ip" { value = "10.42.2.4" }
output "fault" { value = var.fault }
