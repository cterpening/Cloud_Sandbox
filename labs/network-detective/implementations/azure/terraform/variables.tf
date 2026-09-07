variable "resource_group_name" { type = string }
variable "location" {
  type    = string
  default = "eastus"
}
variable "ssh_public_key" { type = string }
variable "fault" {
  type    = string
  default = "healthy"
}
