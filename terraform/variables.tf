variable "aws_region" {
  description = "The AWS region to deploy into"
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  default     = "prod"
}

variable "project_name" {
  description = "The base name for project resources"
  default     = "event-ticketing"
}

variable "github_repo" {
  description = "Your GitHub repository (Format: username/repo-name)"
  default     = "Manu-world/serveless-event-ticketing"
}

# Required for GitHub's immutable OIDC subject claims
variable "github_owner_id" {
  description = "Numeric GitHub owner/org ID used in OIDC sub claims"
  default     = "138615921"
}

variable "github_repo_id" {
  description = "Numeric GitHub repository ID used in OIDC sub claims"
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
  default     = "smtp"
}

variable "smtp_host" {
  description = "SMTP Host"
  default     = "smtp.gmail.com"
}

variable "smtp_port" {
  description = "SMTP Port"
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

locals {
  github_owner = split("/", var.github_repo)[0]
  github_name  = split("/", var.github_repo)[1]
  prefix       = "${var.project_name}-${var.environment}"

  # Support both legacy and immutable GitHub Actions OIDC subject formats
  github_oidc_subs = [
    "repo:${var.github_repo}:ref:refs/heads/main",
    "repo:${local.github_owner}@${var.github_owner_id}/${local.github_name}@${var.github_repo_id}:ref:refs/heads/main",
  ]

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = "manu"
  }
}
