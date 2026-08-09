output "api_endpoint" {
  description = "The HTTP API Gateway endpoint URL"
  value       = module.api.api_endpoint
}

output "cloudfront_distribution_id" {
  description = "The CloudFront Distribution ID"
  value       = module.frontend.cloudfront_dist_id
}

output "cloudfront_domain_name" {
  description = "The CloudFront domain name"
  value       = module.frontend.cloudfront_domain_name
}

output "frontend_bucket" {
  description = "The S3 bucket hosting the frontend"
  value       = module.frontend.bucket_id
}

output "github_actions_deploy_role_arn" {
  description = "OIDC role ARN for application deploys"
  value       = module.compute.github_actions_deploy_role_arn
}

output "github_actions_terraform_role_arn" {
  description = "OIDC role ARN for Terraform plan/apply"
  value       = module.compute.github_actions_terraform_role_arn
}

output "github_actions_role_arn" {
  description = "Legacy OIDC deploy role ARN"
  value       = module.compute.github_actions_role_arn
}
