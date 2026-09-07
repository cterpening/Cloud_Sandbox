mock_provider "azurerm" {}
mock_provider "random" {}
variables {
  resource_group_name = "synthetic-group"
  location            = "eastus"
  client_cidr         = "192.0.2.10/32"
}
run "sandbox_plan" {
  command = plan
  assert {
    condition     = output.project == "file-pipeline"
    error_message = "Wrong project output."
  }
}
