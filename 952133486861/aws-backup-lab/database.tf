resource "aws_dynamodb_table" "lab-orders" {
  name                        = "lab-orders"
  billing_mode                = "PAY_PER_REQUEST"
  deletion_protection_enabled = false
  hash_key                    = "order_id"
  stream_enabled              = false
  table_class                 = "STANDARD"
  attribute {
    name = "order_id"
    type = "S"
  }
  tags = {
    "Struct8:Backup:backup-lab-hourly-8ee55440" = true
    Name                                        = "lab-orders"
    State                                       = "aws-backup-lab"
    Struct8Creator                              = "Contato Struct"
  }
}
