variable "bucket_name" {
  description = "Name of the R2 bucket"
  type        = string
}

variable "cloudflare_account_id" {
  description = "Cloudflare account ID"
  type        = string
}

variable "location" {
  description = "R2 bucket region (WNAM, ENAM, WEUR, EEUR, APAC, OC)"
  type        = string
  default     = "ENAM"
}
