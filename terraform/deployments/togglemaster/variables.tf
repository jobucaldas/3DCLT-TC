variable "aws_region" {
  description = "AWS region for this environment."
  type        = string
}

variable "project_name" {
  description = "Prefix used for AWS resource names."
  type        = string
}

variable "environment" {
  description = "Environment name used in resource tags."
  type        = string
}

variable "apps" {
  description = "Applications deployed in this environment and their optional PostgreSQL database."
  type = map(object({
    database_name = optional(string)
  }))
}

variable "app_service_accounts" {
  description = "Kubernetes service accounts allowed to assume the shared application IAM role."
  type        = set(string)
  default     = []
}

variable "vpc_cidr" {
  type = string
}

variable "public_subnet_cidrs" {
  type = list(string)
}

variable "private_subnet_cidrs" {
  type = list(string)
}

variable "db_username" {
  type = string
}

variable "db_password" {
  type      = string
  sensitive = true

  validation {
    condition     = length(var.db_password) >= 8
    error_message = "db_password must have at least 8 characters."
  }
}

variable "rds_instance_class" {
  type = string
}

variable "rds_allocated_storage_gb" {
  type = number
}

variable "redis_node_type" {
  type = string
}

variable "dynamodb_table_name" {
  type = string
}

variable "eks_node_instance_types" {
  type = list(string)
}

variable "eks_desired_nodes" {
  type = number
}

variable "eks_min_nodes" {
  type = number
}

variable "eks_max_nodes" {
  type = number
}
