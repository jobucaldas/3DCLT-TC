resource "aws_secretsmanager_secret" "app" {
  #checkov:skip=CKV2_AWS_57:Secret container is populated externally; rotation is managed by the credential owner.
  for_each = var.apps

  kms_key_id = module.kms.kms_key_arn

  name = "${var.project_name}/${each.key}"
  tags = merge(local.common_tags, {
    Application = each.key
  })
}
