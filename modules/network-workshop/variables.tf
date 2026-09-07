variable "resource_group_name" { type = string }
variable "location" {
  type = string
  validation {
    condition     = contains(["canadaeast", "centralus", "eastus", "eastus2", "northcentralus", "southcentralus", "westcentralus", "westus2", "centralindia", "southindia", "westindia", "japanwest", "koreacentral", "koreasouth", "eastasia", "germanynorth", "germanywestcentral"], var.location)
    error_message = "Choose a documented Pluralsight region (reviewed 2026-09-07)."
  }
}
variable "ssh_public_key" {
  type        = string
  description = "Your public SSH key only. There is no exposed SSH endpoint."
  validation {
    condition     = can(regex("^ssh-(ed25519|rsa) ", var.ssh_public_key))
    error_message = "Supply an OpenSSH public key, never a private key."
  }
}
variable "fault" {
  type    = string
  default = "healthy"
  validation {
    condition     = contains(["healthy", "nsg", "dns"], var.fault)
    error_message = "Choose healthy, nsg or dns."
  }
}
