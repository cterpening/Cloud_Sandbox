mock_provider "azurerm" {}
mock_provider "random" {}
variables {
  resource_group_name = "synthetic-group"
  location            = "eastus"
  ssh_public_key      = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
}
run "two_small_private_vms" {
  command = plan
  assert {
    condition     = azurerm_nat_gateway.workshop.sku_name == "Standard" && length(azurerm_subnet_nat_gateway_association.workshop) == 2
    error_message = "Both private subnets need explicit diagnostic egress."
  }
  assert {
    condition     = length(azurerm_linux_virtual_machine.workshop) == 2 && alltrue([for vm in azurerm_linux_virtual_machine.workshop : vm.size == "Standard_B1s" && vm.disable_password_authentication])
    error_message = "Require exactly two small SSH-key-only VMs."
  }
  assert {
    condition     = alltrue([for nic in azurerm_network_interface.workshop : nic.ip_configuration[0].public_ip_address_id == null])
    error_message = "Do not expose VMs on public IPs."
  }
}
run "nsg_fault" {
  command = plan
  variables { fault = "nsg" }
  assert {
    condition     = one([for rule in azurerm_network_security_group.server.security_rule : rule.access if rule.name == "client-to-api"]) == "Deny"
    error_message = "NSG fault must actually deny client traffic."
  }
}
run "dns_fault" {
  command = plan
  variables { fault = "dns" }
  assert {
    condition     = azurerm_private_dns_a_record.api.records == toset(["10.42.2.99"])
    error_message = "DNS fault must point to the wrong address."
  }
}
run "reject_bad_fault" {
  command = plan
  variables { fault = "unknown" }
  expect_failures = [var.fault]
}
run "reject_region" {
  command = plan
  variables { location = "unlisted" }
  expect_failures = [var.location]
}
