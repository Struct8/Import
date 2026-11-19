resource "aws_dynamodb_table" "chat_budget" {
  name                        = "chat_budget"
  billing_mode                = "PAY_PER_REQUEST"
  deletion_protection_enabled = false
  hash_key                    = "pk"
  stream_enabled              = false
  table_class                 = "STANDARD"
  attribute {
    name = "pk"
    type = "S"
  }
  tags = {
    Name           = "chat_budget"
    State          = "chat-aurora"
    Struct8Creator = "Contato Struct"
  }
}
