locals {
  name = "${var.project_name}-${var.environment}-self-healing"

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/lambda/handler.py"
  output_path = "${path.module}/lambda/handler.zip"
}

resource "random_password" "token" {
  length  = 48
  special = false
}

resource "aws_iam_role" "lambda" {
  name = local.name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "logs" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${local.name}"
  retention_in_days = 7

  tags = local.common_tags
}

resource "aws_lambda_function" "restart" {
  function_name = local.name
  role          = aws_iam_role.lambda.arn
  runtime       = "python3.12"
  handler       = "handler.handler"
  memory_size   = 128
  timeout       = 30

  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256

  environment {
    variables = {
      CLUSTER_NAME     = var.cluster_name
      CLUSTER_ENDPOINT = var.cluster_endpoint
      CLUSTER_CA       = var.cluster_ca
      WEBHOOK_TOKEN    = random_password.token.result
    }
  }

  tags = local.common_tags

  depends_on = [
    aws_cloudwatch_log_group.lambda,
    aws_iam_role_policy_attachment.logs,
  ]
}

resource "aws_lambda_function_url" "restart" {
  function_name      = aws_lambda_function.restart.function_name
  authorization_type = "NONE"
}

resource "aws_eks_access_entry" "lambda" {
  cluster_name      = var.cluster_name
  principal_arn     = aws_iam_role.lambda.arn
  kubernetes_groups = ["self-healing"]
  type              = "STANDARD"

  tags = local.common_tags
}

resource "aws_secretsmanager_secret" "webhook" {
  name                    = "${var.project_name}/${var.environment}/self-healing"
  recovery_window_in_days = 0

  tags = local.common_tags
}

resource "aws_secretsmanager_secret_version" "webhook" {
  secret_id = aws_secretsmanager_secret.webhook.id
  secret_string = jsonencode({
    url   = aws_lambda_function_url.restart.function_url
    token = random_password.token.result
  })
}
