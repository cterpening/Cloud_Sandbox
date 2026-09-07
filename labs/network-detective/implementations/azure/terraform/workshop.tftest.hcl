mock_provider "azurerm" {}
mock_provider "random" {}
variables {
  resource_group_name = "synthetic-group"
  location            = "eastus"
  ssh_public_key      = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
}
run "sandbox_plan" {
  command = plan
  assert {
    condition     = output.project == "network-detective"
    error_message = "Wrong project output."
  }
}
