variable "resource_group_name" { type = string }
variable "location" {
  type    = string
  default = "eastus"
}
variable "app_version" {
  type    = string
  default = "v1"
}
variable "broken_startup" {
  type    = bool
  default = false
}
variable "container_image" {
  type    = string
  default = "python:3.11-slim-bookworm"
}
