# 1. OIDC Provider for GitHub Actions
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["1c58a3a8518e8759bf075b76b750d4f2df264fcd", "6938fd4d98bab03faadb97b34396831e3780aea1"]
}

# 2. IAM Role for GitHub Actions
resource "aws_iam_role" "github_actions_role" {
  name = "${local.prefix}-github-oidc-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Federated = aws_iam_openid_connect_provider.github.arn }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          "token.actions.githubusercontent.com:sub" = local.github_oidc_subs
        }
      }
    }]
  })
}

# Allow GitHub Actions to publish updated Lambda code after tests pass
resource "aws_iam_role_policy" "github_actions_lambda_deploy" {
  name = "${local.prefix}-github-lambda-deploy"
  role = aws_iam_role.github_actions_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:UpdateFunctionCode",
          "lambda:GetFunction",
          "lambda:GetFunctionConfiguration",
          "lambda:PublishVersion"
        ]
        Resource = [
          for fn in aws_lambda_function.api_handlers : fn.arn
        ]
      }
    ]
  })
}

# 3. Per-Function Lambda IAM Roles

locals {
  lambda_functions = [
    "register",
    "get_events",
    "get_registrations",
    "delete_registration",
    "create_event",
    "update_event",
    "delete_event",
    "authorizer"
  ]
}

resource "aws_iam_role" "lambda_roles" {
  for_each = toset(local.lambda_functions)
  name     = "${local.prefix}-${each.key}-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  for_each   = aws_iam_role.lambda_roles
  role       = each.value.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# X-Ray Tracing Permission for all lambdas
resource "aws_iam_role_policy_attachment" "lambda_xray" {
  for_each   = aws_iam_role.lambda_roles
  role       = each.value.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}

# Specific Policies for each function
# register
resource "aws_iam_role_policy" "register_policy" {
  name = "${local.prefix}-register-policy"
  role = aws_iam_role.lambda_roles["register"].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["dynamodb:PutItem", "dynamodb:GetItem"]
        Resource = aws_dynamodb_table.event_ticketing_db.arn
      },
      {
        Effect = "Allow"
        Action = ["sns:Publish"]
        Resource = aws_sns_topic.admin_alerts.arn
      },
      {
        Effect = "Allow"
        Action = ["ses:SendEmail"]
        Resource = "*"
      }
    ]
  })
}

# get_events
resource "aws_iam_role_policy" "get_events_policy" {
  name = "${local.prefix}-get-events-policy"
  role = aws_iam_role.lambda_roles["get_events"].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["dynamodb:Query"]
        Resource = "${aws_dynamodb_table.event_ticketing_db.arn}/index/SKIndex"
      }
    ]
  })
}

# get_registrations
resource "aws_iam_role_policy" "get_registrations_policy" {
  name = "${local.prefix}-get-registrations-policy"
  role = aws_iam_role.lambda_roles["get_registrations"].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["dynamodb:Query"]
        Resource = "${aws_dynamodb_table.event_ticketing_db.arn}/index/UserEmailIndex"
      }
    ]
  })
}

# delete_registration
resource "aws_iam_role_policy" "delete_registration_policy" {
  name = "${local.prefix}-delete-registration-policy"
  role = aws_iam_role.lambda_roles["delete_registration"].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["dynamodb:Query"]
        Resource = "${aws_dynamodb_table.event_ticketing_db.arn}/index/RegistrationIdIndex"
      },
      {
        Effect = "Allow"
        Action = ["dynamodb:DeleteItem"]
        Resource = aws_dynamodb_table.event_ticketing_db.arn
      }
    ]
  })
}

# create_event
resource "aws_iam_role_policy" "create_event_policy" {
  name = "${local.prefix}-create-event-policy"
  role = aws_iam_role.lambda_roles["create_event"].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["dynamodb:PutItem"]
        Resource = aws_dynamodb_table.event_ticketing_db.arn
      }
    ]
  })
}

# update_event
resource "aws_iam_role_policy" "update_event_policy" {
  name = "${local.prefix}-update-event-policy"
  role = aws_iam_role.lambda_roles["update_event"].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["dynamodb:UpdateItem", "dynamodb:GetItem"]
        Resource = aws_dynamodb_table.event_ticketing_db.arn
      }
    ]
  })
}

# delete_event
resource "aws_iam_role_policy" "delete_event_policy" {
  name = "${local.prefix}-delete-event-policy"
  role = aws_iam_role.lambda_roles["delete_event"].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["dynamodb:DeleteItem", "dynamodb:GetItem", "dynamodb:Query"]
        Resource = aws_dynamodb_table.event_ticketing_db.arn
      }
    ]
  })
}

# authorizer
resource "aws_iam_role_policy" "authorizer_policy" {
  name = "${local.prefix}-authorizer-policy"
  role = aws_iam_role.lambda_roles["authorizer"].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["ssm:GetParameter"]
        Resource = aws_ssm_parameter.admin_api_key.arn
      }
    ]
  })
}