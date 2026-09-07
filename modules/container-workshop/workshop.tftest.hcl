mock_provider "azurerm" {}
mock_provider "random" {}
variables {
  resource_group_name = "synthetic-group"
  location            = "eastus"
}
run "isolated_small_container" {
  command = plan
  assert {
    condition     = azurerm_container_group.workshop.ip_address_type == "None" && azurerm_container_group.workshop.container[0].cpu == 1 && azurerm_container_group.workshop.container[0].memory == 1
    error_message = "Container must be isolated and within its resource budget."
  }
}
run "broken_startup" {
  command = plan
  variables { broken_startup = true }
  assert {
    condition     = azurerm_container_group.workshop.container[0].environment_variables["BROKEN_STARTUP"] == "true"
    error_message = "The fault must reach the actual container."
  }
}
run "reject_version" {
  command = plan
  variables { app_version = "unknown" }
  expect_failures = [var.app_version]
}
run "reject_image" {
  command = plan
  variables { container_image = "untrusted.invalid/arbitrary" }
  expect_failures = [var.container_image]
}
