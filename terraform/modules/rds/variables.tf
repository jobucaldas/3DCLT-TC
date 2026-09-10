variable "project_name" { type = string }
variable "environment" { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "data_security_group_id" { type = string }
variable "databases" {
  description = "Databases required by applications in this environment."
  type = map(object({
    identifier = string
    db_name    = string
  }))
}
variable "db_username" { type = string }
variable "db_password" {
  type      = string
  sensitive = true
}
variable "rds_instance_class" { type = string }
variable "rds_allocated_storage_gb" { type = number }
