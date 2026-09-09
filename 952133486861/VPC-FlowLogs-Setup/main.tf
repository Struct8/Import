terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  backend "s3" {
    bucket  = "struct8-import"
    key     = "952133486861/VPC-FlowLogs-Setup/main.tfstate"
    region  = "us-west-2"
    encrypt = true
  }
}

# --- Main Cloud Provider ---
provider "aws" {
  region = "ca-central-1"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

### CATEGORY: IAM ###

data "aws_iam_policy_document" "flow_log_flowlog-to-cw_st_VPC-FlowLogs-Setup_doc" {
  statement {
    sid       = "AllowFlowLogDelivery"
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:DescribeLogStreams", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.flowlogs-cw.arn}:*"]
  }
}

resource "aws_iam_policy" "flow_log_flowlog-to-cw_st_VPC-FlowLogs-Setup" {
  name        = "flow_log_flowlog-to-cw_st_VPC-FlowLogs-Setup"
  description = "Access Policy for flowlog-to-cw"
  policy      = data.aws_iam_policy_document.flow_log_flowlog-to-cw_st_VPC-FlowLogs-Setup_doc.json
}

data "aws_iam_policy_document" "kinesis_firehose_delivery_stream_flowlogs-firehose_st_VPC-FlowLogs-Setup_doc" {
  statement {
    sid       = "AllowBucketLevelActions"
    effect    = "Allow"
    actions   = ["s3:GetBucketLocation", "s3:ListBucket", "s3:ListBucketMultipartUploads"]
    resources = [aws_s3_bucket.flowlogs-bucket.arn]
  }
  statement {
    sid       = "AllowObjectDelivery"
    effect    = "Allow"
    actions   = ["s3:AbortMultipartUpload", "s3:GetObject", "s3:PutObject"]
    resources = ["${aws_s3_bucket.flowlogs-bucket.arn}/*"]
  }
}

resource "aws_iam_policy" "kinesis_firehose_delivery_stream_flowlogs-firehose_st_VPC-FlowLogs-Setup" {
  name        = "kinesis_firehose_delivery_stream_flowlogs-firehose_st_VPC-FlowLogs-Setup"
  description = "Access Policy for flowlogs-firehose"
  policy      = data.aws_iam_policy_document.kinesis_firehose_delivery_stream_flowlogs-firehose_st_VPC-FlowLogs-Setup_doc.json
}

resource "aws_iam_role" "flowlogs-firehose_role" {
  name = "flowlogs-firehose_role"
  assume_role_policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": "firehose.amazonaws.com"
      }
    }
  ]
})
  force_detach_policies = false
  max_session_duration  = 3600
  path                  = "/"
  tags = {
    Name           = "flowlogs-firehose_role"
    State          = "VPC-FlowLogs-Setup"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "role_flow_log_flowlog-to-cw" {
  name = "role_flow_log_flowlog-to-cw"
  assume_role_policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": "vpc-flow-logs.amazonaws.com"
      }
    }
  ]
})
  tags = {
    Name           = "role_flow_log_flowlog-to-cw"
    State          = "VPC-FlowLogs-Setup"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role_policy_attachment" "flow_log_flowlog-to-cw_st_VPC-FlowLogs-Setup_attach" {
  policy_arn = aws_iam_policy.flow_log_flowlog-to-cw_st_VPC-FlowLogs-Setup.arn
  role       = aws_iam_role.role_flow_log_flowlog-to-cw.name
}

resource "aws_iam_role_policy_attachment" "kinesis_firehose_delivery_stream_flowlogs-firehose_st_VPC-FlowLogs-Setup_attach" {
  policy_arn = aws_iam_policy.kinesis_firehose_delivery_stream_flowlogs-firehose_st_VPC-FlowLogs-Setup.arn
  role       = aws_iam_role.flowlogs-firehose_role.name
}




### CATEGORY: NETWORK ###

resource "aws_vpc" "vpc-flowlog" {
  cidr_block       = "10.3.0.0/16"
  instance_tenancy = "default"
  tags = {
    Name           = "vpc-flowlog"
    State          = "VPC-FlowLogs-Setup"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "private-subnet" {
  vpc_id                  = aws_vpc.vpc-flowlog.id
  availability_zone       = "ca-central-1a"
  cidr_block              = "10.3.0.16/28"
  map_public_ip_on_launch = false
  tags = {
    Name           = "private-subnet"
    State          = "VPC-FlowLogs-Setup"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "public-subnet" {
  vpc_id                  = aws_vpc.vpc-flowlog.id
  availability_zone       = "ca-central-1a"
  cidr_block              = "10.3.0.0/28"
  map_public_ip_on_launch = true
  tags = {
    Name           = "public-subnet"
    State          = "VPC-FlowLogs-Setup"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_flow_log" "flowlog-to-cw" {
  vpc_id               = aws_vpc.vpc-flowlog.id
  iam_role_arn         = aws_iam_role.role_flow_log_flowlog-to-cw.arn
  log_destination      = aws_cloudwatch_log_group.flowlogs-cw.arn
  log_destination_type = "cloud-watch-logs"
  traffic_type         = "ALL"
  tags = {
    Name           = "flowlog-to-cw"
    State          = "VPC-FlowLogs-Setup"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_iam_role_policy_attachment.flow_log_flowlog-to-cw_st_VPC-FlowLogs-Setup_attach]
}

resource "aws_flow_log" "flowlog-to-firehose" {
  vpc_id               = aws_vpc.vpc-flowlog.id
  log_destination      = aws_kinesis_firehose_delivery_stream.flowlogs-firehose.arn
  log_destination_type = "kinesis-data-firehose"
  traffic_type         = "ALL"
  tags = {
    Name           = "flowlog-to-firehose"
    State          = "VPC-FlowLogs-Setup"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_flow_log" "flowlog-to-s3" {
  vpc_id               = aws_vpc.vpc-flowlog.id
  log_destination      = aws_s3_bucket.flowlogs-bucket.arn
  log_destination_type = "s3"
  traffic_type         = "ALL"
  tags = {
    Name           = "flowlog-to-s3"
    State          = "VPC-FlowLogs-Setup"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_s3_bucket_policy.aws_s3_bucket_policy_flowlogs-bucket_st_VPC-FlowLogs-Setup]
}




### CATEGORY: STORAGE ###

resource "aws_s3_bucket" "flowlogs-bucket" {
  bucket              = "flowlogs-bucket-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.region}-an"
  bucket_namespace    = "account-regional"
  force_destroy       = true
  object_lock_enabled = false
  tags = {
    Name           = "flowlogs-bucket"
    State          = "VPC-FlowLogs-Setup"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "lifecycle-expire-1day" {
  bucket = aws_s3_bucket.flowlogs-bucket.id
  rule {
    id     = "expire-logs"
    status = "Enabled"
    expiration {
      days = 1
    }
  }
}

resource "aws_s3_bucket_ownership_controls" "flowlogs-bucket_controls" {
  bucket = aws_s3_bucket.flowlogs-bucket.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

data "aws_iam_policy_document" "aws_s3_bucket_policy_flowlogs-bucket_st_VPC-FlowLogs-Setup_doc" {
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

resource "aws_s3_bucket_policy" "aws_s3_bucket_policy_flowlogs-bucket_st_VPC-FlowLogs-Setup" {
  bucket = aws_s3_bucket.flowlogs-bucket.id
  policy = data.aws_iam_policy_document.aws_s3_bucket_policy_flowlogs-bucket_st_VPC-FlowLogs-Setup_doc.json
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




### CATEGORY: INTEGRATION ###

resource "aws_kinesis_firehose_delivery_stream" "flowlogs-firehose" {
  name        = "flowlogs-firehose"
  destination = "extended_s3"
  extended_s3_configuration {
    bucket_arn         = aws_s3_bucket.flowlogs-bucket.arn
    compression_format = "GZIP"
    role_arn           = aws_iam_role.flowlogs-firehose_role.arn
  }
  tags = {
    Name           = "flowlogs-firehose"
    State          = "VPC-FlowLogs-Setup"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_iam_role_policy_attachment.kinesis_firehose_delivery_stream_flowlogs-firehose_st_VPC-FlowLogs-Setup_attach]
}




### CATEGORY: MONITORING ###

resource "aws_cloudwatch_log_group" "flowlogs-cw" {
  name              = "/aws/ec2/flowlog-to-cw"
  log_group_class   = "STANDARD"
  retention_in_days = 1
  skip_destroy      = false
  tags = {
    Name           = "flowlogs-cw"
    State          = "VPC-FlowLogs-Setup"
    Struct8Creator = "Contato Struct"
  }
}


