resource "aws_secretsmanager_secret" "redis_url" {
  #checkov:skip=CKV2_AWS_57:Redis endpoint is non-sensitive configuration, not a credential requiring rotation.
  name       = "${var.project_name}/${var.environment}/redis-url"
  kms_key_id = var.kms_key_arn
}

resource "aws_secretsmanager_secret_version" "redis_url" {
  secret_id = aws_secretsmanager_secret.redis_url.id

  secret_string = jsonencode({
    REDIS_URL = "redis://${aws_elasticache_cluster.redis.cache_nodes[0].address}:6379"
  })
}
