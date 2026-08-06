# 1. Explicit Log Groups for Retention Management
resource "aws_cloudwatch_log_group" "lambda_logs" {
  for_each          = local.lambdas
  name              = "/aws/lambda/${var.project_name}-${each.key}"
  retention_in_days = 14
  tags              = local.common_tags
}

# 2. CloudWatch Alarm: 5% Error Rate on the Register API
resource "aws_cloudwatch_metric_alarm" "high_error_rate" {
  alarm_name          = "${var.project_name}-register-error-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  threshold           = "5" # 5%
  alarm_description   = "Triggers if the POST /register Lambda error rate exceeds 5%"
  treat_missing_data  = "notBreaching"

  metric_query {
    id          = "e1"
    expression  = "(errors / invocations) * 100"
    label       = "Error Rate (%)"
    return_data = true
  }

  metric_query {
    id = "errors"
    metric {
      metric_name = "Errors"
      namespace   = "AWS/Lambda"
      period      = "300" # 5 minutes
      stat        = "Sum"
      dimensions = {
        FunctionName = aws_lambda_function.api_handlers["register"].function_name
      }
    }
  }

  metric_query {
    id = "invocations"
    metric {
      metric_name = "Invocations"
      namespace   = "AWS/Lambda"
      period      = "300"
      stat        = "Sum"
      dimensions = {
        FunctionName = aws_lambda_function.api_handlers["register"].function_name
      }
    }
  }
}