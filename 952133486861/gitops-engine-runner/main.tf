terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  backend "s3" {
    bucket  = "struct8-import"
    key     = "952133486861/gitops-engine-runner/main.tfstate"
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

### CATEGORY: IAM ###

resource "aws_iam_instance_profile" "engine-runner-nat_profile" {
  name = "engine-runner-nat_profile"
  role = aws_iam_role.engine-runner-nat_role.name
  tags = {
    Name           = "engine-runner-nat_profile"
    State          = "gitops-engine-runner"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_instance_profile" "engine-runner_profile" {
  name = "engine-runner_profile"
  role = aws_iam_role.engine-runner_role.name
  tags = {
    Name           = "engine-runner_profile"
    State          = "gitops-engine-runner"
    Struct8Creator = "Contato Struct"
  }
}

data "aws_iam_policy_document" "iam_instance_profile_engine-runner_profile_st_gitops-engine-runner_doc" {
  statement {
    sid       = "SessionManagerOnly"
    effect    = "Allow"
    actions   = ["ssm:UpdateInstanceInformation", "ssmmessages:CreateControlChannel", "ssmmessages:CreateDataChannel", "ssmmessages:OpenControlChannel", "ssmmessages:OpenDataChannel"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "iam_instance_profile_engine-runner_profile_st_gitops-engine-runner" {
  name        = "iam_instance_profile_engine-runner_profile_st_gitops-engine-runner"
  description = "Access Policy for engine-runner_profile"
  policy      = data.aws_iam_policy_document.iam_instance_profile_engine-runner_profile_st_gitops-engine-runner_doc.json
}

data "aws_iam_policy_document" "iam_role_engine-runner_role_st_gitops-engine-runner_doc" {
  statement {
    sid       = "SessionManagerOnly"
    effect    = "Allow"
    actions   = ["ssm:UpdateInstanceInformation", "ssmmessages:CreateControlChannel", "ssmmessages:CreateDataChannel", "ssmmessages:OpenControlChannel", "ssmmessages:OpenDataChannel"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "iam_role_engine-runner_role_st_gitops-engine-runner" {
  name        = "iam_role_engine-runner_role_st_gitops-engine-runner"
  description = "Access Policy for engine-runner_role"
  policy      = data.aws_iam_policy_document.iam_role_engine-runner_role_st_gitops-engine-runner_doc.json
}

data "aws_iam_policy_document" "instance_engine-runner_st_gitops-engine-runner_doc" {
  statement {
    sid       = "ReadRegistrationToken"
    effect    = "Allow"
    actions   = ["ssm:GetParameter"]
    resources = [aws_ssm_parameter.gitops-engine-runner-token.arn]
  }
  statement {
    sid       = "AllowSecureStringDecrypt"
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = ["*"]
    condition {
      test     = "StringLike"
      values   = ["ssm.*.amazonaws.com"]
      variable = "kms:ViaService"
    }
  }
  statement {
    sid       = "SessionManagerOnly"
    effect    = "Allow"
    actions   = ["ssm:UpdateInstanceInformation", "ssmmessages:CreateControlChannel", "ssmmessages:CreateDataChannel", "ssmmessages:OpenControlChannel", "ssmmessages:OpenDataChannel"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "instance_engine-runner_st_gitops-engine-runner" {
  name        = "instance_engine-runner_st_gitops-engine-runner"
  description = "Access Policy for engine-runner"
  policy      = data.aws_iam_policy_document.instance_engine-runner_st_gitops-engine-runner_doc.json
}

data "aws_iam_policy_document" "debug-engine-runner-nat_debug_permissions" {
  statement {
    sid       = "SendToTaggedInstancesOnly"
    effect    = "Allow"
    actions   = ["ssm:SendCommand"]
    resources = ["arn:aws:ec2:*:*:instance/*"]
    condition {
      test     = "StringEquals"
      values   = ["4a231453-be2a-4a2c-ae3a-174780612260"]
      variable = "aws:ResourceTag/Struct8Debug"
    }
  }
  statement {
    sid       = "PinnedDocumentOnly"
    effect    = "Allow"
    actions   = ["ssm:SendCommand"]
    resources = ["arn:aws:ssm:*:${data.aws_caller_identity.current.account_id}:document/Struct8Probe-4a231453-be2a-4a2c-ae3a-174780612260"]
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
      values   = ["4a231453-be2a-4a2c-ae3a-174780612260"]
      variable = "aws:ResourceTag/Struct8Debug"
    }
  }
}

data "aws_iam_policy_document" "debug-engine-runner-nat_debug_trust" {
  statement {
    effect = "Allow"
    principals {
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/CrossAccountStruct8"]
      type        = "AWS"
    }
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "debug-engine-runner_debug_permissions" {
  statement {
    sid       = "SendToTaggedInstancesOnly"
    effect    = "Allow"
    actions   = ["ssm:SendCommand"]
    resources = ["arn:aws:ec2:*:*:instance/*"]
    condition {
      test     = "StringEquals"
      values   = ["1db1b76c-3d3c-4d58-b68a-4d3c6ec487d6"]
      variable = "aws:ResourceTag/Struct8Debug"
    }
  }
  statement {
    sid       = "PinnedDocumentOnly"
    effect    = "Allow"
    actions   = ["ssm:SendCommand"]
    resources = ["arn:aws:ssm:*:${data.aws_caller_identity.current.account_id}:document/Struct8Probe-1db1b76c-3d3c-4d58-b68a-4d3c6ec487d6"]
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
      values   = ["1db1b76c-3d3c-4d58-b68a-4d3c6ec487d6"]
      variable = "aws:ResourceTag/Struct8Debug"
    }
  }
}

data "aws_iam_policy_document" "debug-engine-runner_debug_trust" {
  statement {
    effect = "Allow"
    principals {
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/CrossAccountStruct8"]
      type        = "AWS"
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "Struct8Debug-debug-engine-runner" {
  name                 = "Struct8Debug-1db1b76c-3d3c-4d58-b68a-4d3c6ec487d6"
  assume_role_policy   = data.aws_iam_policy_document.debug-engine-runner_debug_trust.json
  max_session_duration = 3600
}

resource "aws_iam_role" "Struct8Debug-debug-engine-runner-nat" {
  name                 = "Struct8Debug-4a231453-be2a-4a2c-ae3a-174780612260"
  assume_role_policy   = data.aws_iam_policy_document.debug-engine-runner-nat_debug_trust.json
  max_session_duration = 3600
}

resource "aws_iam_role" "engine-runner-nat_role" {
  name = "engine-runner-nat_role"
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
    Name           = "engine-runner-nat_role"
    State          = "gitops-engine-runner"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "engine-runner_role" {
  name = "engine-runner_role"
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
    Name           = "engine-runner_role"
    State          = "gitops-engine-runner"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role_policy" "Struct8Debug-debug-engine-runner-nat_policy" {
  name   = "Struct8Debug-4a231453-be2a-4a2c-ae3a-174780612260-policy"
  policy = data.aws_iam_policy_document.debug-engine-runner-nat_debug_permissions.json
  role   = aws_iam_role.Struct8Debug-debug-engine-runner-nat.id
}

resource "aws_iam_role_policy" "Struct8Debug-debug-engine-runner_policy" {
  name   = "Struct8Debug-1db1b76c-3d3c-4d58-b68a-4d3c6ec487d6-policy"
  policy = data.aws_iam_policy_document.debug-engine-runner_debug_permissions.json
  role   = aws_iam_role.Struct8Debug-debug-engine-runner.id
}

resource "aws_iam_role_policy_attachment" "AmazonSSMManagedInstanceCore_to_engine-runner-nat_attach" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.engine-runner-nat_role.name
}

resource "aws_iam_role_policy_attachment" "AmazonSSMManagedInstanceCore_to_engine-runner_attach" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.engine-runner_role.name
}

resource "aws_iam_role_policy_attachment" "iam_instance_profile_engine-runner_profile_st_gitops-engine-runner_attach" {
  policy_arn = aws_iam_policy.iam_instance_profile_engine-runner_profile_st_gitops-engine-runner.arn
  role       = aws_iam_role.engine-runner_role.name
}

resource "aws_iam_role_policy_attachment" "instance_engine-runner_st_gitops-engine-runner_attach" {
  policy_arn = aws_iam_policy.instance_engine-runner_st_gitops-engine-runner.arn
  role       = aws_iam_role.engine-runner_role.name
}




### CATEGORY: NETWORK ###

resource "aws_vpc" "gitops-engine-runner" {
  cidr_block           = "10.2.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default"
  tags = {
    Name           = "gitops-engine-runner"
    State          = "gitops-engine-runner"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_vpc_endpoint" "vpce-runner-s3_S3" {
  service_name      = "com.amazonaws.us-west-2.s3"
  vpc_id            = aws_vpc.gitops-engine-runner.id
  route_table_ids   = [aws_route_table.rtb-runner-private.id]
  vpc_endpoint_type = "Gateway"
  tags = {
    DifName        = "vpce-runner-s3_S3"
    Name           = "vpce-runner-s3"
    State          = "gitops-engine-runner"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "snet-private" {
  vpc_id                  = aws_vpc.gitops-engine-runner.id
  availability_zone       = "us-west-2a"
  cidr_block              = "10.2.1.0/24"
  map_public_ip_on_launch = false
  tags = {
    Name           = "snet-private"
    State          = "gitops-engine-runner"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "snet-public" {
  vpc_id                  = aws_vpc.gitops-engine-runner.id
  availability_zone       = "us-west-2a"
  cidr_block              = "10.2.0.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name           = "snet-public"
    State          = "gitops-engine-runner"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.gitops-engine-runner.id
  tags = {
    Name           = "igw"
    State          = "gitops-engine-runner"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route" "route_rtb-runner-private_to_engine-runner-nat_ipv4" {
  network_interface_id   = aws_instance.engine-runner-nat.primary_network_interface_id
  route_table_id         = aws_route_table.rtb-runner-private.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route" "route_rtb-runner-public_to_igw_ipv4" {
  gateway_id             = aws_internet_gateway.igw.id
  route_table_id         = aws_route_table.rtb-runner-public.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table" "rtb-runner-private" {
  vpc_id = aws_vpc.gitops-engine-runner.id
  tags = {
    Name           = "rtb-runner-private"
    State          = "gitops-engine-runner"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route_table" "rtb-runner-public" {
  vpc_id = aws_vpc.gitops-engine-runner.id
  tags = {
    Name           = "rtb-runner-public"
    State          = "gitops-engine-runner"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route_table_association" "aws_route_table_association_snet_private_rtb_runner_private" {
  route_table_id = aws_route_table.rtb-runner-private.id
  subnet_id      = aws_subnet.snet-private.id
}

resource "aws_route_table_association" "aws_route_table_association_snet_public_rtb_runner_public" {
  route_table_id = aws_route_table.rtb-runner-public.id
  subnet_id      = aws_subnet.snet-public.id
}

resource "aws_security_group" "instance_engine-runner-nat_group" {
  name                   = "instance_engine-runner-nat_group"
  vpc_id                 = aws_vpc.gitops-engine-runner.id
  description            = "NAT instance. Accepts all traffic from the private subnet so it can masquerade its outbound traffic. No other inbound rules."
  revoke_rules_on_delete = false
  tags = {
    Name           = "instance_engine-runner-nat_group"
    State          = "gitops-engine-runner"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group" "instance_engine-runner_group" {
  name                   = "instance_engine-runner_group"
  vpc_id                 = aws_vpc.gitops-engine-runner.id
  description            = "GitOps engine runner. No inbound rules; outbound only, through the NAT instance."
  revoke_rules_on_delete = false
  tags = {
    Name           = "instance_engine-runner_group"
    State          = "gitops-engine-runner"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group_rule" "rule_instance_engine_runner_group_egress_all_protocols" {
  security_group_id = aws_security_group.instance_engine-runner_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "rule_instance_engine_runner_nat_group_egress_all_protocols" {
  security_group_id = aws_security_group.instance_engine-runner-nat_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "rule_instance_engine_runner_nat_group_ingress_all_protocols" {
  security_group_id = aws_security_group.instance_engine-runner-nat_group.id
  cidr_blocks       = ["10.2.1.0/24"]
  description       = "From the private subnet, to be routed out"
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "ingress"
}

resource "aws_eip" "eip-nat" {
  instance = aws_instance.engine-runner-nat.id
  tags = {
    Name           = "eip-nat"
    State          = "gitops-engine-runner"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_internet_gateway.igw]
}




### CATEGORY: COMPUTE ###

data "local_file" "UserData_engine-runner" {
  filename = "${path.module}/.external_modules/struct8-templates/templates/gitops-engine-runner/v1/user_data/runner.sh"
}

data "aws_ami" "AMI_Data_Source_engine-runner" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-arm64-server-*"]
  }
}

resource "aws_instance" "engine-runner" {
  subnet_id                   = aws_subnet.snet-private.id
  ami                         = data.aws_ami.AMI_Data_Source_engine-runner.id
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.engine-runner_profile.name
  instance_type               = "t4g.micro"
  user_data_base64 = base64encode(<<-EOFUData
#!/bin/bash

# --- BEGIN STRUCT8 VARIABLES ---
cat << 'EOFENV' > /etc/struct8_env
RUNNER_GITHUB_REPOSITORY="OWNER/REPOSITORY"
RUNNER_LABEL="struct8-engine"
NAME="engine-runner"
REGION="${data.aws_region.current.region}"
ACCOUNT="${data.aws_caller_identity.current.account_id}"
AWS_SSM_PARAMETER_NAME_0="gitops-engine-runner-token"
EOFENV
cat /etc/struct8_env >> /etc/environment
sed 's/^/export /' /etc/struct8_env > /etc/profile.d/struct8_vars.sh
chmod +x /etc/profile.d/struct8_vars.sh
chmod 644 /etc/struct8_env
# --- END STRUCT8 VARIABLES ---

${data.local_file.UserData_engine-runner.content}
EOFUData
)
  vpc_security_group_ids = [aws_security_group.instance_engine-runner_group.id]
  lifecycle {
    create_before_destroy = false
    ignore_changes        = [ami, user_data_base64]
    prevent_destroy       = false
  }
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
  root_block_device {
    encrypted   = true
    iops        = 3000
    throughput  = 125
    volume_size = 30
    volume_type = "gp3"
  }
  tags = {
    Struct8Debug   = "1db1b76c-3d3c-4d58-b68a-4d3c6ec487d6"
    Name           = "engine-runner"
    State          = "gitops-engine-runner"
    Struct8Creator = "Contato Struct"
  }
}

data "local_file" "UserData_engine-runner-nat" {
  filename = "${path.module}/.external_modules/struct8-templates/templates/gitops-engine-runner/v1/user_data/nat.sh"
}

data "aws_ami" "AMI_Data_Source_engine-runner-nat" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-minimal-2023.*-kernel-6.1-arm64"]
  }
}

resource "aws_instance" "engine-runner-nat" {
  subnet_id                   = aws_subnet.snet-public.id
  ami                         = data.aws_ami.AMI_Data_Source_engine-runner-nat.id
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.engine-runner-nat_profile.name
  instance_type               = "t4g.nano"
  source_dest_check           = false
  user_data_base64 = base64encode(<<-EOFUData
#!/bin/bash

${data.local_file.UserData_engine-runner-nat.content}
EOFUData
)
  vpc_security_group_ids = [aws_security_group.instance_engine-runner-nat_group.id]
  lifecycle {
    create_before_destroy = false
    ignore_changes        = [ami, user_data_base64]
    prevent_destroy       = false
  }
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
    Struct8Debug   = "4a231453-be2a-4a2c-ae3a-174780612260"
    Name           = "engine-runner-nat"
    State          = "gitops-engine-runner"
    Struct8Creator = "Contato Struct"
  }
}




### CATEGORY: CONFIG ###

resource "aws_ssm_document" "Struct8Probe-debug-engine-runner" {
  name = "Struct8Probe-1db1b76c-3d3c-4d58-b68a-4d3c6ec487d6"
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

resource "aws_ssm_document" "Struct8Probe-debug-engine-runner-nat" {
  name = "Struct8Probe-4a231453-be2a-4a2c-ae3a-174780612260"
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

resource "aws_ssm_parameter" "gitops-engine-runner-token" {
  name      = "gitops-engine-runner-token"
  data_type = "text"
  overwrite = false
  tier      = "Standard"
  type      = "SecureString"
  value     = "paste-the-token-here"
  lifecycle {
    create_before_destroy = false
    ignore_changes        = [value]
    prevent_destroy       = false
  }
  tags = {
    Name           = "gitops-engine-runner-token"
    State          = "gitops-engine-runner"
    Struct8Creator = "Contato Struct"
  }
}


