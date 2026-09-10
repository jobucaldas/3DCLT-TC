resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-rds-subnets"
  subnet_ids = var.private_subnet_ids

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-rds-subnets"
  })
}

resource "aws_db_instance" "postgres" {
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
