output "lambda_invoke_arns" {
  value = { for k, v in aws_lambda_function.api_handlers : k => v.invoke_arn }
}

output "authorizer_invoke_arn" {
  value = aws_lambda_function.api_handlers["authorizer"].invoke_arn
}

output "lambda_function_names" {
  value = { for k, v in aws_lambda_function.api_handlers : k => v.function_name }
}

output "authorizer_function_name" {
  value = aws_lambda_function.api_handlers["authorizer"].function_name
}

output "github_actions_role_arn" {
  description = "Legacy deploy role ARN (kept for secret migration)"
  value       = aws_iam_role.github_actions_role.arn
}

output "github_actions_deploy_role_arn" {
  value = aws_iam_role.github_actions_deploy_role.arn
}

output "github_actions_terraform_role_arn" {
  value = aws_iam_role.github_actions_terraform_role.arn
}
