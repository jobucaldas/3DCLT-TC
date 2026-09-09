# checkov:skip=CKV2_AWS_57:Redis endpoint is non-sensitive configuration, not a credential requiring rotation.
resource "aws_secretsmanager_secret" "redis_url" {
  name = "${var.project_name}/redis-url"
}

resource "aws_secretsmanager_secret_version" "redis_url" {
  secret_id = aws_secretsmanager_secret.redis_url.id

  secret_string = jsonencode({
    REDIS_URL = "redis://${aws_elasticache_cluster.redis.cache_nodes[0].address}:6379"
  })
}
