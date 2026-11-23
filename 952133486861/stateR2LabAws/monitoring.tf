resource "aws_cloudwatch_log_group" "r2-lab-fn-logs" {
  name              = "/aws/lambda/r2-lab-fn"
  log_group_class   = "STANDARD"
  retention_in_days = 1
  skip_destroy      = false
  tags = {
    Name           = "r2-lab-fn-logs"
    State          = "stateR2LabAws"
    Struct8Creator = "Contato Struct"
  }
}
