output "rds_endpoints" {
  value = {
    for name, db in aws_db_instance.postgres : name => db.address
  }
}
