resource "aws_secretsmanager_secret" "sqs_url" {
  #checkov:skip=CKV2_AWS_57:SQS endpoint is non-sensitive configuration, not a credential requiring rotation.
  name       = "${var.project_name}/${var.environment}/sqs-url"
  kms_key_id = var.kms_key_arn
}

resource "aws_secretsmanager_secret_version" "sqs_url" {
  secret_id = aws_secretsmanager_secret.sqs_url.id

  secret_string = jsonencode({
    AWS_SQS_URL = aws_sqs_queue.events.url
  })
}
