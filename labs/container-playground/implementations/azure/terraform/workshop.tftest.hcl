mock_provider "azurerm" {}
mock_provider "random" {}
variables {
  resource_group_name = "synthetic-group"
  location            = "eastus"
}
run "sandbox_plan" {
  command = plan
  assert {
    condition     = output.project == "container-playground"
    error_message = "Wrong project output."
  }
}
