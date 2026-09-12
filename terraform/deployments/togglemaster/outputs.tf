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

output "rds_master_secret_arns" {
  description = "RDS-managed master user secrets (auto-rotated by AWS)."
  value       = module.rds.master_secret_arns
}
