output "ecr_repository_urls" {
  value = module.ecr.ecr_repository_urls
}

output "bucket_name" {
  value = module.r2.bucket_name
}

output "r2_endpoint" {
  value = module.r2.r2_endpoint
}

output "backend_configs" {
  description = "Pass to 'init -backend-config', uses same bucket but with a key per environment"
  value = {
    for env in var.environments : env => {
      bucket   = module.r2.bucket_name
      key      = env == "requirements" ? "requirements/terraform.tfstate" : "${var.project_name}/${env}/terraform.tfstate"
      region   = "auto"
      endpoint = module.r2.r2_endpoint
    }
  }
}
