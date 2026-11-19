resource "aws_prometheus_workspace" "wp-flowlogs-amp" {
  alias = "wp-flowlogs-amp"
  tags = {
    Struct8Management = "Struct8Flow"
    Name              = "wp-flowlogs-amp"
    State             = "wp-flowlogs"
    Struct8Creator    = "Contato Struct"
  }
}

resource "aws_prometheus_workspace_configuration" "wp-flowlogs-amp_configuration" {
  workspace_id                        = aws_prometheus_workspace.wp-flowlogs-amp.id
  out_of_order_time_window_in_seconds = 600
  retention_period_in_days            = 30
  rule_query_offset_in_seconds        = 60
}
