output "state_bucket_name" {
  description = "S3 bucket used for Terraform remote state"
  value       = aws_s3_bucket.tfstate.bucket
}

output "state_bucket_arn" {
  description = "ARN of the Terraform state bucket"
  value       = aws_s3_bucket.tfstate.arn
}

output "github_oidc_provider_arn" {
  description = "Account-level GitHub OIDC provider ARN"
  value       = aws_iam_openid_connect_provider.github.arn
}

output "aws_account_id" {
  description = "AWS account ID that owns these bootstrap resources"
  value       = data.aws_caller_identity.current.account_id
}
