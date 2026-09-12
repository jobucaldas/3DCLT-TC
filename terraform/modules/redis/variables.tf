variable "project_name" { type = string }
variable "environment" { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "data_security_group_id" { type = string }
variable "redis_node_type" { type = string }
