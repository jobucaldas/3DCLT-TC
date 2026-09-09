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
