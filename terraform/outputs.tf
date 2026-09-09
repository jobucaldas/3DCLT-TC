output "kubernetes_secret_values" {
  description = "Values to add unto aws secret manager."
  sensitive   = true
  value = {
    auth_database_url      = "postgres://${var.db_username}:${var.db_password}@${aws_db_instance.postgres["auth"].address}:5432/auth_db"
    flag_database_url      = "postgres://${var.db_username}:${var.db_password}@${aws_db_instance.postgres["flag"].address}:5432/flags_db"
    targeting_database_url = "postgres://${var.db_username}:${var.db_password}@${aws_db_instance.postgres["targeting"].address}:5432/targeting_db"
  }
}
