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

resource "aws_iam_instance_profile" "Instance_flow_logs_profile" {
  name = "Instance_flow_logs_profile"
  role = aws_iam_role.Instance_flow_logs_role.name
  tags = {
    Name           = "Instance_flow_logs_profile"
    State          = "VPC-FlowLogs-Setup"
    Struct8Creator = "Contato Struct"
  }
}

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

resource "aws_iam_role" "Instance_flow_logs_role" {
  name = "Instance_flow_logs_role"
  assume_role_policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      }
    }
  ]
})
  force_detach_policies = false
  max_session_duration  = 3600
  path                  = "/"
  tags = {
    Name           = "Instance_flow_logs_role"
    State          = "VPC-FlowLogs-Setup"
    Struct8Creator = "Contato Struct"
  }
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
  assign_generated_ipv6_cidr_block = true
  cidr_block                       = "10.3.0.0/16"
  enable_dns_hostnames             = true
  enable_dns_support               = true
  instance_tenancy                 = "default"
  tags = {
    Name           = "vpc-flowlog"
    State          = "VPC-FlowLogs-Setup"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "private-subnet" {
  vpc_id                                         = aws_vpc.vpc-flowlog.id
  assign_ipv6_address_on_creation                = true
  availability_zone                              = "ca-central-1a"
  enable_resource_name_dns_aaaa_record_on_launch = true
  ipv6_cidr_block                                = cidrsubnet(aws_vpc.vpc-flowlog.ipv6_cidr_block, 8, 1)
  ipv6_native                                    = true
  private_dns_hostname_type_on_launch            = "resource-name"
  tags = {
    Name           = "private-subnet"
    State          = "VPC-FlowLogs-Setup"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "public-subnet" {
  vpc_id                                         = aws_vpc.vpc-flowlog.id
  assign_ipv6_address_on_creation                = true
  availability_zone                              = "ca-central-1a"
  enable_resource_name_dns_aaaa_record_on_launch = true
  ipv6_cidr_block                                = cidrsubnet(aws_vpc.vpc-flowlog.ipv6_cidr_block, 8, 0)
  ipv6_native                                    = true
  private_dns_hostname_type_on_launch            = "resource-name"
  tags = {
    Name           = "public-subnet"
    State          = "VPC-FlowLogs-Setup"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_internet_gateway" "flowlog-igw" {
  vpc_id = aws_vpc.vpc-flowlog.id
  tags = {
    Name           = "flowlog-igw"
    State          = "VPC-FlowLogs-Setup"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route" "route_public-rt_to_flowlog-igw_ipv6" {
  gateway_id                  = aws_internet_gateway.flowlog-igw.id
  route_table_id              = aws_route_table.public-rt.id
  destination_ipv6_cidr_block = "::/0"
}

resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.vpc-flowlog.id
  tags = {
    Name           = "public-rt"
    State          = "VPC-FlowLogs-Setup"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route_table_association" "aws_route_table_association_public_subnet_public_rt" {
  route_table_id = aws_route_table.public-rt.id
  subnet_id      = aws_subnet.public-subnet.id
}

resource "aws_security_group" "instance_Instance_flow_logs_group" {
  name                   = "instance_Instance_flow_logs_group"
  vpc_id                 = aws_vpc.vpc-flowlog.id
  revoke_rules_on_delete = false
  tags = {
    Name           = "instance_Instance_flow_logs_group"
    State          = "VPC-FlowLogs-Setup"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group_rule" "rule_instance_Instance_flow_logs_group_egress_all_protocols" {
  security_group_id = aws_security_group.instance_Instance_flow_logs_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  ipv6_cidr_blocks  = ["::/0"]
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
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
  subnet_id            = aws_subnet.public-subnet.id
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




### CATEGORY: COMPUTE ###

data "aws_ami" "AMI_Data_Source_Instance_flow_logs" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-kernel-6.1-x86_64"]
  }
}

resource "aws_instance" "Instance_flow_logs" {
  subnet_id                   = aws_subnet.public-subnet.id
  ami                         = data.aws_ami.AMI_Data_Source_Instance_flow_logs.id
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.Instance_flow_logs_profile.name
  instance_type               = "t3.nano"
  ipv6_address_count          = 1
  user_data_replace_on_change = false
  vpc_security_group_ids      = [aws_security_group.instance_Instance_flow_logs_group.id]
  lifecycle {
    ignore_changes = [user_data]
  }
  metadata_options {
    http_endpoint      = "enabled"
    http_protocol_ipv6 = "enabled"
    http_tokens        = "required"
  }
  root_block_device {
    encrypted   = true
    iops        = 3000
    throughput  = 125
    volume_size = 8
    volume_type = "gp3"
  }
  tags = {
    Name           = "Instance_flow_logs"
    State          = "VPC-FlowLogs-Setup"
    Struct8Creator = "Contato Struct"
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
    LogDeliveryEnabled = true
    Name               = "flowlogs-firehose"
    State              = "VPC-FlowLogs-Setup"
    Struct8Creator     = "Contato Struct"
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


