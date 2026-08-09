resource "aws_ssm_parameter" "admin_api_key" {
  name        = "/${var.project_name}/${var.environment}/admin-api-key"
  description = "API Key for Admin Endpoints"
  type        = "SecureString"
  value       = var.admin_api_key
  tags        = local.common_tags
}

resource "aws_ssm_parameter" "smtp_password" {
  name        = "/${var.project_name}/${var.environment}/smtp-password"
  description = "SMTP Password for Email Service"
  type        = "SecureString"
  value       = var.smtp_password
  tags        = local.common_tags
}
