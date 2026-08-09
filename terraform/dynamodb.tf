resource "aws_dynamodb_table" "event_ticketing_db" {
  name                        = "${local.prefix}-table"
  billing_mode                = "PAY_PER_REQUEST"
  hash_key                    = "PK"
  range_key                   = "SK"
  deletion_protection_enabled = false # Changed to false for easier teardown if needed during testing

  point_in_time_recovery {
    enabled = true
  }

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
  attribute {
    name = "RegistrationId"
    type = "S"
  }

  # GSI to fetch all registrations for a specific email
  global_secondary_index {
    name               = "UserEmailIndex"
    hash_key           = "UserEmail"
    range_key          = "PK"
    projection_type    = "ALL"
  }

  # GSI to fetch all events (replaces table scan)
  global_secondary_index {
    name               = "SKIndex"
    hash_key           = "SK"
    range_key          = "PK"
    projection_type    = "ALL"
  }

  # GSI to find a registration by its ID (replaces table scan)
  global_secondary_index {
    name               = "RegistrationIdIndex"
    hash_key           = "RegistrationId"
    projection_type    = "ALL"
  }

  tags = local.common_tags
}