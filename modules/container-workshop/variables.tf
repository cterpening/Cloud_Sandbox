variable "resource_group_name" { type = string }
variable "location" {
  type = string
  validation {
    condition     = contains(["canadaeast", "centralus", "eastus", "eastus2", "northcentralus", "southcentralus", "westcentralus", "westus2", "centralindia", "southindia", "westindia", "japanwest", "koreacentral", "koreasouth", "eastasia", "germanynorth", "germanywestcentral"], var.location)
    error_message = "Choose a documented Pluralsight region (reviewed 2026-09-07)."
  }
}
variable "app_version" {
  type    = string
  default = "v1"
  validation {
    condition     = contains(["v1", "v2"], var.app_version)
    error_message = "Choose v1 or v2."
  }
}
variable "broken_startup" {
  type    = bool
  default = false
}
variable "container_image" {
  type        = string
  default     = "python:3.11-slim-bookworm"
  description = "Public official Python image; pin a reviewed digest for exact reproducibility."
  validation {
    condition     = startswith(var.container_image, "python:3.11-") || startswith(var.container_image, "python@sha256:")
    error_message = "Use a reviewed official Python 3.11 image tag or digest."
  }
}
