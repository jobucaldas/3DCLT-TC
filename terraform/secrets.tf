resource "aws_secretsmanager_secret" "auth_service" {
  name = "${var.project_name}/auth-service"
}

resource "aws_secretsmanager_secret" "analytics_service" {
  name = "${var.project_name}/analytics-service"
}

resource "aws_secretsmanager_secret" "evaluation_service" {
  name = "${var.project_name}/evaluation-service"
}

resource "aws_secretsmanager_secret" "flag_service" {
  name = "${var.project_name}/flag-service"
}

resource "aws_secretsmanager_secret" "targeting_service" {
  name = "${var.project_name}/targeting-service"
}

resource "aws_secretsmanager_secret" "sqs_url" {
  name = "${var.project_name}/sqs-url"
}

resource "aws_secretsmanager_secret_version" "sqs_url" {
  secret_id = aws_secretsmanager_secret.sqs_url.id

  secret_string = jsonencode({
    AWS_SQS_URL = aws_sqs_queue.events.url
  })
}

resource "aws_secretsmanager_secret" "redis_url" {
  name = "${var.project_name}/redis-url"
}

resource "aws_secretsmanager_secret_version" "redis_url" {
  secret_id = aws_secretsmanager_secret.redis_url.id

  secret_string = jsonencode({
    REDIS_URL = "redis://${aws_elasticache_cluster.redis.cache_nodes[0].address}:6379"
  })
}
