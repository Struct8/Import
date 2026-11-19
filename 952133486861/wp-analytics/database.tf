resource "aws_dynamodb_table" "cspTable" {
  name                        = "cspTable"
  billing_mode                = "PROVISIONED"
  deletion_protection_enabled = false
  hash_key                    = "pk"
  range_key                   = "sk"
  read_capacity               = 3
  stream_enabled              = false
  table_class                 = "STANDARD"
  write_capacity              = 3
  attribute {
    name = "pk"
    type = "S"
  }
  attribute {
    name = "sk"
    type = "S"
  }
  lifecycle {
    ignore_changes = [read_capacity]
  }
  tags = {
    Name           = "cspTable"
    State          = "wp-analytics"
    Struct8Creator = "Contato Struct"
  }
  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }
}
