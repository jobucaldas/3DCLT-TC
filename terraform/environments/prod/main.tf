module "vpc" {
  source = "../../modules/vpc"

  project_name         = var.project_name
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

module "sqs" {
  source = "../../modules/sqs"

  project_name = var.project_name
  environment  = var.environment
}

module "dynamodb" {
  source = "../../modules/dynamodb"

  project_name = var.project_name
  environment  = var.environment
  table_name   = var.dynamodb_table_name
}

module "ecr" {
  source = "../../modules/ecr"

  project_name = var.project_name
  environment  = var.environment
  apps         = toset(keys(var.apps))
}

module "eks" {
  source = "../../modules/eks"

  project_name            = var.project_name
  environment             = var.environment
  aws_region              = var.aws_region
  private_subnet_ids      = module.vpc.private_subnet_ids
  sqs_queue_arn           = module.sqs.queue_arn
  dynamodb_table_arn      = module.dynamodb.table_arn
  eks_node_instance_types = var.eks_node_instance_types
  eks_desired_nodes       = var.eks_desired_nodes
  eks_min_nodes           = var.eks_min_nodes
  eks_max_nodes           = var.eks_max_nodes
  app_service_accounts    = var.app_service_accounts
}

module "rds" {
  source = "../../modules/rds"

  project_name             = var.project_name
  environment              = var.environment
  private_subnet_ids       = module.vpc.private_subnet_ids
  data_security_group_id   = module.vpc.data_security_group_id
  databases                = local.databases
  db_username              = var.db_username
  db_password              = var.db_password
  rds_instance_class       = var.rds_instance_class
  rds_allocated_storage_gb = var.rds_allocated_storage_gb
}

module "redis" {
  source = "../../modules/redis"

  project_name           = var.project_name
  environment            = var.environment
  private_subnet_ids     = module.vpc.private_subnet_ids
  data_security_group_id = module.vpc.data_security_group_id
  redis_node_type        = var.redis_node_type
}
