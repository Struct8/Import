terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  backend "s3" {
    bucket  = "struct8-import"
    key     = "952133486861/k6-panel-lab-state/main.tfstate"
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

resource "aws_iam_instance_profile" "k6-panel-lab-hub_profile" {
  name = "k6-panel-lab-hub_profile"
  role = aws_iam_role.k6-panel-lab-hub_role.name
  tags = {
    Name           = "k6-panel-lab-hub_profile"
    State          = "k6-panel-lab-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_instance_profile" "k6-panel-lab-k6_profile" {
  name = "k6-panel-lab-k6_profile"
  role = aws_iam_role.k6-panel-lab-k6_role.name
  tags = {
    Name           = "k6-panel-lab-k6_profile"
    State          = "k6-panel-lab-state"
    Struct8Creator = "Contato Struct"
  }
}

data "aws_iam_policy_document" "Debug_debug_permissions" {
  statement {
    sid       = "SendToTaggedInstancesOnly"
    effect    = "Allow"
    actions   = ["ssm:SendCommand"]
    resources = ["arn:aws:ec2:*:*:instance/*"]
    condition {
      test     = "StringEquals"
      values   = ["KYsrC0bRmz41-VA-uqMQq"]
      variable = "aws:ResourceTag/Struct8Debug"
    }
  }
  statement {
    sid       = "PinnedDocumentOnly"
    effect    = "Allow"
    actions   = ["ssm:SendCommand"]
    resources = ["arn:aws:ssm:*::document/AWS-RunShellScript"]
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
      values   = ["KYsrC0bRmz41-VA-uqMQq"]
      variable = "aws:ResourceTag/Struct8Debug"
    }
  }
  statement {
    sid       = "RunShellScriptDocument"
    effect    = "Allow"
    actions   = ["ssm:SendCommand"]
    resources = ["arn:aws:ssm:*::document/AWS-RunShellScript"]
  }
}

data "aws_iam_policy_document" "Debug_debug_trust" {
  statement {
    effect = "Allow"
    principals {
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/CrossAccountStruct8"]
      type        = "AWS"
    }
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "k6-panel-lab-debug_debug_permissions" {
  statement {
    sid       = "SendToTaggedInstancesOnly"
    effect    = "Allow"
    actions   = ["ssm:SendCommand"]
    resources = ["arn:aws:ec2:*:*:instance/*"]
    condition {
      test     = "StringEquals"
      values   = ["d07f5910-819b-4296-ac0b-7176473864d5"]
      variable = "aws:ResourceTag/Struct8Debug"
    }
  }
  statement {
    sid       = "PinnedDocumentOnly"
    effect    = "Allow"
    actions   = ["ssm:SendCommand"]
    resources = ["arn:aws:ssm:*::document/AWS-RunShellScript"]
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
      values   = ["d07f5910-819b-4296-ac0b-7176473864d5"]
      variable = "aws:ResourceTag/Struct8Debug"
    }
  }
  statement {
    sid       = "RunShellScriptDocument"
    effect    = "Allow"
    actions   = ["ssm:SendCommand"]
    resources = ["arn:aws:ssm:*::document/AWS-RunShellScript"]
  }
}

data "aws_iam_policy_document" "k6-panel-lab-debug_debug_trust" {
  statement {
    effect = "Allow"
    principals {
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/CrossAccountStruct8"]
      type        = "AWS"
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "Struct8Debug-Debug" {
  name                 = "Struct8Debug-KYsrC0bRmz41-VA-uqMQq"
  assume_role_policy   = data.aws_iam_policy_document.Debug_debug_trust.json
  max_session_duration = 3600
}

resource "aws_iam_role" "Struct8Debug-k6-panel-lab-debug" {
  name                 = "Struct8Debug-d07f5910-819b-4296-ac0b-7176473864d5"
  assume_role_policy   = data.aws_iam_policy_document.k6-panel-lab-debug_debug_trust.json
  max_session_duration = 3600
}

resource "aws_iam_role" "k6-panel-lab-hub_role" {
  name = "k6-panel-lab-hub_role"
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
    Name           = "k6-panel-lab-hub_role"
    State          = "k6-panel-lab-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "k6-panel-lab-k6_role" {
  name = "k6-panel-lab-k6_role"
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
    Name           = "k6-panel-lab-k6_role"
    State          = "k6-panel-lab-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role_policy" "Struct8Debug-Debug_policy" {
  name   = "Struct8Debug-KYsrC0bRmz41-VA-uqMQq-policy"
  policy = data.aws_iam_policy_document.Debug_debug_permissions.json
  role   = aws_iam_role.Struct8Debug-Debug.id
}

resource "aws_iam_role_policy" "Struct8Debug-k6-panel-lab-debug_policy" {
  name   = "Struct8Debug-d07f5910-819b-4296-ac0b-7176473864d5-policy"
  policy = data.aws_iam_policy_document.k6-panel-lab-debug_debug_permissions.json
  role   = aws_iam_role.Struct8Debug-k6-panel-lab-debug.id
}

resource "aws_iam_role_policy_attachment" "AmazonSSMManagedInstanceCore_to_k6-panel-lab-hub_attach" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.k6-panel-lab-hub_role.name
}

resource "aws_iam_role_policy_attachment" "AmazonSSMManagedInstanceCore_to_k6-panel-lab-k6_attach" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.k6-panel-lab-k6_role.name
}




### CATEGORY: NETWORK ###

resource "aws_vpc" "k6-panel-lab" {
  cidr_block           = "10.8.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default"
  tags = {
    Name           = "k6-panel-lab"
    State          = "k6-panel-lab-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "k6-panel-lab-public-a" {
  vpc_id                  = aws_vpc.k6-panel-lab.id
  availability_zone       = "us-west-2a"
  cidr_block              = "10.8.1.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name           = "k6-panel-lab-public-a"
    State          = "k6-panel-lab-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_internet_gateway" "k6-panel-lab-igw" {
  vpc_id = aws_vpc.k6-panel-lab.id
  tags = {
    Name           = "k6-panel-lab-igw"
    State          = "k6-panel-lab-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route" "route_k6-panel-lab-rtb-public_to_k6-panel-lab-igw_ipv4" {
  gateway_id             = aws_internet_gateway.k6-panel-lab-igw.id
  route_table_id         = aws_route_table.k6-panel-lab-rtb-public.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route" "route_k6-panel-lab-rtb-public_to_k6-panel-lab-igw_ipv6" {
  gateway_id                  = aws_internet_gateway.k6-panel-lab-igw.id
  route_table_id              = aws_route_table.k6-panel-lab-rtb-public.id
  destination_ipv6_cidr_block = "::/0"
}

resource "aws_route_table" "k6-panel-lab-rtb-public" {
  vpc_id = aws_vpc.k6-panel-lab.id
  tags = {
    Name           = "k6-panel-lab-rtb-public"
    State          = "k6-panel-lab-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route_table_association" "aws_route_table_association_k6_panel_lab_public_a_k6_panel_lab_rtb_public" {
  route_table_id = aws_route_table.k6-panel-lab-rtb-public.id
  subnet_id      = aws_subnet.k6-panel-lab-public-a.id
}

resource "aws_security_group" "instance_k6-panel-lab-hub_group" {
  name                   = "instance_k6-panel-lab-hub_group"
  vpc_id                 = aws_vpc.k6-panel-lab.id
  revoke_rules_on_delete = false
  tags = {
    Name           = "instance_k6-panel-lab-hub_group"
    State          = "k6-panel-lab-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group" "instance_k6-panel-lab-k6_group" {
  name                   = "instance_k6-panel-lab-k6_group"
  vpc_id                 = aws_vpc.k6-panel-lab.id
  revoke_rules_on_delete = false
  tags = {
    Name           = "instance_k6-panel-lab-k6_group"
    State          = "k6-panel-lab-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group_rule" "rule_instance_k6_panel_lab_hub_group_egress_all_protocols" {
  security_group_id = aws_security_group.instance_k6-panel-lab-hub_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "rule_instance_k6_panel_lab_k6_group_egress_all_protocols" {
  security_group_id = aws_security_group.instance_k6-panel-lab-k6_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "rule_instance_k6_panel_lab_k6_group_ingress_tcp_5665" {
  security_group_id = aws_security_group.instance_k6-panel-lab-k6_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "k6 live dashboard (teaching lab)"
  from_port         = 5665
  protocol          = "tcp"
  to_port           = 5665
  type              = "ingress"
}

resource "aws_security_group_rule" "rule_instance_k6_panel_lab_k6_group_ingress_tcp_80" {
  security_group_id = aws_security_group.instance_k6-panel-lab-k6_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "k6 control panel (teaching lab)"
  from_port         = 80
  protocol          = "tcp"
  to_port           = 80
  type              = "ingress"
}

resource "aws_security_group_rule" "rule_instance_k6_panel_lab_k6_group_to_instance_k6_panel_lab_hub_group_tcp_8080" {
  security_group_id        = aws_security_group.instance_k6-panel-lab-hub_group.id
  source_security_group_id = aws_security_group.instance_k6-panel-lab-k6_group.id
  description              = "k6 load generator to Hub"
  from_port                = 8080
  protocol                 = "tcp"
  to_port                  = 8080
  type                     = "ingress"
}




### CATEGORY: COMPUTE ###

data "local_file" "UserData_k6-panel-lab-hub" {
  filename = "${path.module}/.external_modules/struct8-templates/templates/ec2-hub-docker/v1/user_data/hub-docker.sh"
}

data "aws_ami" "AMI_Data_Source_k6-panel-lab-hub" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-kernel-6.1-arm64"]
  }
}

resource "aws_instance" "k6-panel-lab-hub" {
  subnet_id                   = aws_subnet.k6-panel-lab-public-a.id
  ami                         = data.aws_ami.AMI_Data_Source_k6-panel-lab-hub.id
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.k6-panel-lab-hub_profile.name
  instance_type               = "t4g.nano"
  monitoring                  = true
  private_ip                  = "10.8.1.10"
  user_data_base64 = base64encode(<<-EOFUData
#!/bin/bash

# --- BEGIN STRUCT8 VARIABLES ---
cat << 'EOFENV' > /etc/struct8_env
HUB_LOADTEST="on"
NAME="k6-panel-lab-hub"
REGION="${data.aws_region.current.region}"
ACCOUNT="${data.aws_caller_identity.current.account_id}"
EOFENV
cat /etc/struct8_env >> /etc/environment
sed 's/^/export /' /etc/struct8_env > /etc/profile.d/struct8_vars.sh
chmod +x /etc/profile.d/struct8_vars.sh
chmod 644 /etc/struct8_env
# --- END STRUCT8 VARIABLES ---

${data.local_file.UserData_k6-panel-lab-hub.content}
EOFUData
)
  vpc_security_group_ids = [aws_security_group.instance_k6-panel-lab-hub_group.id]
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
    Struct8Debug   = "d07f5910-819b-4296-ac0b-7176473864d5"
    Name           = "k6-panel-lab-hub"
    State          = "k6-panel-lab-state"
    Struct8Creator = "Contato Struct"
  }
}

data "local_file" "UserData_k6-panel-lab-k6" {
  filename = "${path.module}/.external_modules/struct8-templates/templates/vpc-k6-load-generator/v2/user_data/k6-bootstrap.sh"
}

data "aws_ami" "AMI_Data_Source_k6-panel-lab-k6" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-kernel-6.1-arm64"]
  }
}

resource "aws_instance" "k6-panel-lab-k6" {
  subnet_id                   = aws_subnet.k6-panel-lab-public-a.id
  ami                         = data.aws_ami.AMI_Data_Source_k6-panel-lab-k6.id
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.k6-panel-lab-k6_profile.name
  instance_type               = "t4g.nano"
  user_data_base64 = base64encode(<<-EOFUData
#!/bin/bash

# --- BEGIN STRUCT8 VARIABLES ---
cat << 'EOFENV' > /etc/struct8_env
K6_PANEL="on"
K6_PANEL_REF="main"
K6_PANEL_MAX_VUS="200"
NAME="k6-panel-lab-k6"
REGION="${data.aws_region.current.region}"
ACCOUNT="${data.aws_caller_identity.current.account_id}"
AWS_INSTANCE_NAME_0="k6-panel-lab-hub"
EOFENV
cat /etc/struct8_env >> /etc/environment
sed 's/^/export /' /etc/struct8_env > /etc/profile.d/struct8_vars.sh
chmod +x /etc/profile.d/struct8_vars.sh
chmod 644 /etc/struct8_env
# --- END STRUCT8 VARIABLES ---

${data.local_file.UserData_k6-panel-lab-k6.content}
EOFUData
)
  vpc_security_group_ids = [aws_security_group.instance_k6-panel-lab-k6_group.id]
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
    Struct8Debug   = "KYsrC0bRmz41-VA-uqMQq"
    Name           = "k6-panel-lab-k6"
    State          = "k6-panel-lab-state"
    Struct8Creator = "Contato Struct"
  }
}


