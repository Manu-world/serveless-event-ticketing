variable "prefix" {
  type = string
}

variable "environment" {
  type = string
}

variable "common_tags" {
  type = map(string)
}

variable "table_name" {
  type = string
}

variable "table_arn" {
  type = string
}

variable "sns_topic_arn" {
  type = string
}

variable "email_provider" {
  type = string
}

variable "smtp_host" {
  type = string
}

variable "smtp_port" {
  type = string
}

variable "smtp_user" {
  type = string
}

variable "admin_api_key_ssm_name" {
  type = string
}

variable "smtp_password_ssm_name" {
  type = string
}

variable "github_oidc_subs" {
  type = list(string)
}

variable "frontend_bucket_arn" {
  type = string
}

variable "cloudfront_distribution_arn" {
  type = string
}

variable "state_bucket_arn" {
  type = string
}

variable "log_retention_days" {
  type    = number
  default = 14
}
