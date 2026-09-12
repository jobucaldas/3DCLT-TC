output "app_secret_arns" {
  value = {
    for name, secret in aws_secretsmanager_secret.app : name => secret.arn
  }
}

output "rds_endpoints" {
  value = module.rds.rds_endpoints
}

output "redis_endpoint" {
  value = module.redis.redis_endpoint
}

output "sqs_queue_url" {
  value = module.sqs.sqs_queue_url
}

output "dynamodb_table_name" {
  value = module.dynamodb.dynamodb_table_name
}

output "app_pods_role_arn" {
  value = module.eks.app_pods_role_arn
}

output "kubernetes_secret_values" {
  description = "Database URLs to populate in the corresponding application Secrets Manager secrets."
  sensitive   = true

  value = {
    for name, database in local.databases : "${name}_database_url" => "postgres://${var.db_username}:${var.db_password}@${module.rds.rds_endpoints[name]}:5432/${database.db_name}"
  }
}
