locals {
  lambdas = {
    "register"            = "register"
    "get_events"          = "get_events"
    "get_registrations"   = "get_registrations"
    "delete_registration" = "delete_registration"
  }
}

# Dynamically zip all Python files
data "archive_file" "lambda_zips" {
  for_each    = local.lambdas
  type        = "zip"
  source_file = "${path.module}/../src/${each.value}.py"
  output_path = "${path.module}/../dist/${each.value}.zip"
}

# Provision the Lambda functions
resource "aws_lambda_function" "api_handlers" {
  for_each         = local.lambdas
  filename         = data.archive_file.lambda_zips[each.key].output_path
  function_name    = "${var.project_name}-${each.key}"
  role             = aws_iam_role.lambda_exec_role.arn
  handler          = "${each.value}.lambda_handler"
  source_code_hash = data.archive_file.lambda_zips[each.key].output_base64sha256
  runtime          = "python3.10"
  timeout          = 15

  environment {
    variables = {
      TABLE_NAME    = aws_dynamodb_table.event_ticketing_db.name
      SNS_TOPIC_ARN = aws_sns_topic.event_confirmations.arn
    }
  }
  
  tags = local.common_tags
}
