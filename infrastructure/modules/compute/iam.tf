data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# Shared account-level OIDC provider (owned by infrastructure/bootstrap)
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

# ---------------------------------------------------------------------------
# GitHub Actions: deploy role (Lambda code + frontend sync)
# ---------------------------------------------------------------------------
resource "aws_iam_role" "github_actions_deploy_role" {
  name = "${var.prefix}-gha-deploy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = data.aws_iam_openid_connect_provider.github.arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          "token.actions.githubusercontent.com:sub" = var.github_oidc_subs
        }
      }
    }]
  })

  tags = var.common_tags
}

resource "aws_iam_role_policy" "github_actions_deploy" {
  name = "${var.prefix}-gha-deploy"
  role = aws_iam_role.github_actions_deploy_role.id

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
        Resource = [for fn in aws_lambda_function.api_handlers : fn.arn]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetObject"
        ]
        Resource = [
          var.frontend_bucket_arn,
          "${var.frontend_bucket_arn}/*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = ["cloudfront:CreateInvalidation", "cloudfront:GetDistribution"]
        Resource = [var.cloudfront_distribution_arn]
      }
    ]
  })
}

# ---------------------------------------------------------------------------
# GitHub Actions: terraform role (plan/apply for this environment)
# ---------------------------------------------------------------------------
resource "aws_iam_role" "github_actions_terraform_role" {
  name = "${var.prefix}-gha-terraform-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = data.aws_iam_openid_connect_provider.github.arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          "token.actions.githubusercontent.com:sub" = var.github_oidc_subs
        }
      }
    }]
  })

  tags = var.common_tags
}

resource "aws_iam_role_policy" "github_actions_terraform" {
  name = "${var.prefix}-gha-terraform"
  role = aws_iam_role.github_actions_terraform_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadStateBucket"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketVersioning",
          "s3:GetBucketLocation"
        ]
        Resource = [var.state_bucket_arn]
      },
      {
        Sid    = "StateObjects"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = ["${var.state_bucket_arn}/${var.environment}/*"]
      },
      {
        Sid    = "BroadProvisioner"
        Effect = "Allow"
        Action = [
          "apigateway:*",
          "cloudfront:*",
          "cloudwatch:*",
          "dynamodb:*",
          "iam:*",
          "lambda:*",
          "logs:*",
          "s3:*",
          "sns:*",
          "ssm:*",
          "budgets:*",
          "xray:*",
          "sts:GetCallerIdentity"
        ]
        Resource = "*"
      }
    ]
  })
}

# Keep the legacy role name as an alias during migration so existing
# AWS_OIDC_ROLE_ARN secrets that point at *-github-oidc-role keep working
# until secrets are rotated to the new deploy role ARN.
resource "aws_iam_role" "github_actions_role" {
  name = "${var.prefix}-github-oidc-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = data.aws_iam_openid_connect_provider.github.arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          "token.actions.githubusercontent.com:sub" = var.github_oidc_subs
        }
      }
    }]
  })

  tags = var.common_tags
}

resource "aws_iam_role_policy" "github_actions_lambda_deploy" {
  name = "${var.prefix}-github-lambda-deploy"
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
        Resource = [for fn in aws_lambda_function.api_handlers : fn.arn]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetObject"
        ]
        Resource = [
          var.frontend_bucket_arn,
          "${var.frontend_bucket_arn}/*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = ["cloudfront:CreateInvalidation", "cloudfront:GetDistribution"]
        Resource = [var.cloudfront_distribution_arn]
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
  name     = "${var.prefix}-${each.key}-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
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
  name = "${var.prefix}-register-policy"
  role = aws_iam_role.lambda_roles["register"].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["dynamodb:PutItem", "dynamodb:GetItem"]
        Resource = var.table_arn
      },
      {
        Effect   = "Allow"
        Action   = ["sns:Publish"]
        Resource = var.sns_topic_arn
      },
      {
        Effect   = "Allow"
        Action   = ["ses:SendEmail"]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["ssm:GetParameter"]
        Resource = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter${var.smtp_password_ssm_name}"
      }
    ]
  })
}

# get_events
resource "aws_iam_role_policy" "get_events_policy" {
  name = "${var.prefix}-get-events-policy"
  role = aws_iam_role.lambda_roles["get_events"].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["dynamodb:Query"]
        Resource = "${var.table_arn}/index/SKIndex"
      }
    ]
  })
}

# get_registrations
resource "aws_iam_role_policy" "get_registrations_policy" {
  name = "${var.prefix}-get-registrations-policy"
  role = aws_iam_role.lambda_roles["get_registrations"].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["dynamodb:Query"]
        Resource = "${var.table_arn}/index/UserEmailIndex"
      }
    ]
  })
}

# delete_registration
resource "aws_iam_role_policy" "delete_registration_policy" {
  name = "${var.prefix}-delete-registration-policy"
  role = aws_iam_role.lambda_roles["delete_registration"].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["dynamodb:Query"]
        Resource = "${var.table_arn}/index/RegistrationIdIndex"
      },
      {
        Effect   = "Allow"
        Action   = ["dynamodb:DeleteItem"]
        Resource = var.table_arn
      }
    ]
  })
}

# create_event
resource "aws_iam_role_policy" "create_event_policy" {
  name = "${var.prefix}-create-event-policy"
  role = aws_iam_role.lambda_roles["create_event"].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["dynamodb:PutItem"]
        Resource = var.table_arn
      }
    ]
  })
}

# update_event
resource "aws_iam_role_policy" "update_event_policy" {
  name = "${var.prefix}-update-event-policy"
  role = aws_iam_role.lambda_roles["update_event"].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["dynamodb:UpdateItem", "dynamodb:GetItem"]
        Resource = var.table_arn
      }
    ]
  })
}

# delete_event
resource "aws_iam_role_policy" "delete_event_policy" {
  name = "${var.prefix}-delete-event-policy"
  role = aws_iam_role.lambda_roles["delete_event"].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["dynamodb:DeleteItem", "dynamodb:GetItem", "dynamodb:Query"]
        Resource = var.table_arn
      }
    ]
  })
}

# authorizer
resource "aws_iam_role_policy" "authorizer_policy" {
  name = "${var.prefix}-authorizer-policy"
  role = aws_iam_role.lambda_roles["authorizer"].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ssm:GetParameter"]
        Resource = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter${var.admin_api_key_ssm_name}"
      }
    ]
  })
}