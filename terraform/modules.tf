module "vpc" {
  source = "./modules/vpc"

  project_name         = var.project_name
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  common_tags          = local.common_tags
}

module "cluster" {
  source = "./modules/cluster"

  project_name            = var.project_name
  services                = local.services
  private_subnet_ids      = module.vpc.private_subnet_ids
  cluster_role_arn        = aws_iam_role.eks_cluster.arn
  node_role_arn           = aws_iam_role.eks_node_group.arn
  eks_node_instance_types = var.eks_node_instance_types
  eks_desired_nodes       = var.eks_desired_nodes
  eks_min_nodes           = var.eks_min_nodes
  eks_max_nodes           = var.eks_max_nodes
  common_tags             = local.common_tags

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.ecr_read_only
  ]
}