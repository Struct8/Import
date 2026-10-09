terraform {
  required_providers {
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

resource "aws_iam_role_policy" "Struct8Debug-Debug1_policy" {
  name   = "Struct8Debug-2zeRq_EaN5iT0PSAbe6RL-policy"
  policy = data.aws_iam_policy_document.Debug1_debug_permissions.json
  role   = aws_iam_role.Struct8Debug-Debug1.id
}

resource "aws_iam_role_policy_attachment" "AmazonSSMManagedInstanceCore_to_k6Generator_attach" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.k6Generator_role.name
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


