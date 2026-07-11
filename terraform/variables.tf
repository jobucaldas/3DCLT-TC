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

variable "vpc_cidr" {
  description = "CIDR block for the demo VPC."
  type        = string
  default     = "10.42.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs used by load balancers and NAT gateways."
  type        = list(string)
  default     = ["10.42.1.0/24", "10.42.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDRs used by EKS nodes, RDS and Redis."
  type        = list(string)
  default     = ["10.42.101.0/24", "10.42.102.0/24"]
}

variable "eks_node_instance_types" {
  description = "EC2 instance types used by the EKS managed node group."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "eks_desired_nodes" {
  description = "Desired number of EKS worker nodes."
  type        = number
  default     = 2
}

variable "eks_min_nodes" {
  description = "Minimum number of EKS worker nodes."
  type        = number
  default     = 1
}

variable "eks_max_nodes" {
  description = "Maximum number of EKS worker nodes."
  type        = number
  default     = 3
}

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

variable "redis_node_type" {
  description = "ElastiCache Redis node type."
  type        = string
  default     = "cache.t3.micro"
}
