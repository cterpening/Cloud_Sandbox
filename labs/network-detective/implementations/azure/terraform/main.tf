terraform {
  required_version = ">= 1.9, < 2.0"
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = "4.64.0" }
    random  = { source = "hashicorp/random", version = "3.7.2" }
  }
}
provider "azurerm" {
  features {
    app_configuration {
      purge_soft_delete_on_destroy = false
      recover_soft_deleted         = false
    }
  }
  resource_provider_registrations = "none"
}
module "workshop" {
  source              = "../../../../../modules/network-workshop"
  resource_group_name = var.resource_group_name
  location            = var.location
  ssh_public_key      = var.ssh_public_key
  fault               = var.fault
}
