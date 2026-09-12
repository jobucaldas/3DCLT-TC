output "rds_endpoints" {
  value = {
    for name, db in aws_db_instance.postgres : name => db.address
  }
}

output "master_secret_arns" {
  description = "RDS-managed master secrets per database."
  value = {
    for name, db in aws_db_instance.postgres : name => db.master_user_secret[0].secret_arn
  }
}
