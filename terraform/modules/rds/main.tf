resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-${var.environment}-rds-subnets"
  subnet_ids = var.private_subnet_ids

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-rds-subnets"
  })
}

resource "aws_db_instance" "postgres" {
  #checkov:skip=CKV_AWS_157:Demo environment; Multi-AZ is intentionally omitted to control cost.
  #checkov:skip=CKV_AWS_293:Demo environment; deletion protection would block routine teardown.
  #checkov:skip=CKV2_AWS_69:Demo clients are not configured to require PostgreSQL TLS.
  for_each = var.databases

  identifier              = each.value.identifier
  engine                  = "postgres"
  engine_version          = "16"
  instance_class          = var.rds_instance_class
  allocated_storage       = var.rds_allocated_storage_gb
  db_name                 = each.value.db_name
  username                = var.db_username
  password                = var.db_password
  db_subnet_group_name    = aws_db_subnet_group.main.name
  vpc_security_group_ids  = [var.data_security_group_id]
  publicly_accessible     = false
  multi_az                = false
  storage_encrypted       = true
  backup_retention_period = 7
  deletion_protection     = false

  performance_insights_kms_key_id = var.kms_key_arn
  parameter_group_name            = aws_db_parameter_group.postgres.name

  enabled_cloudwatch_logs_exports     = ["postgresql", "upgrade"]
  iam_database_authentication_enabled = true
  performance_insights_enabled        = true
  auto_minor_version_upgrade          = true
  copy_tags_to_snapshot               = true

  skip_final_snapshot       = false
  final_snapshot_identifier = "${each.value.identifier}-final"

  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.monitoring.arn

  tags = merge(local.common_tags, {
    Name = each.value.identifier
  })
}

resource "aws_db_parameter_group" "postgres" {
  name   = "${var.project_name}-${var.environment}-postgres16"
  family = "postgres16"

  parameter {
    name         = "log_statement"
    value        = "all"
    apply_method = "pending-reboot"
  }

  tags = local.common_tags
}
