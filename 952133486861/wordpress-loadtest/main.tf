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
    key     = "952133486861/wordpress-loadtest/main.tfstate"
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

### SYSTEM DATA SOURCES ###

data "aws_route53_zone" "zoneWordpress" {
  name = "cloudman.pro"
}




### EXTERNAL REFERENCES ###

data "aws_vpc" "wordpress-professional" {
  filter {
    name   = "tag:Name"
    values = ["wordpress-professional"]
  }
}

data "aws_route_table" "rt-public-wp" {
  filter {
    name   = "tag:Name"
    values = ["rt-public-wp"]
  }
}




### CATEGORY: IAM ###

resource "aws_iam_instance_profile" "k6Generator_profile" {
  name = "k6Generator_profile"
  role = aws_iam_role.k6Generator_role.name
  tags = {
    Name           = "k6Generator_profile"
    State          = "wordpress-loadtest"
    Struct8Creator = "Contato Struct"
  }
}

data "aws_iam_policy_document" "synthetics_canary_wpReadCanary_st_wordpress-loadtest_doc" {
  statement {
    sid       = "AllowCanaryArtifactBucketLocation"
    effect    = "Allow"
    actions   = ["s3:GetBucketLocation"]
    resources = [aws_s3_bucket.canaryArtifacts.arn]
  }
  statement {
    sid       = "AllowCanaryArtifactObjects"
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject"]
    resources = ["${aws_s3_bucket.canaryArtifacts.arn}/*"]
  }
  statement {
    sid       = "CanaryMetrics"
    effect    = "Allow"
    actions   = ["cloudwatch:PutMetricData"]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "cloudwatch:namespace"
      values   = ["CloudWatchSynthetics"]
    }
  }
  statement {
    sid       = "CanaryListBuckets"
    effect    = "Allow"
    actions   = ["s3:ListAllMyBuckets"]
    resources = ["*"]
  }
  statement {
    sid       = "CanaryLogs"
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/cwsyn-*:*"]
  }
}

resource "aws_iam_policy" "synthetics_canary_wpReadCanary_st_wordpress-loadtest" {
  name        = "synthetics_canary_wpReadCanary_st_wordpress-loadtest"
  description = "Access Policy for wpReadCanary"
  policy      = data.aws_iam_policy_document.synthetics_canary_wpReadCanary_st_wordpress-loadtest_doc.json
}

data "aws_iam_policy_document" "Debug1_debug_permissions" {
  statement {
    sid       = "SendToTaggedInstancesOnly"
    effect    = "Allow"
    actions   = ["ssm:SendCommand"]
    resources = ["arn:aws:ec2:*:*:instance/*"]
    condition {
      test     = "StringEquals"
      values   = ["2zeRq_EaN5iT0PSAbe6RL"]
      variable = "aws:ResourceTag/Struct8Debug"
    }
  }
  statement {
    sid       = "PinnedDocumentOnly"
    effect    = "Allow"
    actions   = ["ssm:SendCommand"]
    resources = ["arn:aws:ssm:*:${data.aws_caller_identity.current.account_id}:document/Struct8Probe-2zeRq_EaN5iT0PSAbe6RL"]
  }
  statement {
    sid       = "ReadOwnResults"
    effect    = "Allow"
    actions   = ["ssm:GetCommandInvocation", "ssm:DescribeInstanceInformation"]
    resources = ["*"]
  }
  statement {
    sid       = "CancelOnTaggedInstancesOnly"
    effect    = "Allow"
    actions   = ["ssm:CancelCommand"]
    resources = ["arn:aws:ec2:*:*:instance/*"]
    condition {
      test     = "StringEquals"
      values   = ["2zeRq_EaN5iT0PSAbe6RL"]
      variable = "aws:ResourceTag/Struct8Debug"
    }
  }
}

data "aws_iam_policy_document" "Debug1_debug_trust" {
  statement {
    effect = "Allow"
    principals {
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/CrossAccountStruct8"]
      type        = "AWS"
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "Struct8Debug-Debug1" {
  name                 = "Struct8Debug-2zeRq_EaN5iT0PSAbe6RL"
  assume_role_policy   = data.aws_iam_policy_document.Debug1_debug_trust.json
  max_session_duration = 3600
}

resource "aws_iam_role" "k6Generator_role" {
  name = "k6Generator_role"
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
    Name           = "k6Generator_role"
    State          = "wordpress-loadtest"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "wpReadCanary_role" {
  name = "wpReadCanary_role"
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
    Name           = "wpReadCanary_role"
    State          = "wordpress-loadtest"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role_policy" "Struct8Debug-Debug1_policy" {
  name   = "Struct8Debug-2zeRq_EaN5iT0PSAbe6RL-policy"
  policy = data.aws_iam_policy_document.Debug1_debug_permissions.json
  role   = aws_iam_role.Struct8Debug-Debug1.id
}

resource "aws_iam_role_policy_attachment" "AmazonSSMManagedInstanceCore_to_k6Generator_attach" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.k6Generator_role.name
}

resource "aws_iam_role_policy_attachment" "synthetics_canary_wpReadCanary_st_wordpress-loadtest_attach" {
  policy_arn = aws_iam_policy.synthetics_canary_wpReadCanary_st_wordpress-loadtest.arn
  role       = aws_iam_role.wpReadCanary_role.name
}




### CATEGORY: NETWORK ###

resource "aws_subnet" "pubLoadTest" {
  vpc_id                  = data.aws_vpc.wordpress-professional.id
  availability_zone       = "us-west-2a"
  cidr_block              = "10.0.3.0/24"
  ipv6_cidr_block         = cidrsubnet(data.aws_vpc.wordpress-professional.ipv6_cidr_block, 8, 3)
  map_public_ip_on_launch = true
  tags = {
    Name           = "pubLoadTest"
    State          = "wordpress-loadtest"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route_table_association" "aws_route_table_association_pubLoadTest_rt_public_wp" {
  route_table_id = data.aws_route_table.rt-public-wp.id
  subnet_id      = aws_subnet.pubLoadTest.id
}

resource "aws_security_group" "instance_k6Generator_group" {
  name                   = "instance_k6Generator_group"
  vpc_id                 = data.aws_vpc.wordpress-professional.id
  revoke_rules_on_delete = false
  tags = {
    Name           = "instance_k6Generator_group"
    State          = "wordpress-loadtest"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group_rule" "rule_instance_k6Generator_group_egress_all_protocols" {
  security_group_id = aws_security_group.instance_k6Generator_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "rule_instance_k6Generator_group_ingress_tcp_5665" {
  security_group_id = aws_security_group.instance_k6Generator_group.id
  cidr_blocks       = ["45.166.205.227/32"]
  description       = "k6 web dashboard"
  from_port         = 5665
  protocol          = "tcp"
  to_port           = 5665
  type              = "ingress"
}

resource "aws_security_group_rule" "rule_instance_k6Generator_group_ingress_tcp_80" {
  security_group_id = aws_security_group.instance_k6Generator_group.id
  cidr_blocks       = ["45.166.205.227/32"]
  description       = "k6 panel"
  from_port         = 80
  protocol          = "tcp"
  to_port           = 80
  type              = "ingress"
}

resource "aws_eip" "eip-generator" {
  instance = aws_instance.k6Generator.id
  tags = {
    Name           = "eip-generator"
    State          = "wordpress-loadtest"
    Struct8Creator = "Contato Struct"
  }
}




### CATEGORY: STORAGE ###

resource "aws_s3_bucket" "canaryArtifacts" {
  bucket              = "canaryartifacts-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.region}-an"
  bucket_namespace    = "account-regional"
  force_destroy       = true
  object_lock_enabled = false
  tags = {
    Name           = "canaryArtifacts"
    State          = "wordpress-loadtest"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "canaryArtifacts_lifecycle" {
  bucket = aws_s3_bucket.canaryArtifacts.id
  rule {
    id     = "abort-incomplete-uploads"
    status = "Enabled"
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
    expiration {
      days                         = 15
      expired_object_delete_marker = false
    }
  }
}

resource "aws_s3_bucket_ownership_controls" "canaryArtifacts_controls" {
  bucket = aws_s3_bucket.canaryArtifacts.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "canaryArtifacts_block" {
  block_public_acls       = true
  block_public_policy     = true
  bucket                  = aws_s3_bucket.canaryArtifacts.id
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "canaryArtifacts_configuration" {
  bucket = aws_s3_bucket.canaryArtifacts.id
  rule {
    bucket_key_enabled = true
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "canaryArtifacts_versioning" {
  bucket = aws_s3_bucket.canaryArtifacts.id
  versioning_configuration {
    mfa_delete = "Disabled"
    status     = "Suspended"
  }
}




### CATEGORY: COMPUTE ###

data "local_file" "UserData_k6Generator" {
  filename = "${path.module}/.external_modules/struct8-templates/templates/vpc-k6-load-generator/v3/user_data/k6-bootstrap.sh"
}

data "aws_ami" "AMI_Data_Source_k6Generator" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-kernel-6.1-arm64"]
  }
}

resource "aws_instance" "k6Generator" {
  subnet_id                   = aws_subnet.pubLoadTest.id
  ami                         = data.aws_ami.AMI_Data_Source_k6Generator.id
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.k6Generator_profile.name
  instance_type               = "t4g.small"
  user_data_base64 = base64encode(<<-EOFUData
#!/bin/bash

# --- BEGIN STRUCT8 VARIABLES ---
cat << 'EOFENV' > /etc/struct8_env
K6_SCENARIO="wordpress"
K6_PANEL="on"
NAME="k6Generator"
REGION="${data.aws_region.current.region}"
ACCOUNT="${data.aws_caller_identity.current.account_id}"
TARGET_URL="https://wp.cloudman.pro/"
EOFENV
cat /etc/struct8_env >> /etc/environment
sed 's/^/export /' /etc/struct8_env > /etc/profile.d/struct8_vars.sh
chmod +x /etc/profile.d/struct8_vars.sh
chmod 644 /etc/struct8_env
# --- END STRUCT8 VARIABLES ---

${data.local_file.UserData_k6Generator.content}
EOFUData
)
  user_data_replace_on_change = true
  vpc_security_group_ids      = [aws_security_group.instance_k6Generator_group.id]
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
  root_block_device {
    encrypted   = true
    iops        = 3000
    throughput  = 125
    volume_size = 8
    volume_type = "gp3"
  }
  tags = {
    Struct8Debug   = "2zeRq_EaN5iT0PSAbe6RL"
    Name           = "k6Generator"
    State          = "wordpress-loadtest"
    Struct8Creator = "Contato Struct"
  }
}




### CATEGORY: MONITORING ###

resource "aws_cloudwatch_log_group" "wpReadCanaryLogs" {
  name              = "/aws/lambda/${element(split(":", aws_synthetics_canary.wpReadCanary.engine_arn), 6)}"
  log_group_class   = "STANDARD"
  retention_in_days = 30
  skip_destroy      = false
  tags = {
    Name           = "wpReadCanaryLogs"
    State          = "wordpress-loadtest"
    Struct8Creator = "Contato Struct"
  }
}

data "archive_file" "canary_struct8-templates_wpReadCanary" {
  output_path = "${path.module}/canary_struct8-templates_wpReadCanary_${substr(sha1(join(",", [for f in sort(fileset("${path.module}/.external_modules/struct8-templates/templates/wordpress-professional/v1/canary", "**")) : "${f}:${filesha1("${path.module}/.external_modules/struct8-templates/templates/wordpress-professional/v1/canary/${f}")}"])), 0, 16)}.zip"
  source_dir  = "${path.module}/.external_modules/struct8-templates/templates/wordpress-professional/v1/canary"
  type        = "zip"
}

resource "aws_synthetics_canary" "wpReadCanary" {
  name                 = "wpreadcanary"
  artifact_s3_location = "s3://${aws_s3_bucket.canaryArtifacts.bucket}/canary/wpreadcanary"
  delete_lambda        = true
  execution_role_arn   = aws_iam_role.wpReadCanary_role.arn
  handler              = "index.handler"
  runtime_version      = "syn-nodejs-playwright-9.0"
  start_canary         = true
  zip_file             = data.archive_file.canary_struct8-templates_wpReadCanary.output_path
  run_config {
    active_tracing     = false
    ephemeral_storage  = 1024
    memory_in_mb       = 960
    timeout_in_seconds = 120
    environment_variables = {
    NAME                 = "wpReadCanary"
    REGION               = data.aws_region.current.region
    ACCOUNT              = data.aws_caller_identity.current.account_id
    AWS_S3_BUCKET_NAME_0 = "canaryartifacts-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.region}-an"
    TARGET_URL           = "https://wp.cloudman.pro/"
  }
  }
  schedule {
    expression = "rate(5 minutes)"
    retry_config {
      max_retries = 0
    }
  }
  tags = {
    Name           = "wpReadCanary"
    State          = "wordpress-loadtest"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_iam_role_policy_attachment.synthetics_canary_wpReadCanary_st_wordpress-loadtest_attach]
}




### CATEGORY: CONFIG ###

resource "aws_ssm_document" "Struct8Probe-Debug1" {
  name = "Struct8Probe-2zeRq_EaN5iT0PSAbe6RL"
  content = <<EOF
{
  "schemaVersion": "2.2",
  "description": "Struct8 network probe. The command text is fixed here; the caller supplies only a target and a port.",
  "parameters": {
    "target": {
      "type": "String",
      "description": "Hostname or IP address to probe.",
      "interpolationType": "ENV_VAR",
      "allowedPattern": "^[A-Za-z0-9._-]{1,253}$"
    },
    "port": {
      "type": "String",
      "description": "TCP port to test.",
      "default": "443",
      "interpolationType": "ENV_VAR",
      "allowedPattern": "^[0-9]{1,5}$"
    }
  },
  "mainSteps": [
    {
      "action": "aws:runShellScript",
      "name": "struct8Probe",
      "inputs": {
        "timeoutSeconds": "60",
        "runCommand": [
          "if [ -z \"$SSM_target\" ]; then export SSM_target=\"{{target}}\"; fi",
          "if [ -z \"$SSM_port\" ]; then export SSM_port=\"{{port}}\"; fi",
          "echo '--- resolve ---'",
          "getent hosts \"$SSM_target\" || echo \"no DNS answer\"",
          "echo '--- icmp ---'",
          "ping -c 3 -W 2 \"$SSM_target\" || echo \"no ICMP reply (often filtered, not conclusive)\"",
          "echo '--- tcp ---'",
          "if timeout 5 bash -c 'exec 3<>/dev/tcp/\"$1\"/\"$2\"' _ \"$SSM_target\" \"$SSM_port\" 2>/dev/null; then echo \"port $SSM_port open\"; else echo \"port $SSM_port closed or filtered\"; fi"
        ]
      }
    }
  ]
}
  EOF
  document_format = "JSON"
  document_type   = "Command"
}


