module "database" {
  source                      = "../../modules/database"
  prefix                      = local.prefix
  common_tags                 = local.common_tags
  enable_pitr                 = var.enable_pitr
  deletion_protection_enabled = var.dynamodb_deletion_protection
}

module "messaging" {
  source             = "../../modules/messaging"
  prefix             = local.prefix
  common_tags        = local.common_tags
  notification_email = var.notification_email
}

module "frontend" {
  source        = "../../modules/frontend"
  prefix        = local.prefix
  common_tags   = local.common_tags
  force_destroy = var.s3_force_destroy
}

module "compute" {
  source                      = "../../modules/compute"
  prefix                      = local.prefix
  environment                 = var.environment
  common_tags                 = local.common_tags
  table_name                  = module.database.table_name
  table_arn                   = module.database.table_arn
  sns_topic_arn               = module.messaging.topic_arn
  email_provider              = var.email_provider
  smtp_host                   = var.smtp_host
  smtp_port                   = var.smtp_port
  smtp_user                   = var.smtp_user
  admin_api_key_ssm_name      = aws_ssm_parameter.admin_api_key.name
  smtp_password_ssm_name      = aws_ssm_parameter.smtp_password.name
  github_oidc_subs            = local.github_oidc_subs
  frontend_bucket_arn         = module.frontend.bucket_arn
  cloudfront_distribution_arn = module.frontend.cloudfront_distribution_arn
  state_bucket_arn            = var.state_bucket_arn
  log_retention_days          = var.log_retention_days
}

module "api" {
  source                   = "../../modules/api"
  prefix                   = local.prefix
  common_tags              = local.common_tags
  lambda_invoke_arns       = module.compute.lambda_invoke_arns
  lambda_function_names    = module.compute.lambda_function_names
  authorizer_function_name = module.compute.authorizer_function_name
  cloudfront_domain_name   = module.frontend.cloudfront_domain_name
  log_retention_days       = var.log_retention_days
  throttling_burst_limit   = var.throttling_burst_limit
  throttling_rate_limit    = var.throttling_rate_limit
}
