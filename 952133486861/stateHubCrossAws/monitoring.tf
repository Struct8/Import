resource "aws_cloudwatch_log_group" "cross-caller-logs" {
  name              = "/aws/lambda/cross-caller"
  log_group_class   = "STANDARD"
  retention_in_days = 7
  skip_destroy      = false
  tags = {
    Name           = "cross-caller-logs"
    State          = "stateHubCrossAws"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_xray_group" "cross-traces" {
  group_name        = "cross-traces"
  filter_expression = "service(\"cross-caller\")"
  tags = {
    Name           = "cross-traces"
    State          = "stateHubCrossAws"
    Struct8Creator = "Contato Struct"
  }
}
