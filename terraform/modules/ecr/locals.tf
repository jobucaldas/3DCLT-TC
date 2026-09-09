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
}
