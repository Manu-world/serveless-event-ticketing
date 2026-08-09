output "api_endpoint" {
  description = "The base URL for the API Gateway"
  value       = aws_apigatewayv2_api.http_api.api_endpoint
}

output "cloudfront_domain" {
  description = "CloudFront Distribution Domain Name"
  value       = aws_cloudfront_distribution.cdn.domain_name
}

output "s3_bucket_name" {
  description = "Frontend S3 Bucket Name"
  value       = aws_s3_bucket.frontend.id
}

output "dynamodb_table_name" {
  description = "DynamoDB Table Name"
  value       = aws_dynamodb_table.event_ticketing_db.id
}

output "lambda_function_arns" {
  description = "ARNs of all deployed Lambda functions"
  value       = { for k, v in aws_lambda_function.api_handlers : k => v.arn }
}

output "sns_topic_arn" {
  description = "SNS Topic ARN for admin alerts"
  value       = aws_sns_topic.admin_alerts.arn
}

output "github_actions_role_arn" {
  description = "IAM Role ARN for GitHub Actions CI/CD"
  value       = aws_iam_role.github_actions_role.arn
}
