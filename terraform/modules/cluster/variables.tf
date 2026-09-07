variable "project_name" {
  type = string
}

variable "services" {
  type = list(string)
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "cluster_role_arn" {
  type = string
}

variable "node_role_arn" {
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

variable "common_tags" {
  type = map(string)
}