resource "aws_secretsmanager_secret" "app" {
  for_each = var.apps

  name = "${var.project_name}/${each.key}"
  tags = merge(local.common_tags, {
    Application = each.key
  })
}
