variable "aws_region" {
  description = "The AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "The base name for project resources"
  type        = string
  default     = "event-ticketing"
}

variable "github_repo" {
  description = "Your GitHub repository (Format: username/repo-name)"
  type        = string
  default     = "Manu-world/serveless-event-ticketing"
}

variable "github_owner_id" {
  description = "Numeric GitHub owner/org ID used in OIDC sub claims"
  type        = string
  default     = "138615921"
}

variable "github_repo_id" {
  description = "Numeric GitHub repository ID used in OIDC sub claims"
  type        = string
  default     = "1325358812"
}

variable "admin_api_key" {
  description = "Secret API key for accessing admin endpoints"
  type        = string
  sensitive   = true
}

variable "notification_email" {
  description = "Email address for admin alerts and budgets"
  type        = string
}

variable "email_provider" {
  description = "Email provider to use (smtp, ses, none)"
  type        = string
  default     = "none"
}

variable "smtp_host" {
  description = "SMTP Host"
  type        = string
  default     = "smtp.gmail.com"
}

variable "smtp_port" {
  description = "SMTP Port"
  type        = string
  default     = "587"
}

variable "smtp_user" {
  description = "SMTP Username"
  type        = string
}

variable "smtp_password" {
  description = "SMTP Password"
  type        = string
  sensitive   = true
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}

variable "enable_pitr" {
  description = "Enable DynamoDB point-in-time recovery"
  type        = bool
  default     = false
}

variable "enable_detailed_alarms" {
  description = "Enable duration and other detailed CloudWatch alarms"
  type        = bool
  default     = false
}

variable "budget_limit_usd" {
  description = "Monthly AWS budget limit in USD"
  type        = string
  default     = "1.00"
}

variable "s3_force_destroy" {
  description = "Allow Terraform to destroy non-empty frontend buckets"
  type        = bool
  default     = true
}

variable "dynamodb_deletion_protection" {
  description = "Enable DynamoDB deletion protection"
  type        = bool
  default     = false
}

variable "state_bucket_arn" {
  description = "ARN of the shared Terraform state bucket"
  type        = string
  default     = "arn:aws:s3:::event-ticketing-tfstate-272558305025"
}

variable "throttling_burst_limit" {
  type    = number
  default = 50
}

variable "throttling_rate_limit" {
  type    = number
  default = 25
}

locals {
  github_owner = split("/", var.github_repo)[0]
  github_name  = split("/", var.github_repo)[1]
  prefix       = "${var.project_name}-${var.environment}"

  # Jobs that declare `environment:` get an `environment:` subject rather than a
  # `ref:` one, so both forms are trusted to cover workflows of either shape.
  github_oidc_subs = [
    "repo:${var.github_repo}:environment:dev",
    "repo:${var.github_repo}:ref:refs/heads/dev",
    "repo:${local.github_owner}@${var.github_owner_id}/${local.github_name}@${var.github_repo_id}:environment:dev",
    "repo:${local.github_owner}@${var.github_owner_id}/${local.github_name}@${var.github_repo_id}:ref:refs/heads/dev",
  ]

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = "manu"
  }
}
