resource "aws_ecr_repository" "service" {
  for_each = toset(var.services)

  name         = each.value
  force_delete = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = var.common_tags
}
