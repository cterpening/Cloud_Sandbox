variable "resource_group_name" { type = string }
variable "location" {
  type = string
  validation {
    condition     = contains(["canadaeast", "centralus", "eastus", "eastus2", "northcentralus", "southcentralus", "westcentralus", "westus2", "centralindia", "southindia", "westindia", "japanwest", "koreacentral", "koreasouth", "eastasia", "germanynorth", "germanywestcentral"], var.location)
    error_message = "Choose a documented Pluralsight region (reviewed 2026-09-07)."
  }
}
variable "client_cidr" {
  type = string
  validation {
    condition     = can(cidrnetmask(var.client_cidr)) && endswith(var.client_cidr, "/32") && try(cidrhost(var.client_cidr, 0) != "0.0.0.0", false)
    error_message = "Only a single workstation IPv4 /32 is allowed."
  }
}
