variable "project_name" {
  type    = string
  default = "togglemaster"
}

variable "bucket_name" {
  description = "R2 bucket for terraform states"
  type        = string
  default     = "togglemaster-tfstate"
}

variable "cloudflare_account_id" {
  description = "Cloudflare account ID for terraform state R2"
  type        = string
  default     = "073e8b789fdafd36000d32aaba9757b0"
}

variable "location" {
  description = "R2 terraform state bucket jurisdiction (WNAM, ENAM, WEUR, EEUR, APAC, OC)"
  type        = string
  default     = "ENAM"
}

variable "environments" {
  description = "Environments where states will be kept"
  type        = set(string)
  default     = ["requirements", "dev", "prod"]
}
