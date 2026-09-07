locals {
  common_tags = {
    Project     = var.project_name
    Environment = "demo"
    ManagedBy   = "terraform"
  }

  services = [
    "auth-service",
    "flag-service",
    "targeting-service",
    "evaluation-service",
    "analytics-service",
  ]

  rds_databases = {
    auth = {
      identifier = "${var.project_name}-auth-db"
      db_name    = "auth_db"
    }
    flag = {
      identifier = "${var.project_name}-flag-db"
      db_name    = "flags_db"
    }
    targeting = {
      identifier = "${var.project_name}-targeting-db"
      db_name    = "targeting_db"
    }
  }
}
