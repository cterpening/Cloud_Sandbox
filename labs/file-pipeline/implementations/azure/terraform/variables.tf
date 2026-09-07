variable "resource_group_name" { type = string }
variable "location" {
  type    = string
  default = "eastus"
}
variable "client_cidr" { type = string }
