variable "prefix" {
  description = "Name prefix for Lambda and IAM resources"
  type        = string
}

variable "environment" {
  description = "Deployment environment name (dev, prod, ...)"
  type        = string
}

variable "common_tags" {
  description = "Tags applied to compute resources"
  type        = map(string)
}

variable "table_name" {
  description = "DynamoDB table name"
  type        = string
}

variable "table_arn" {
  description = "DynamoDB table ARN"
  type        = string
}

variable "sns_topic_arn" {
  description = "SNS topic ARN for admin alerts"
  type        = string
}

variable "email_provider" {
  description = "Email backend: smtp, ses, or none"
  type        = string
}

variable "smtp_host" {
  description = "SMTP hostname"
  type        = string
}

variable "smtp_port" {
  description = "SMTP port"
  type        = string
}

variable "smtp_user" {
  description = "SMTP username / from-address"
  type        = string
}

variable "admin_api_key_ssm_name" {
  description = "SSM parameter name for the admin API key"
  type        = string
}

variable "smtp_password_ssm_name" {
  description = "SSM parameter name for the SMTP password (not the password itself)"
  type        = string
}

variable "github_oidc_subs" {
  description = "Allowed GitHub OIDC subject claims for CI roles"
  type        = list(string)
}

variable "frontend_bucket_arn" {
  description = "Frontend S3 bucket ARN for deploy-role permissions"
  type        = string
}

variable "cloudfront_distribution_arn" {
  description = "CloudFront distribution ARN for invalidation permissions"
  type        = string
}

variable "state_bucket_arn" {
  description = "Shared Terraform state bucket ARN"
  type        = string
}

variable "log_retention_days" {
  description = "CloudWatch log retention (unused by compute today; reserved for parity)"
  type        = number
  default     = 14
}
