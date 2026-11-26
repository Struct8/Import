resource "aws_cloudwatch_log_group" "eks-kuma-logs" {
  name              = "/aws/eks/eks-kuma/cluster"
  log_group_class   = "STANDARD"
  retention_in_days = 7
  skip_destroy      = false
  tags = {
    Name           = "eks-kuma-logs"
    State          = "eks-kuma-infra"
    Struct8Creator = "Contato Struct"
  }
}
