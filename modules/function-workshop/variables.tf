variable "resource_group_name" {
  type        = string
  description = "Existing resource group assigned by the sandbox. Never created or owned by this module."
}

variable "location" {
  type        = string
  description = "Documented sandbox region; preflight must separately check service availability."
  validation {
    condition = contains([
      "canadaeast", "centralus", "eastus", "eastus2", "northcentralus", "southcentralus",
      "westcentralus", "westus2", "centralindia", "southindia", "westindia", "japanwest",
      "koreacentral", "koreasouth", "eastasia", "germanynorth", "germanywestcentral"
    ], var.location)
    error_message = "Select a region from the Pluralsight Azure allowlist reviewed 2026-09-06."
  }
}

variable "project" {
  type = string
  validation {
    condition = contains([
      "observable-serverless-api", "tiny-notes", "queue-worker", "broken-dependency", "search-playground"
    ], var.project)
    error_message = "Unknown workshop project."
  }
}

variable "short_name" {
  type = string
  validation {
    condition     = can(regex("^[a-z]{2,8}$", var.short_name))
    error_message = "Use 2-8 lowercase letters for the short name."
  }
}

variable "dependency_table" {
  type        = string
  default     = "missingitems"
  description = "Broken-dependency exercise: change missingitems to items to repair checkout."
  validation {
    condition     = contains(["missingitems", "items"], var.dependency_table)
    error_message = "Use missingitems (broken) or items (repaired)."
  }
}

variable "client_cidr" {
  type        = string
  description = "Your public IPv4 address as a /32. HTTP API access is restricted to this address."
  validation {
    condition     = can(cidrnetmask(var.client_cidr)) && endswith(var.client_cidr, "/32")
    error_message = "Supply a single public IPv4 address with /32; broad public access is not the default."
  }
}
