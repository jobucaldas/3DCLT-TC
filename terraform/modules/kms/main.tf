data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "main" {
  #checkov:skip=CKV_AWS_109:Account-root KMS permissions are required by the standard KMS key policy
  #checkov:skip=CKV_AWS_111:Account-root KMS permissions are required by the standard KMS key policy
  #checkov:skip=CKV_AWS_356:KMS key policies require resource "*" because the policy applies to this key
  statement {
    sid    = "EnableAccountRootPermissions"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    actions   = ["kms:*"]
    resources = ["*"]
  }
}

resource "aws_kms_key" "main" {
  description         = "${var.project_name}-${var.environment} encryption key"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.main.json
}

resource "aws_kms_alias" "main" {
  name          = "alias/${var.project_name}-${var.environment}"
  target_key_id = aws_kms_key.main.key_id
}
