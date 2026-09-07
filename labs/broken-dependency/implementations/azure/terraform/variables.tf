variable "resource_group_name" {
  type        = string
  description = "Use the existing group supplied by Pluralsight."
}
variable "location" {
  type    = string
  default = "eastus"
}
variable "client_cidr" {
  type        = string
  description = "Your public IPv4 address followed by /32. Supply it locally."
}
variable "dependency_table" {
  type    = string
  default = "missingitems"
}
