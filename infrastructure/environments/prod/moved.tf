# Reconcile the half-migrated prod state: resources still at the root must
# move into their modules without destroy/recreate.

# --- API module ---
moved {
  from = aws_apigatewayv2_api.http_api
  to   = module.api.aws_apigatewayv2_api.http_api
}

moved {
  from = aws_apigatewayv2_authorizer.admin_auth
  to   = module.api.aws_apigatewayv2_authorizer.admin_auth
}

moved {
  from = aws_apigatewayv2_integration.lambda_integration
  to   = module.api.aws_apigatewayv2_integration.lambda_integration
}

moved {
  from = aws_apigatewayv2_route.admin_routes
  to   = module.api.aws_apigatewayv2_route.admin_routes
}

moved {
  from = aws_apigatewayv2_route.public_routes
  to   = module.api.aws_apigatewayv2_route.public_routes
}

moved {
  from = aws_apigatewayv2_stage.default
  to   = module.api.aws_apigatewayv2_stage.default
}

moved {
  from = aws_cloudwatch_log_group.api_gw
  to   = module.api.aws_cloudwatch_log_group.api_gw
}

moved {
  from = aws_lambda_permission.api_gw_invoke
  to   = module.api.aws_lambda_permission.api_gw_invoke
}

moved {
  from = aws_lambda_permission.authorizer_invoke
  to   = module.api.aws_lambda_permission.authorizer_invoke
}

# --- Compute module ---
moved {
  from = data.archive_file.lambda_zips
  to   = module.compute.data.archive_file.lambda_zips
}

moved {
  from = aws_lambda_function.api_handlers
  to   = module.compute.aws_lambda_function.api_handlers
}

moved {
  from = aws_iam_role.github_actions_role
  to   = module.compute.aws_iam_role.github_actions_role
}

moved {
  from = aws_iam_role.lambda_roles
  to   = module.compute.aws_iam_role.lambda_roles
}

moved {
  from = aws_iam_role_policy.authorizer_policy
  to   = module.compute.aws_iam_role_policy.authorizer_policy
}

moved {
  from = aws_iam_role_policy.create_event_policy
  to   = module.compute.aws_iam_role_policy.create_event_policy
}

moved {
  from = aws_iam_role_policy.delete_event_policy
  to   = module.compute.aws_iam_role_policy.delete_event_policy
}

moved {
  from = aws_iam_role_policy.delete_registration_policy
  to   = module.compute.aws_iam_role_policy.delete_registration_policy
}

moved {
  from = aws_iam_role_policy.get_events_policy
  to   = module.compute.aws_iam_role_policy.get_events_policy
}

moved {
  from = aws_iam_role_policy.get_registrations_policy
  to   = module.compute.aws_iam_role_policy.get_registrations_policy
}

moved {
  from = aws_iam_role_policy.github_actions_lambda_deploy
  to   = module.compute.aws_iam_role_policy.github_actions_lambda_deploy
}

moved {
  from = aws_iam_role_policy.register_policy
  to   = module.compute.aws_iam_role_policy.register_policy
}

moved {
  from = aws_iam_role_policy.update_event_policy
  to   = module.compute.aws_iam_role_policy.update_event_policy
}

moved {
  from = aws_iam_role_policy_attachment.lambda_basic_execution
  to   = module.compute.aws_iam_role_policy_attachment.lambda_basic_execution
}

moved {
  from = aws_iam_role_policy_attachment.lambda_xray
  to   = module.compute.aws_iam_role_policy_attachment.lambda_xray
}

# --- Frontend module ---
moved {
  from = aws_s3_bucket_policy.allow_cloudfront
  to   = module.frontend.aws_s3_bucket_policy.allow_cloudfront
}

# --- Monitoring address change (resource -> count index) ---
moved {
  from = aws_cloudwatch_metric_alarm.ddb_throttling
  to   = aws_cloudwatch_metric_alarm.ddb_throttling[0]
}
