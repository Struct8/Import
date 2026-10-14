terraform {
  required_providers {
    archive = {
      source = "hashicorp/archive"
    }
    aws = {
      source = "hashicorp/aws"
    }
  }

  backend "s3" {
    bucket  = "struct8-import"
    key     = "952133486861/wp-flowlogs/main.tfstate"
    region  = "us-west-2"
    encrypt = true
  }
}

# --- Main Cloud Provider ---
provider "aws" {
  region = "us-west-2"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

### EXTERNAL REFERENCES ###

data "aws_vpc" "wordpress-professional" {
  filter {
    name   = "tag:Name"
    values = ["wordpress-professional"]
  }
}




### CATEGORY: IAM ###

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




### CATEGORY: NETWORK ###

resource "aws_flow_log" "flowlog-vpc-b" {
  vpc_id               = data.aws_vpc.wordpress-professional.id
  log_destination      = aws_s3_bucket.flowlogs-bucket.arn
  log_destination_type = "s3"
  log_format           = "$${version} $${vpc-id} $${subnet-id} $${interface-id} $${instance-id} $${srcaddr} $${dstaddr} $${pkt-srcaddr} $${pkt-dstaddr} $${srcport} $${dstport} $${protocol} $${packets} $${bytes} $${start} $${end} $${action} $${log-status} $${flow-direction} $${traffic-path} $${pkt-src-aws-service} $${pkt-dst-aws-service} $${interface-type}"
  traffic_type         = "ALL"
  tags = {
    Name           = "flowlog-vpc-b"
    State          = "wp-flowlogs"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_s3_bucket_policy.aws_s3_bucket_policy_flowlogs-bucket_st_wp-flowlogs]
}




### CATEGORY: STORAGE ###

resource "aws_s3_bucket" "flowlogs-bucket" {
  bucket              = "flowlogs-bucket-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.region}-an"
  bucket_namespace    = "account-regional"
  force_destroy       = true
  object_lock_enabled = false
  tags = {
    Name           = "flowlogs-bucket"
    State          = "wp-flowlogs"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "flowlogs-bucket_lifecycle" {
  bucket = aws_s3_bucket.flowlogs-bucket.id
  rule {
    id     = "expire-logs"
    status = "Enabled"
    expiration {
      days                         = 1
      expired_object_delete_marker = false
    }
  }
}

resource "aws_s3_bucket_notification" "wp-notify" {
  bucket = aws_s3_bucket.flowlogs-bucket.id
  lambda_function {
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "AWSLogs/"
    filter_suffix       = ".log.gz"
    lambda_function_arn = aws_lambda_function.wp-process-flow-logs.arn
  }
  depends_on = [aws_lambda_permission.perm_aws_s3_bucket_flowlogs-bucket_to_wp-process-flow-logs]
}

resource "aws_s3_bucket_ownership_controls" "flowlogs-bucket_controls" {
  bucket = aws_s3_bucket.flowlogs-bucket.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

data "aws_iam_policy_document" "aws_s3_bucket_policy_flowlogs-bucket_st_wp-flowlogs_doc" {
  statement {
    sid    = "AllowLogDeliveryAclCheck"
    effect = "Allow"
    principals {
      identifiers = ["delivery.logs.amazonaws.com"]
      type        = "Service"
    }
    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.flowlogs-bucket.arn]
    condition {
      test     = "StringEquals"
      values   = [data.aws_caller_identity.current.account_id]
      variable = "AWS:SourceAccount"
    }
  }
  statement {
    sid    = "AllowLogDeliveryWrite"
    effect = "Allow"
    principals {
      identifiers = ["delivery.logs.amazonaws.com"]
      type        = "Service"
    }
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.flowlogs-bucket.arn}/*"]
    condition {
      test     = "StringEquals"
      values   = [data.aws_caller_identity.current.account_id]
      variable = "AWS:SourceAccount"
    }
  }
}

resource "aws_s3_bucket_policy" "aws_s3_bucket_policy_flowlogs-bucket_st_wp-flowlogs" {
  bucket = aws_s3_bucket.flowlogs-bucket.id
  policy = data.aws_iam_policy_document.aws_s3_bucket_policy_flowlogs-bucket_st_wp-flowlogs_doc.json
}

resource "aws_s3_bucket_public_access_block" "flowlogs-bucket_block" {
  block_public_acls       = true
  block_public_policy     = true
  bucket                  = aws_s3_bucket.flowlogs-bucket.id
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "flowlogs-bucket_configuration" {
  bucket = aws_s3_bucket.flowlogs-bucket.id
  rule {
    bucket_key_enabled = true
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "flowlogs-bucket_versioning" {
  bucket = aws_s3_bucket.flowlogs-bucket.id
  versioning_configuration {
    mfa_delete = "Disabled"
    status     = "Suspended"
  }
}




### CATEGORY: COMPUTE ###

data "archive_file" "archive_struct8-templates_wp-process-flow-logs" {
  output_path = "${path.module}/struct8-templates_wp-process-flow-logs.zip"
  source_dir  = "${path.module}/.external_modules/struct8-templates/templates/vpc-flowlogs-amp/v1/lambda/process-flow-logs"
  type        = "zip"
}

resource "aws_lambda_function" "wp-process-flow-logs" {
  function_name                  = "wp-process-flow-logs"
  architectures                  = ["arm64"]
  description                    = "Reads each VPC Flow Logs object delivered to the bucket and writes bytes and packets per conversation per minute to the Prometheus workspace."
  filename                       = data.archive_file.archive_struct8-templates_wp-process-flow-logs.output_path
  handler                        = "ProcessFlowLogs.lambda_handler"
  memory_size                    = 2024
  publish                        = false
  reserved_concurrent_executions = -1
  role                           = aws_iam_role.wp-process-flow-logs_role.arn
  runtime                        = "python3.13"
  source_code_hash               = data.archive_file.archive_struct8-templates_wp-process-flow-logs.output_base64sha256
  timeout                        = 120
  environment {
    variables = {
    FLOW_LOG_BUCKET                     = aws_s3_bucket.flowlogs-bucket.id
    CUTOFF_SECONDS                      = "120"
    BUCKET_SECONDS                      = "60"
    FALLBACK_FIELD_ORDER                = "version vpc-id subnet-id interface-id instance-id srcaddr dstaddr pkt-srcaddr pkt-dstaddr srcport dstport protocol packets bytes start end action log-status flow-direction traffic-path pkt-src-aws-service pkt-dst-aws-service interface-type"
    NAME                                = "wp-process-flow-logs"
    REGION                              = data.aws_region.current.region
    ACCOUNT                             = data.aws_caller_identity.current.account_id
    AWS_PROMETHEUS_WORKSPACE_ENDPOINT_0 = aws_prometheus_workspace.wp-flowlogs-amp.prometheus_endpoint
    AWS_PROMETHEUS_WORKSPACE_ID_0       = aws_prometheus_workspace.wp-flowlogs-amp.id
    AWS_S3_BUCKET_NAME_0                = "flowlogs-bucket-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.region}-an"
  }
  }
  tags = {
    Name           = "wp-process-flow-logs"
    State          = "wp-flowlogs"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_iam_role_policy_attachment.lambda_function_wp-process-flow-logs_st_wp-flowlogs_attach]
}

resource "aws_lambda_permission" "perm_aws_s3_bucket_flowlogs-bucket_to_wp-process-flow-logs" {
  function_name = aws_lambda_function.wp-process-flow-logs.function_name
  statement_id  = "perm_aws_s3_bucket_flowlogs-bucket_to_wp-process-flow-logs"
  principal     = "s3.amazonaws.com"
  action        = "lambda:InvokeFunction"
  source_arn    = aws_s3_bucket.flowlogs-bucket.arn
}




### CATEGORY: MONITORING ###

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


