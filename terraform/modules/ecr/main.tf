resource "aws_ecr_repository" "service" {
  for_each = var.apps

  name         = each.value
  force_delete = true

  image_scanning_configuration {
    scan_on_push = true
  }

  image_tag_mutability = "IMMUTABLE"

  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = var.kms_key_arn
  }

  tags = local.common_tags
}
