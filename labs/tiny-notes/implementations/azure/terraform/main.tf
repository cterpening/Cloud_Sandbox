terraform {
  required_version = ">= 1.9, < 2.0"
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = "= 4.64.0" }
    random  = { source = "hashicorp/random", version = "= 3.7.2" }
  }
}
provider "azurerm" {
  features {}
  resource_provider_registrations = "none"
}
module "workshop" {
  source              = "../../../../../modules/function-workshop"
  project             = "tiny-notes"
  short_name          = "notes"
  resource_group_name = var.resource_group_name
  location            = var.location
  client_cidr         = var.client_cidr
}
