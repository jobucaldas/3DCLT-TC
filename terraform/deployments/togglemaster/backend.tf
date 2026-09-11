terraform {
  backend "s3" {
    bucket = "togglemaster-tfstate"
    region = "auto"

    # Encrypt can be off as cloudflare keeps encryption on always
    encrypt                     = false
    use_lockfile                = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
    use_path_style              = true
    endpoints = {
      s3 = "https://073e8b789fdafd36000d32aaba9757b0.r2.cloudflarestorage.com"
    }
  }
}
