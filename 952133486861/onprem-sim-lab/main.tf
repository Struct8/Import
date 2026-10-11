terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  backend "s3" {
    bucket  = "struct8-import"
    key     = "952133486861/onprem-sim-lab/main.tfstate"
    region  = "us-west-2"
    encrypt = true
  }
}

# --- Main Cloud Provider ---
provider "aws" {
  region = "us-east-2"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

### CATEGORY: IAM ###

resource "aws_iam_instance_profile" "onprem-sim-router_profile" {
  name = "onprem-sim-router_profile"
  role = aws_iam_role.onprem-sim-router_role.name
  tags = {
    Name           = "onprem-sim-router_profile"
    State          = "onprem-sim-lab"
    Struct8Creator = "Contato Struct"
  }
}

data "aws_iam_policy_document" "debug-onprem-sim_debug_permissions" {
  statement {
    sid       = "SendToTaggedInstancesOnly"
    effect    = "Allow"
    actions   = ["ssm:SendCommand"]
    resources = ["arn:aws:ec2:*:*:instance/*"]
    condition {
      test     = "StringEquals"
      values   = ["d435000a-517c-47a2-ba23-b8bbbcc1f695"]
      variable = "aws:ResourceTag/Struct8Debug"
    }
  }
  statement {
    sid       = "PinnedDocumentOnly"
    effect    = "Allow"
    actions   = ["ssm:SendCommand"]
    resources = ["arn:aws:ssm:*:${data.aws_caller_identity.current.account_id}:document/Struct8Probe-d435000a-517c-47a2-ba23-b8bbbcc1f695"]
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
      values   = ["d435000a-517c-47a2-ba23-b8bbbcc1f695"]
      variable = "aws:ResourceTag/Struct8Debug"
    }
  }
}

data "aws_iam_policy_document" "debug-onprem-sim_debug_trust" {
  statement {
    effect = "Allow"
    principals {
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/CrossAccountStruct8"]
      type        = "AWS"
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "Struct8Debug-debug-onprem-sim" {
  name                 = "Struct8Debug-d435000a-517c-47a2-ba23-b8bbbcc1f695"
  assume_role_policy   = data.aws_iam_policy_document.debug-onprem-sim_debug_trust.json
  max_session_duration = 3600
}

resource "aws_iam_role" "onprem-sim-router_role" {
  name = "onprem-sim-router_role"
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
    Name           = "onprem-sim-router_role"
    State          = "onprem-sim-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role_policy" "Struct8Debug-debug-onprem-sim_policy" {
  name   = "Struct8Debug-d435000a-517c-47a2-ba23-b8bbbcc1f695-policy"
  policy = data.aws_iam_policy_document.debug-onprem-sim_debug_permissions.json
  role   = aws_iam_role.Struct8Debug-debug-onprem-sim.id
}

resource "aws_iam_role_policy_attachment" "AmazonSSMManagedInstanceCore_to_onprem-sim-router_attach" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.onprem-sim-router_role.name
}




### CATEGORY: NETWORK ###

resource "aws_vpc" "onprem-sim-vpc" {
  cidr_block           = "192.168.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default"
  tags = {
    Name           = "onprem-sim-vpc"
    State          = "onprem-sim-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "onprem-sim-public-a" {
  vpc_id                  = aws_vpc.onprem-sim-vpc.id
  availability_zone       = "us-east-2a"
  cidr_block              = "192.168.0.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name           = "onprem-sim-public-a"
    State          = "onprem-sim-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_internet_gateway" "onprem-sim-igw" {
  vpc_id = aws_vpc.onprem-sim-vpc.id
  tags = {
    Name           = "onprem-sim-igw"
    State          = "onprem-sim-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route" "route_onprem-sim-rt_to_onprem-sim-igw_ipv4" {
  gateway_id             = aws_internet_gateway.onprem-sim-igw.id
  route_table_id         = aws_route_table.onprem-sim-rt.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table" "onprem-sim-rt" {
  vpc_id = aws_vpc.onprem-sim-vpc.id
  tags = {
    Name           = "onprem-sim-rt"
    State          = "onprem-sim-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route_table_association" "aws_route_table_association_onprem_sim_public_a_onprem_sim_rt" {
  route_table_id = aws_route_table.onprem-sim-rt.id
  subnet_id      = aws_subnet.onprem-sim-public-a.id
}

resource "aws_security_group" "instance_onprem-sim-router_group" {
  name                   = "instance_onprem-sim-router_group"
  vpc_id                 = aws_vpc.onprem-sim-vpc.id
  description            = "On-premises router of the VPN test"
  revoke_rules_on_delete = false
  tags = {
    Name           = "instance_onprem-sim-router_group"
    State          = "onprem-sim-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group_rule" "rule_instance_onprem_sim_router_group_egress_all_protocols" {
  security_group_id = aws_security_group.instance_onprem-sim-router_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "rule_instance_onprem_sim_router_group_ingress_50_0" {
  security_group_id = aws_security_group.instance_onprem-sim-router_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "ESP"
  from_port         = 0
  protocol          = "50"
  to_port           = 0
  type              = "ingress"
}

resource "aws_security_group_rule" "rule_instance_onprem_sim_router_group_ingress_icmp__1" {
  security_group_id = aws_security_group.instance_onprem-sim-router_group.id
  cidr_blocks       = ["10.0.0.0/8"]
  description       = "Ping from the lab VPCs"
  from_port         = -1
  protocol          = "icmp"
  to_port           = -1
  type              = "ingress"
}

resource "aws_security_group_rule" "rule_instance_onprem_sim_router_group_ingress_udp_4500" {
  security_group_id = aws_security_group.instance_onprem-sim-router_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "IPsec NAT-T"
  from_port         = 4500
  protocol          = "udp"
  to_port           = 4500
  type              = "ingress"
}

resource "aws_security_group_rule" "rule_instance_onprem_sim_router_group_ingress_udp_500" {
  security_group_id = aws_security_group.instance_onprem-sim-router_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "IKE"
  from_port         = 500
  protocol          = "udp"
  to_port           = 500
  type              = "ingress"
}

resource "aws_eip" "onprem-sim-eip" {
  instance = aws_instance.onprem-sim-router.id
  tags = {
    Name           = "onprem-sim-eip"
    State          = "onprem-sim-lab"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_internet_gateway.onprem-sim-igw]
}




### CATEGORY: COMPUTE ###

data "aws_ami" "AMI_Data_Source_onprem-sim-router" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-arm64-server-*"]
  }
}

resource "aws_instance" "onprem-sim-router" {
  subnet_id                   = aws_subnet.onprem-sim-public-a.id
  ami                         = data.aws_ami.AMI_Data_Source_onprem-sim-router.id
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.onprem-sim-router_profile.name
  instance_type               = "t4g.small"
  source_dest_check           = false
  vpc_security_group_ids      = [aws_security_group.instance_onprem-sim-router_group.id]
  lifecycle {
    ignore_changes = [user_data]
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
    Struct8Debug   = "d435000a-517c-47a2-ba23-b8bbbcc1f695"
    Name           = "onprem-sim-router"
    State          = "onprem-sim-lab"
    Struct8Creator = "Contato Struct"
  }
}




### CATEGORY: CONFIG ###

resource "aws_ssm_document" "Struct8Probe-debug-onprem-sim" {
  name = "Struct8Probe-d435000a-517c-47a2-ba23-b8bbbcc1f695"
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


