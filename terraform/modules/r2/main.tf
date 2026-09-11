resource "cloudflare_r2_bucket" "bucket" {
  account_id = var.cloudflare_account_id
  name       = var.bucket_name
  location   = var.location
}
