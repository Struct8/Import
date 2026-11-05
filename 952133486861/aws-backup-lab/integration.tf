resource "aws_scheduler_schedule" "efs-writer-every-5-min" {
  name                = "efs-writer-every-5-min"
  schedule_expression = "rate(5 minutes)"
  flexible_time_window {
    mode = "OFF"
  }
  target {
    arn      = aws_ecs_cluster.backup-lab-cluster.arn
    role_arn = aws_iam_role.efs-writer-every-5-min_role.arn
    ecs_parameters {
      launch_type         = "FARGATE"
      propagate_tags      = "TASK_DEFINITION"
      task_definition_arn = aws_ecs_task_definition.efs-writer.arn
      network_configuration {
        assign_public_ip = true
        security_groups  = [aws_security_group.ecs_task_definition_efs-writer_group.id]
        subnets          = [aws_subnet.pubA1.id]
      }
    }
  }
  depends_on = [aws_iam_role_policy_attachment.scheduler_schedule_efs-writer-every-5-min_st_aws-backup-lab_attach]
}
