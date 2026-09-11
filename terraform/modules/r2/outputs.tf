output "bucket_name" {
  value = cloudflare_r2_bucket.bucket.name
}

output "r2_endpoint" {
  value = "https://${var.cloudflare_account_id}.r2.cloudflarestorage.com"
}
