variable "project_name" { type = string }
variable "environment" { type = string }
variable "aws_region" { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "sqs_queue_arn" { type = string }
variable "dynamodb_table_arn" { type = string }
variable "app_service_accounts" {
  description = "Kubernetes service accounts allowed to assume the application IAM role."
  type        = set(string)
  default     = []
}
variable "eks_node_instance_types" { type = list(string) }
variable "eks_desired_nodes" { type = number }
variable "eks_min_nodes" { type = number }
variable "eks_max_nodes" { type = number }
