# 1. Define the HTTP API with Native CORS
resource "aws_apigatewayv2_api" "http_api" {
  name          = "${var.project_name}-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"] # In a strict production environment, this would be my CloudFront domain
    allow_methods = ["GET", "POST", "DELETE", "OPTIONS"]
    allow_headers = ["Content-Type", "Authorization"]
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
}

# 3. Map Routes to the Lambda Functions
locals {
  api_routes = {
    "POST /register"            = "register"
    "GET /events"               = "get_events"
    "GET /registrations/{email}" = "get_registrations"
    "DELETE /registration/{id}" = "delete_registration"
  }
}

# 4. Create the Lambda Proxy Integrations
resource "aws_apigatewayv2_integration" "lambda_integration" {
  for_each           = local.api_routes
  api_id             = aws_apigatewayv2_api.http_api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.api_handlers[each.value].invoke_arn
  integration_method = "POST" # API Gateway always invokes Lambda via POST, regardless of the client method
}

# 5. Create the Routes
resource "aws_apigatewayv2_route" "api_routes" {
  for_each  = local.api_routes
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = each.key
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration[each.key].id}"
}

# 6. Grant API Gateway Permission to Invoke the Lambdas
resource "aws_lambda_permission" "api_gw_invoke" {
  for_each      = local.api_routes
  statement_id  = "AllowExecutionFromAPIGateway_${each.value}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api_handlers[each.value].function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}

# 7. Output the Final Base URL
output "api_endpoint" {
  description = "The base URL for the API Gateway"
  value       = aws_apigatewayv2_api.http_api.api_endpoint
}