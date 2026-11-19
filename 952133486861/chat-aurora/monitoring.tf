resource "aws_cloudwatch_log_group" "LogGroup" {
  name              = "/aws/lambda/db_query"
  log_group_class   = "STANDARD"
  retention_in_days = 1
  skip_destroy      = false
  tags = {
    Name           = "LogGroup"
    State          = "chat-aurora"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_cloudwatch_log_group" "web_chat_logs" {
  name              = "/aws/lambda/web_chat"
  log_group_class   = "STANDARD"
  retention_in_days = 30
  skip_destroy      = false
  tags = {
    Name           = "web_chat_logs"
    State          = "chat-aurora"
    Struct8Creator = "Contato Struct"
  }
}
