# checkov:skip=CKV2_AWS_57:SQS endpoint is non-sensitive configuration, not a credential requiring rotation.
resource "aws_secretsmanager_secret" "sqs_url" {
  name = "${var.project_name}/sqs-url"
}

resource "aws_secretsmanager_secret_version" "sqs_url" {
  secret_id = aws_secretsmanager_secret.sqs_url.id

  secret_string = jsonencode({
    AWS_SQS_URL = aws_sqs_queue.events.url
  })
}
