data "aws_iam_policy_document" "lambda_function_wp-process-flow-logs_st_wp-flowlogs_doc" {
  statement {
    sid       = "AllowPrometheusRemoteWrite"
    effect    = "Allow"
    actions   = ["aps:GetLabels", "aps:GetMetricMetadata", "aps:GetSeries", "aps:QueryMetrics", "aps:RemoteWrite"]
    resources = [aws_prometheus_workspace.wp-flowlogs-amp.arn]
  }
  statement {
    sid       = "AllowBucketLevelActions"
    effect    = "Allow"
    actions   = ["s3:GetBucketLocation", "s3:ListBucket"]
    resources = [aws_s3_bucket.flowlogs-bucket.arn]
  }
  statement {
    sid       = "AllowObjectCRUD"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.flowlogs-bucket.arn}/*"]
  }
  statement {
    sid       = "AllowReadingWhoOwnsEachAddress"
    effect    = "Allow"
    actions   = ["ec2:DescribeInstances", "ec2:DescribeNatGateways", "ec2:DescribeNetworkInterfaces", "ec2:DescribeVpcEndpoints", "ec2:DescribeVpcs", "elasticloadbalancing:DescribeTags", "lambda:ListTags", "rds:DescribeDBInstances", "rds:DescribeDBProxies", "tag:GetResources"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "lambda_function_wp-process-flow-logs_st_wp-flowlogs" {
  name        = "lambda_function_wp-process-flow-logs_st_wp-flowlogs"
  description = "Access Policy for wp-process-flow-logs"
  policy      = data.aws_iam_policy_document.lambda_function_wp-process-flow-logs_st_wp-flowlogs_doc.json
}

resource "aws_iam_role" "wp-process-flow-logs_role" {
  name = "wp-process-flow-logs_role"
  assume_role_policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      }
    }
  ]
})
  force_detach_policies = false
  max_session_duration  = 3600
  path                  = "/"
  tags = {
    Name           = "wp-process-flow-logs_role"
    State          = "wp-flowlogs"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role_policy_attachment" "lambda_function_wp-process-flow-logs_st_wp-flowlogs_attach" {
  policy_arn = aws_iam_policy.lambda_function_wp-process-flow-logs_st_wp-flowlogs.arn
  role       = aws_iam_role.wp-process-flow-logs_role.name
}
