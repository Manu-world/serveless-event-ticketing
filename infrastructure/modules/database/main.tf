resource "aws_dynamodb_table" "event_ticketing_db" {
  name                        = "${var.prefix}-table"
  billing_mode                = "PAY_PER_REQUEST"
  hash_key                    = "PK"
  range_key                   = "SK"
  deletion_protection_enabled = var.deletion_protection_enabled

  point_in_time_recovery {
    enabled = var.enable_pitr
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

  global_secondary_index {
    name            = "UserEmailIndex"
    hash_key        = "UserEmail"
    range_key       = "PK"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "SKIndex"
    hash_key        = "SK"
    range_key       = "PK"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "RegistrationIdIndex"
    hash_key        = "RegistrationId"
    projection_type = "ALL"
  }

  tags = var.common_tags
}
