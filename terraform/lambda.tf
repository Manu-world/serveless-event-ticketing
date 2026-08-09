locals {
  lambdas = {
    "register"            = "register"
    "get_events"          = "get_events"
    "get_registrations"   = "get_registrations"
    "delete_registration" = "delete_registration"
    "create_event"        = "create_event"
    "update_event"        = "update_event"
    "delete_event"        = "delete_event"
    "authorizer"          = "authorizer"
  }
}

# Dynamically zip all Python files. We use a custom build script or assume all go into one zip for now
# Since each function might need shared.py and email_service.py, we package the whole src dir for each
data "archive_file" "lambda_zips" {
  for_each    = local.lambdas
  type        = "zip"
  source_dir  = "${path.module}/../src"
  output_path = "${path.module}/../dist/${each.value}.zip"
  excludes    = ["__pycache__", "*.pyc", "*.pyo"]
}

# Provision the Lambda functions
resource "aws_lambda_function" "api_handlers" {
  for_each         = local.lambdas
  filename         = data.archive_file.lambda_zips[each.key].output_path
  function_name    = "${local.prefix}-${each.key}"
  role             = aws_iam_role.lambda_roles[each.key].arn
  handler          = "${each.value}.lambda_handler"
  source_code_hash = data.archive_file.lambda_zips[each.key].output_base64sha256
  runtime          = "python3.12"
  timeout          = 15
  reserved_concurrent_executions = 10

  tracing_config {
    mode = "Active"
  }

  environment {
    variables = {
      TABLE_NAME             = aws_dynamodb_table.event_ticketing_db.name
      SNS_TOPIC_ARN          = aws_sns_topic.admin_alerts.arn
      EMAIL_PROVIDER         = var.email_provider
      SMTP_HOST              = var.smtp_host
      SMTP_PORT              = var.smtp_port
      SMTP_USER              = var.smtp_user
      SMTP_PASSWORD          = var.smtp_password
      ADMIN_API_KEY_SSM_PARAM = aws_ssm_parameter.admin_api_key.name
    }
  }
  
  tags = local.common_tags
}
