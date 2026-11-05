resource "aws_cloudwatch_log_group" "logs-efs-writer" {
  name              = "/aws/ecs/efs-writer"
  log_group_class   = "STANDARD"
  retention_in_days = 1
  skip_destroy      = false
  tags = {
    Name           = "logs-efs-writer"
    State          = "aws-backup-lab"
    Struct8Creator = "Contato Struct"
  }
}
