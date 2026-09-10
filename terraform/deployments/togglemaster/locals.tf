locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }

  databases = {
    for name, app in var.apps : name => {
      identifier = "${var.project_name}-${name}-db"
      db_name    = app.database_name
    }
    if app.database_name != null
  }
}
