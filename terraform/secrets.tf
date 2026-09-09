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
