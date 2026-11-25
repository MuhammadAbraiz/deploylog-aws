resource "aws_dynamodb_table" "deployments" {
  name         = "${var.name}-deployments"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "service"
  range_key    = "deployed_at"

  attribute {
    name = "service"
    type = "S"
  }

  attribute {
    name = "deployed_at"
    type = "S"
  }

  # Old records clean themselves up after 90 days
  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }
}
