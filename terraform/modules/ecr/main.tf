resource "aws_ecr_repository" "service" {
  for_each = var.apps

  name         = each.value
  force_delete = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = local.common_tags
}
