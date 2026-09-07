mock_provider "azurerm" {}
mock_provider "random" {
  mock_resource "random_string" { defaults = { result = "abc123" } }
}
variables {
  resource_group_name = "synthetic-sandbox-group"
  location            = "eastus"
  client_cidr         = "192.0.2.10/32"
}
run "sandbox_plan" {
  command = plan
  assert {
    condition     = module.workshop.project == "queue-worker"
    error_message = "Wrong project selected."
  }
}
