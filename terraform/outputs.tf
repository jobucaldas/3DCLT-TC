output "eks_cluster_name" {
  value = aws_eks_cluster.main.name
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "nat_gateway_public_ips" {
  value = aws_eip.nat[*].public_ip
}

output "update_kubeconfig_command" {
  value = "aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.main.name}"
}

output "ecr_repository_urls" {
  value = {
    for name, repo in aws_ecr_repository.service : name => repo.repository_url
  }
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

output "kubernetes_secret_values" {
  description = "Values to add unto aws secret manager."
  sensitive   = true
  value = {
    auth_database_url      = "postgres://${var.db_username}:${var.db_password}@${aws_db_instance.postgres["auth"].address}:5432/auth_db"
    flag_database_url      = "postgres://${var.db_username}:${var.db_password}@${aws_db_instance.postgres["flag"].address}:5432/flags_db"
    targeting_database_url = "postgres://${var.db_username}:${var.db_password}@${aws_db_instance.postgres["targeting"].address}:5432/targeting_db"
  }
}
