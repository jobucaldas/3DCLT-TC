module "r2" {
  source = "../../modules/r2"

  bucket_name           = var.bucket_name
  cloudflare_account_id = var.cloudflare_account_id
  location              = var.location
}
