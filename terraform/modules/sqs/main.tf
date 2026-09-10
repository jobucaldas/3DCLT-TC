resource "aws_sqs_queue" "events" {
  name = "${var.project_name}-events"

  kms_master_key_id = var.kms_key_arn

  tags = local.common_tags
}
