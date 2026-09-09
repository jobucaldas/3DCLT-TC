variable "aws_region" {
  description = "AWS region where the demo environment will be created."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefix used for AWS resource names."
  type        = string
  default     = "togglemaster"
}
