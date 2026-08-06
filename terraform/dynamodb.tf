resource "aws_dynamodb_table" "event_ticketing_db" {
  name         = "${var.project_name}-table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "PK"
  range_key    = "SK"

  attribute {
    name = "PK"
    type = "S"
  }
  attribute {
    name = "SK"
    type = "S"
  }
  attribute {
    name = "UserEmail"
    type = "S"
  }

  # GSI to fetch all registrations for a specific email
  global_secondary_index {
    name               = "UserEmailIndex"
    hash_key           = "UserEmail"
    range_key          = "PK"
    projection_type    = "ALL"
  }

  tags = local.common_tags
}