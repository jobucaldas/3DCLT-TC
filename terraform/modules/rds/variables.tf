variable "db_username" {
  description = "PostgreSQL username for the three RDS instances."
  type        = string
  default     = "togglemaster"
}

variable "db_password" {
  description = "PostgreSQL password for the three RDS instances."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.db_password) >= 8
    error_message = "db_password must have at least 8 characters for Amazon RDS."
  }
}

variable "rds_instance_class" {
  description = "RDS instance class for the demo databases."
  type        = string
  default     = "db.t4g.micro"
}

variable "rds_allocated_storage_gb" {
  description = "Allocated storage per RDS instance."
  type        = number
  default     = 20
}
