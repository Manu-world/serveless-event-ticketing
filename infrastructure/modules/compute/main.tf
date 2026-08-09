locals {
  lambdas = {
    "register"            = "services.registrations.handlers.create"
    "get_events"          = "services.events.handlers.get"
    "get_registrations"   = "services.registrations.handlers.get"
    "delete_registration" = "services.registrations.handlers.delete"
    "create_event"        = "services.events.handlers.create"
    "update_event"        = "services.events.handlers.update"
    "delete_event"        = "services.events.handlers.delete"
    "authorizer"          = "services.auth.authorizer"
  }
}

data "archive_file" "lambda_zips" {
  for_each    = local.lambdas
  type        = "zip"
  source_dir  = "${path.module}/../../../backend"
  output_path = "${path.module}/../../../dist/${each.key}.zip"
  excludes    = ["__pycache__", "*.pyc", "*.pyo"]
}

resource "aws_lambda_function" "api_handlers" {
  for_each         = local.lambdas
  filename         = data.archive_file.lambda_zips[each.key].output_path
  function_name    = "${var.prefix}-${each.key}"
  role             = aws_iam_role.lambda_roles[each.key].arn
  handler          = "${each.value}.lambda_handler"
  source_code_hash = data.archive_file.lambda_zips[each.key].output_base64sha256
  runtime          = "python3.12"
  timeout          = 15

  tracing_config {
    mode = "Active"
  }

  environment {
    variables = {
      TABLE_NAME              = var.table_name
      SNS_TOPIC_ARN           = var.sns_topic_arn
      EMAIL_PROVIDER          = var.email_provider
      SMTP_HOST               = var.smtp_host
      SMTP_PORT               = var.smtp_port
      SMTP_USER               = var.smtp_user
      SMTP_PASSWORD_SSM_PARAM = var.smtp_password_ssm_name
      ADMIN_API_KEY_SSM_PARAM = var.admin_api_key_ssm_name
    }
  }

  tags = var.common_tags

  # Terraform seeds the function with the repo zip on create, but application
  # code is owned by the deploy pipeline from then on. Without this, every
  # apply would revert the deployed artifact and show permanent drift.
  lifecycle {
    ignore_changes = [filename, source_code_hash]
  }
}
