resource "aws_sqs_queue" "events" {
  name = "${var.project_name}-events"

  tags = local.common_tags
}
