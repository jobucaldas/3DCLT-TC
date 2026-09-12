variable "project_name" { type = string }
variable "kms_key_arn" {
  type = string
}
variable "apps" {
  description = "Applications for which ECR repositories are created."
  type        = set(string)
}
