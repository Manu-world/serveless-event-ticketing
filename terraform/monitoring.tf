# 1. Explicit Log Groups for Retention Management
resource "aws_cloudwatch_log_group" "lambda_logs" {
  for_each          = local.lambdas
  name              = "/aws/lambda/${local.prefix}-${each.key}"
  retention_in_days = 14
  tags              = local.common_tags
}

# 2. CloudWatch Alarm: 5% Error Rate (All Lambdas)
resource "aws_cloudwatch_metric_alarm" "high_error_rate" {
  for_each            = local.lambdas
  alarm_name          = "${local.prefix}-${each.key}-error-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  threshold           = "5" # 5%
  alarm_description   = "Triggers if the ${each.key} Lambda error rate exceeds 5%"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.admin_alerts.arn]

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
        FunctionName = aws_lambda_function.api_handlers[each.key].function_name
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
        FunctionName = aws_lambda_function.api_handlers[each.key].function_name
      }
    }
  }
}

# 3. Lambda Duration Alarm (>10s)
resource "aws_cloudwatch_metric_alarm" "high_duration" {
  for_each            = local.lambdas
  alarm_name          = "${local.prefix}-${each.key}-duration"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  threshold           = "10000" # 10 seconds in ms
  alarm_description   = "Triggers if ${each.key} Lambda takes longer than 10s"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.admin_alerts.arn]

  metric_name = "Duration"
  namespace   = "AWS/Lambda"
  period      = "300"
  statistic   = "Average"
  dimensions = {
    FunctionName = aws_lambda_function.api_handlers[each.key].function_name
  }
}

# 4. API Gateway 5xx Alarm
resource "aws_cloudwatch_metric_alarm" "api_gw_5xx" {
  alarm_name          = "${local.prefix}-api-5xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  threshold           = "10"
  alarm_description   = "API Gateway returning 5xx errors"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.admin_alerts.arn]

  metric_name = "5XXError"
  namespace   = "AWS/ApiGateway"
  period      = "300"
  statistic   = "Sum"
  dimensions = {
    ApiId = aws_apigatewayv2_api.http_api.id
  }
}

# 5. DynamoDB Throttling Alarm
resource "aws_cloudwatch_metric_alarm" "ddb_throttling" {
  alarm_name          = "${local.prefix}-ddb-throttling"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  threshold           = "5"
  alarm_description   = "DynamoDB requests are being throttled"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.admin_alerts.arn]

  metric_name = "ThrottledRequests"
  namespace   = "AWS/DynamoDB"
  period      = "300"
  statistic   = "Sum"
  dimensions = {
    TableName = aws_dynamodb_table.event_ticketing_db.name
  }
}