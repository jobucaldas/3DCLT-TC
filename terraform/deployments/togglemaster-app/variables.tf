variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "environment" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "repo_url" {
  type    = string
  default = "https://github.com/jobucaldas/3DCLT-TC.git"
}

variable "target_revision" {
  type    = string
  default = "t3"
}
