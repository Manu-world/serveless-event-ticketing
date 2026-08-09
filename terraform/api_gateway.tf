# 1. Define the HTTP API with Native CORS
resource "aws_apigatewayv2_api" "http_api" {
  name          = "${local.prefix}-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["https://${aws_cloudfront_distribution.cdn.domain_name}", "http://localhost:5500", "http://127.0.0.1:5500"]
    allow_methods = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    allow_headers = ["Content-Type", "Authorization", "x-api-key"]
  }
  
  tags = local.common_tags
}

# 2. Configure the Stage and Rate Limiting (Throttling)
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true

  default_route_settings {
    throttling_burst_limit = 100 # Max concurrent requests
    throttling_rate_limit  = 50  # Steady-state requests per second
  }

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw.arn
    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
    })
  }
}

resource "aws_cloudwatch_log_group" "api_gw" {
  name              = "/aws/api_gw/${aws_apigatewayv2_api.http_api.name}"
  retention_in_days = 14
  tags              = local.common_tags
}

# 3. Lambda Authorizer
resource "aws_apigatewayv2_authorizer" "admin_auth" {
  api_id                            = aws_apigatewayv2_api.http_api.id
  authorizer_type                   = "REQUEST"
  authorizer_uri                    = aws_lambda_function.api_handlers["authorizer"].invoke_arn
  identity_sources                  = ["$request.header.x-api-key"]
  name                              = "${local.prefix}-admin-authorizer"
  authorizer_payload_format_version = "2.0"
  enable_simple_responses           = true
}

# 4. Map Routes to the Lambda Functions
locals {
  public_routes = {
    "POST /register"             = "register"
    "GET /events"                = "get_events"
    "GET /registrations/{email}" = "get_registrations"
    "DELETE /registration/{id}"  = "delete_registration"
  }
  admin_routes = {
    "POST /admin/events"           = "create_event"
    "PUT /admin/events/{eventId}"  = "update_event"
    "DELETE /admin/events/{eventId}" = "delete_event"
  }
  all_routes = merge(local.public_routes, local.admin_routes)
}

# 5. Create the Lambda Proxy Integrations
resource "aws_apigatewayv2_integration" "lambda_integration" {
  for_each           = local.all_routes
  api_id             = aws_apigatewayv2_api.http_api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.api_handlers[each.value].invoke_arn
  integration_method = "POST"
}

# 6. Create Public Routes
resource "aws_apigatewayv2_route" "public_routes" {
  for_each  = local.public_routes
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = each.key
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration[each.key].id}"
}

# 7. Create Admin Routes
resource "aws_apigatewayv2_route" "admin_routes" {
  for_each           = local.admin_routes
  api_id             = aws_apigatewayv2_api.http_api.id
  route_key          = each.key
  target             = "integrations/${aws_apigatewayv2_integration.lambda_integration[each.key].id}"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.admin_auth.id
}

# 8. Grant API Gateway Permission to Invoke the Handler Lambdas
resource "aws_lambda_permission" "api_gw_invoke" {
  for_each      = local.all_routes
  statement_id  = "AllowExecutionFromAPIGateway_${replace(each.value, "/", "_")}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api_handlers[each.value].function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "authorizer_invoke" {
  statement_id  = "AllowExecutionFromAPIGateway_Authorizer"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api_handlers["authorizer"].function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}