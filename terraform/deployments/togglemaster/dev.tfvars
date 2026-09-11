aws_region   = "us-east-1"
project_name = "togglemaster"
environment  = "dev"

apps = {
  auth-service = {
    database_name = "auth_dev_db"
  }
  flag-service = {
    database_name = "flags_dev_db"
  }
  targeting-service = {
    database_name = "targeting_dev_db"
  }
  evaluation-service = {}
  analytics-service  = {}
}

app_service_accounts = [
  "system:serviceaccount:togglemaster-evaluation-dev:evaluation-service",
  "system:serviceaccount:togglemaster-analytics-dev:analytics-service",
]

vpc_cidr             = "10.43.0.0/16"
public_subnet_cidrs  = ["10.43.1.0/24", "10.43.2.0/24"]
private_subnet_cidrs = ["10.43.101.0/24", "10.43.102.0/24"]

db_username = "togglemaster-dev"
# Set TF_VAR_db_password outside Git (for example in your CI secret store).
rds_instance_class       = "db.t4g.micro"
rds_allocated_storage_gb = 20
redis_node_type          = "cache.t3.micro"
dynamodb_table_name      = "ToggleMasterAnalyticsDev"

eks_node_instance_types = ["t3.medium"]
eks_desired_nodes       = 2
eks_min_nodes           = 1
eks_max_nodes           = 3
