resource "aws_sns_topic" "admin_alerts" {
  name = "${local.prefix}-admin-alerts"
  tags = local.common_tags
}

resource "aws_sns_topic_subscription" "email_sub" {
  topic_arn = aws_sns_topic.admin_alerts.arn
  protocol  = "email"
  endpoint  = var.notification_email
}