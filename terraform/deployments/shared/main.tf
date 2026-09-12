module "r2" {
  source = "../../modules/r2"

  bucket_name           = var.bucket_name
  cloudflare_account_id = var.cloudflare_account_id
  location              = var.location
}

module "kms_shared" {
  source = "../../modules/kms"

  project_name = var.project_name
  environment  = "shared"
}

module "ecr" {
  source = "../../modules/ecr"

  project_name = var.project_name
  apps         = var.apps
  kms_key_arn  = module.kms_shared.kms_key_arn
}
