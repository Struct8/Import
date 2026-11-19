resource "aws_cloudwatch_log_group" "Struct8Probe_debug-wp_wordpress_logs" {
  name              = "/struct8/probe/t1eAUxGPRo-vo6lIyc15I/wordpress"
  retention_in_days = 1
}

resource "aws_cloudwatch_log_group" "logsWordpress" {
  name              = "/ecs/wordpress"
  log_group_class   = "STANDARD"
  retention_in_days = 30
  skip_destroy      = false
  tags = {
    Name           = "logsWordpress"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_cloudwatch_metric_alarm" "alarmDbCapacity" {
  alarm_name          = "alarmDbCapacity"
  metric_name         = "ServerlessDatabaseCapacity"
  alarm_actions       = [aws_sns_topic.alarmsWordpress.arn]
  alarm_description   = "Aurora has run at its maximum capacity (2 ACUs) for 15 minutes. If this repeats, raise the maximum capacity of the wp-aurora cluster and this threshold with it."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  datapoints_to_alarm = 3
  evaluation_periods  = 3
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 2
  treat_missing_data  = "notBreaching"
  dimensions = {
    DBClusterIdentifier = aws_rds_cluster.wp-aurora.cluster_identifier
  }
  tags = {
    Name           = "alarmDbCapacity"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_cloudwatch_metric_alarm" "alarmSite5xx" {
  alarm_name          = "alarmSite5xx"
  metric_name         = "HTTPCode_ELB_5XX_Count"
  alarm_actions       = [aws_sns_topic.alarmsWordpress.arn]
  alarm_description   = "The load balancer itself answered 5xx (502, 503 or 504) at least 10 times in 5 minutes: no healthy WordPress task, or tasks not answering."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  datapoints_to_alarm = 1
  evaluation_periods  = 1
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  treat_missing_data  = "notBreaching"
  dimensions = {
    LoadBalancer = aws_lb.alb-wp.arn_suffix
  }
  tags = {
    Name           = "alarmSite5xx"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_cloudwatch_metric_alarm" "alarmTasksCpu" {
  alarm_name          = "alarmTasksCpu"
  metric_name         = "CPUUtilization"
  alarm_actions       = [aws_sns_topic.alarmsWordpress.arn]
  alarm_description   = "Average CPU of the WordPress service above 80% for 15 minutes."
  comparison_operator = "GreaterThanThreshold"
  datapoints_to_alarm = 3
  evaluation_periods  = 3
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  dimensions = {
    ClusterName = aws_ecs_cluster.wp-cluster.name
    ServiceName = aws_ecs_service.wordpress_service.name
  }
  tags = {
    Name           = "alarmTasksCpu"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_cloudwatch_metric_alarm" "alarmTasksMemory" {
  alarm_name          = "alarmTasksMemory"
  metric_name         = "MemoryUtilization"
  alarm_actions       = [aws_sns_topic.alarmsWordpress.arn]
  alarm_description   = "Average memory of the WordPress service above 85% of the task memory for 15 minutes."
  comparison_operator = "GreaterThanThreshold"
  datapoints_to_alarm = 3
  evaluation_periods  = 3
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 85
  dimensions = {
    ClusterName = aws_ecs_cluster.wp-cluster.name
    ServiceName = aws_ecs_service.wordpress_service.name
  }
  tags = {
    Name           = "alarmTasksMemory"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_xray_group" "wordpressTraces" {
  group_name        = "wordpressTraces"
  filter_expression = "service(\"alarmsWordpress\") OR service(\"wordpress\")"
  tags = {
    Name           = "wordpressTraces"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
}

data "aws_iam_policy_document" "aws_xray_resource_policy_st_wordpress-professional_6a7eb02276_doc" {
  statement {
    sid    = "AllowSNSToSendTracesToXRay"
    effect = "Allow"
    principals {
      identifiers = ["sns.amazonaws.com"]
      type        = "Service"
    }
    actions   = ["xray:GetSamplingRules", "xray:GetSamplingTargets", "xray:PutTraceSegments"]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      values   = [data.aws_caller_identity.current.account_id]
      variable = "aws:SourceAccount"
    }
    condition {
      test     = "StringLike"
      values   = ["arn:aws:sns:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:*"]
      variable = "aws:SourceArn"
    }
  }
}

resource "aws_xray_resource_policy" "aws_xray_resource_policy_st_wordpress-professional_6a7eb02276" {
  policy_name     = "aws_xray_resource_policy_st_wordpress-professional_6a7eb02276"
  policy_document = data.aws_iam_policy_document.aws_xray_resource_policy_st_wordpress-professional_6a7eb02276_doc.json
}
