variable "environment" { type = string }
variable "repo_url" {
  type    = string
  default = "https://github.com/jobucaldas/3DCLT-TC.git"
}
variable "target_revision" {
  type    = string
  default = "t3"
}
variable "apps" {
  type = map(string)
  default = {
    auth-service       = "togglemaster-auth"
    flag-service       = "togglemaster-flag"
    targeting-service  = "togglemaster-targeting"
    evaluation-service = "togglemaster-evaluation"
    analytics-service  = "togglemaster-analytics"
  }
}
variable "chart_version" {
  type    = string
  default = "10.9.0"
}
variable "external_secrets_role_arn" {
  type    = string
  default = "arn:aws:iam::762846202773:role/togglemaster-prod-external-secrets-role"
}
variable "keda_operator_role_arn" {
  type    = string
  default = "arn:aws:iam::762846202773:role/togglemaster-prod-keda-operator-role"
}
