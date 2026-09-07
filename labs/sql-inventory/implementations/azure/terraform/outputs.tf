output "project" {
  value = module.workshop.project
}
output "resource_name" {
  value = module.workshop.resource_name
}
output "resource_group_name" {
  value = module.workshop.resource_group_name
}
output "sql_host" {
  value = module.workshop.sql_host
}
output "sql_password" {
  value     = module.workshop.sql_password
  sensitive = true
}
