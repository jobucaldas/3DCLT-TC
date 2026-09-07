output "eks_cluster_name" {
  value = module.cluster.cluster_name
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}

output "nat_gateway_public_ips" {
  value = module.vpc.nat_gateway_public_ips
}

output "update_kubeconfig_command" {
  value = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.cluster.cluster_name}"
}

output "ecr_repository_urls" {
  value = module.cluster.ecr_repository_urls
}

output "rds_endpoints" {
  value = {
    for name, db in aws_db_instance.postgres : name => db.address
  }
}

output "redis_endpoint" {
  value = aws_elasticache_cluster.redis.cache_nodes[0].address
}

output "sqs_queue_url" {
  value = aws_sqs_queue.events.url
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.analytics.name
}

output "keda_operator_role_arn" {
  value = aws_iam_role.keda_operator.arn
}

output "external_secrets_role_arn" {
  value = aws_iam_role.external_secrets.arn
}

output "app_pods_role_arn" {
  value = aws_iam_role.app_pods.arn
}

output "kubernetes_secret_values" {
  description = "Values to add unto aws secret manager."
  sensitive   = true
  value = {
    auth_database_url      = "postgres://${var.db_username}:${var.db_password}@${aws_db_instance.postgres["auth"].address}:5432/auth_db"
    flag_database_url      = "postgres://${var.db_username}:${var.db_password}@${aws_db_instance.postgres["flag"].address}:5432/flags_db"
    targeting_database_url = "postgres://${var.db_username}:${var.db_password}@${aws_db_instance.postgres["targeting"].address}:5432/targeting_db"
  }
}
