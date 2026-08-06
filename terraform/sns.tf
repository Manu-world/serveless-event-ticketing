resource "aws_sns_topic" "event_confirmations" {
  name = "${var.project_name}-confirmations"
  tags = local.common_tags
}

resource "aws_sns_topic_subscription" "email_sub" {
  topic_arn = aws_sns_topic.event_confirmations.arn
  protocol  = "email"
  endpoint  = "manu.softwareengineer@gmail.com"
}