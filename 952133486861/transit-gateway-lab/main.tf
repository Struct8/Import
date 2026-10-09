terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  backend "s3" {
    bucket  = "struct8-import"
    key     = "952133486861/transit-gateway-lab/main.tfstate"
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

resource "aws_iam_instance_profile" "spoke1-test_profile" {
  name = "spoke1-test_profile"
  role = aws_iam_role.spoke1-test_role.name
  tags = {
    Name           = "spoke1-test_profile"
    State          = "transit-gateway-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_instance_profile" "spoke2-test_profile" {
  name = "spoke2-test_profile"
  role = aws_iam_role.spoke2-test_role.name
  tags = {
    Name           = "spoke2-test_profile"
    State          = "transit-gateway-lab"
    Struct8Creator = "Contato Struct"
  }
}

data "aws_iam_policy_document" "debug-spoke-1_debug_permissions" {
  statement {
    sid       = "SendToTaggedInstancesOnly"
    effect    = "Allow"
    actions   = ["ssm:SendCommand"]
    resources = ["arn:aws:ec2:*:*:instance/*"]
    condition {
      test     = "StringEquals"
      values   = ["1777769e-5891-4b59-ba1b-e5964cef20eb"]
      variable = "aws:ResourceTag/Struct8Debug"
    }
  }
  statement {
    sid       = "PinnedDocumentOnly"
    effect    = "Allow"
    actions   = ["ssm:SendCommand"]
    resources = ["arn:aws:ssm:*:${data.aws_caller_identity.current.account_id}:document/Struct8Probe-1777769e-5891-4b59-ba1b-e5964cef20eb"]
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
      values   = ["1777769e-5891-4b59-ba1b-e5964cef20eb"]
      variable = "aws:ResourceTag/Struct8Debug"
    }
  }
}

data "aws_iam_policy_document" "debug-spoke-1_debug_trust" {
  statement {
    effect = "Allow"
    principals {
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/CrossAccountStruct8"]
      type        = "AWS"
    }
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "debug-spoke-2_debug_permissions" {
  statement {
    sid       = "SendToTaggedInstancesOnly"
    effect    = "Allow"
    actions   = ["ssm:SendCommand"]
    resources = ["arn:aws:ec2:*:*:instance/*"]
    condition {
      test     = "StringEquals"
      values   = ["991eeb51-f267-4468-b9a1-668aac78d0a0"]
      variable = "aws:ResourceTag/Struct8Debug"
    }
  }
  statement {
    sid       = "PinnedDocumentOnly"
    effect    = "Allow"
    actions   = ["ssm:SendCommand"]
    resources = ["arn:aws:ssm:*:${data.aws_caller_identity.current.account_id}:document/Struct8Probe-991eeb51-f267-4468-b9a1-668aac78d0a0"]
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
      values   = ["991eeb51-f267-4468-b9a1-668aac78d0a0"]
      variable = "aws:ResourceTag/Struct8Debug"
    }
  }
}

data "aws_iam_policy_document" "debug-spoke-2_debug_trust" {
  statement {
    effect = "Allow"
    principals {
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/CrossAccountStruct8"]
      type        = "AWS"
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "Struct8Debug-debug-spoke-1" {
  name                 = "Struct8Debug-1777769e-5891-4b59-ba1b-e5964cef20eb"
  assume_role_policy   = data.aws_iam_policy_document.debug-spoke-1_debug_trust.json
  max_session_duration = 3600
}

resource "aws_iam_role" "Struct8Debug-debug-spoke-2" {
  name                 = "Struct8Debug-991eeb51-f267-4468-b9a1-668aac78d0a0"
  assume_role_policy   = data.aws_iam_policy_document.debug-spoke-2_debug_trust.json
  max_session_duration = 3600
}

resource "aws_iam_role" "spoke1-test_role" {
  name = "spoke1-test_role"
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
    Name           = "spoke1-test_role"
    State          = "transit-gateway-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "spoke2-test_role" {
  name = "spoke2-test_role"
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
    Name           = "spoke2-test_role"
    State          = "transit-gateway-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role_policy" "Struct8Debug-debug-spoke-1_policy" {
  name   = "Struct8Debug-1777769e-5891-4b59-ba1b-e5964cef20eb-policy"
  policy = data.aws_iam_policy_document.debug-spoke-1_debug_permissions.json
  role   = aws_iam_role.Struct8Debug-debug-spoke-1.id
}

resource "aws_iam_role_policy" "Struct8Debug-debug-spoke-2_policy" {
  name   = "Struct8Debug-991eeb51-f267-4468-b9a1-668aac78d0a0-policy"
  policy = data.aws_iam_policy_document.debug-spoke-2_debug_permissions.json
  role   = aws_iam_role.Struct8Debug-debug-spoke-2.id
}

resource "aws_iam_role_policy_attachment" "AmazonSSMManagedInstanceCore_to_spoke1-test_attach" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.spoke1-test_role.name
}

resource "aws_iam_role_policy_attachment" "AmazonSSMManagedInstanceCore_to_spoke2-test_attach" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.spoke2-test_role.name
}




### CATEGORY: NETWORK ###

resource "aws_vpc" "vpc-hub" {
  cidr_block           = "10.30.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default"
  tags = {
    Name           = "vpc-hub"
    State          = "transit-gateway-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_vpc" "vpc-spoke-1" {
  cidr_block           = "10.2.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default"
  tags = {
    Name           = "vpc-spoke-1"
    State          = "transit-gateway-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_vpc" "vpc-spoke-2" {
  cidr_block           = "10.6.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default"
  tags = {
    Name           = "vpc-spoke-2"
    State          = "transit-gateway-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_vpc_endpoint" "spoke1-gateway-endpoints_DynamoDB" {
  service_name      = "com.amazonaws.us-west-2.dynamodb"
  vpc_id            = aws_vpc.vpc-spoke-1.id
  route_table_ids   = [aws_route_table.rt-spoke-1.id]
  vpc_endpoint_type = "Gateway"
  tags = {
    DifName        = "spoke1-gateway-endpoints_DynamoDB"
    Name           = "spoke1-gateway-endpoints"
    State          = "transit-gateway-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_vpc_endpoint" "spoke1-gateway-endpoints_S3" {
  service_name      = "com.amazonaws.us-west-2.s3"
  vpc_id            = aws_vpc.vpc-spoke-1.id
  route_table_ids   = [aws_route_table.rt-spoke-1.id]
  vpc_endpoint_type = "Gateway"
  tags = {
    DifName        = "spoke1-gateway-endpoints_S3"
    Name           = "spoke1-gateway-endpoints"
    State          = "transit-gateway-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_vpc_endpoint" "spoke2-gateway-endpoints_DynamoDB" {
  service_name      = "com.amazonaws.us-west-2.dynamodb"
  vpc_id            = aws_vpc.vpc-spoke-2.id
  route_table_ids   = [aws_route_table.rt-spoke-2.id]
  vpc_endpoint_type = "Gateway"
  tags = {
    DifName        = "spoke2-gateway-endpoints_DynamoDB"
    Name           = "spoke2-gateway-endpoints"
    State          = "transit-gateway-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_vpc_endpoint" "spoke2-gateway-endpoints_S3" {
  service_name      = "com.amazonaws.us-west-2.s3"
  vpc_id            = aws_vpc.vpc-spoke-2.id
  route_table_ids   = [aws_route_table.rt-spoke-2.id]
  vpc_endpoint_type = "Gateway"
  tags = {
    DifName        = "spoke2-gateway-endpoints_S3"
    Name           = "spoke2-gateway-endpoints"
    State          = "transit-gateway-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "Subnet" {
  vpc_id                  = aws_vpc.vpc-hub.id
  availability_zone       = "us-west-2a"
  cidr_block              = "10.30.0.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name           = "Subnet"
    State          = "transit-gateway-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "hub-public-b" {
  vpc_id                  = aws_vpc.vpc-hub.id
  availability_zone       = "us-west-2b"
  cidr_block              = "10.30.1.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name           = "hub-public-b"
    State          = "transit-gateway-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "hub-public-c" {
  vpc_id                  = aws_vpc.vpc-hub.id
  availability_zone       = "us-west-2c"
  cidr_block              = "10.30.2.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name           = "hub-public-c"
    State          = "transit-gateway-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "hub-tgw-a" {
  vpc_id                  = aws_vpc.vpc-hub.id
  availability_zone       = "us-west-2a"
  cidr_block              = "10.30.100.0/28"
  map_public_ip_on_launch = false
  tags = {
    Name           = "hub-tgw-a"
    State          = "transit-gateway-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "hub-tgw-b" {
  vpc_id                  = aws_vpc.vpc-hub.id
  availability_zone       = "us-west-2b"
  cidr_block              = "10.30.100.16/28"
  map_public_ip_on_launch = false
  tags = {
    Name           = "hub-tgw-b"
    State          = "transit-gateway-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "hub-tgw-c" {
  vpc_id                  = aws_vpc.vpc-hub.id
  availability_zone       = "us-west-2c"
  cidr_block              = "10.30.100.32/28"
  map_public_ip_on_launch = false
  tags = {
    Name           = "hub-tgw-c"
    State          = "transit-gateway-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "spoke1-a" {
  vpc_id                  = aws_vpc.vpc-spoke-1.id
  availability_zone       = "us-west-2a"
  cidr_block              = "10.2.0.0/24"
  map_public_ip_on_launch = false
  tags = {
    Name           = "spoke1-a"
    State          = "transit-gateway-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "spoke1-b" {
  vpc_id                  = aws_vpc.vpc-spoke-1.id
  availability_zone       = "us-west-2b"
  cidr_block              = "10.2.1.0/24"
  map_public_ip_on_launch = false
  tags = {
    Name           = "spoke1-b"
    State          = "transit-gateway-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "spoke1-c" {
  vpc_id                  = aws_vpc.vpc-spoke-1.id
  availability_zone       = "us-west-2c"
  cidr_block              = "10.2.2.0/24"
  map_public_ip_on_launch = false
  tags = {
    Name           = "spoke1-c"
    State          = "transit-gateway-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "spoke2-a" {
  vpc_id                  = aws_vpc.vpc-spoke-2.id
  availability_zone       = "us-west-2a"
  cidr_block              = "10.6.0.0/24"
  map_public_ip_on_launch = false
  tags = {
    Name           = "spoke2-a"
    State          = "transit-gateway-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "spoke2-b" {
  vpc_id                  = aws_vpc.vpc-spoke-2.id
  availability_zone       = "us-west-2b"
  cidr_block              = "10.6.1.0/24"
  map_public_ip_on_launch = false
  tags = {
    Name           = "spoke2-b"
    State          = "transit-gateway-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "spoke2-c" {
  vpc_id                  = aws_vpc.vpc-spoke-2.id
  availability_zone       = "us-west-2c"
  cidr_block              = "10.6.2.0/24"
  map_public_ip_on_launch = false
  tags = {
    Name           = "spoke2-c"
    State          = "transit-gateway-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_internet_gateway" "IGW" {
  vpc_id = aws_vpc.vpc-hub.id
  tags = {
    Name           = "IGW"
    State          = "transit-gateway-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_nat_gateway" "NAT1" {
  vpc_id            = aws_vpc.vpc-hub.id
  availability_mode = "regional"
  connectivity_type = "public"
  tags = {
    Name           = "NAT1"
    State          = "transit-gateway-lab"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_internet_gateway.IGW]
}

resource "aws_route" "route_NAT1_to_tgw-lab_ipv4" {
  route_table_id         = aws_nat_gateway.NAT1.route_table_id
  transit_gateway_id     = aws_ec2_transit_gateway.tgw-lab.id
  destination_cidr_block = "10.0.0.0/8"
  depends_on             = [aws_ec2_transit_gateway_vpc_attachment.att-hub]
}

resource "aws_route" "route_RT_to_IGW_ipv4" {
  gateway_id             = aws_internet_gateway.IGW.id
  route_table_id         = aws_route_table.RT.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route" "route_RT_to_tgw-lab_ipv4" {
  route_table_id         = aws_route_table.RT.id
  transit_gateway_id     = aws_ec2_transit_gateway.tgw-lab.id
  destination_cidr_block = "10.0.0.0/8"
  depends_on             = [aws_ec2_transit_gateway_vpc_attachment.att-hub]
}

resource "aws_route" "route_rt-hub-tgw-a_to_NAT1_ipv4" {
  nat_gateway_id         = aws_nat_gateway.NAT1.id
  route_table_id         = aws_route_table.rt-hub-tgw-a.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route" "route_rt-hub-tgw-b_to_NAT1_ipv4" {
  nat_gateway_id         = aws_nat_gateway.NAT1.id
  route_table_id         = aws_route_table.rt-hub-tgw-b.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route" "route_rt-hub-tgw-c_to_NAT1_ipv4" {
  nat_gateway_id         = aws_nat_gateway.NAT1.id
  route_table_id         = aws_route_table.rt-hub-tgw-c.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route" "route_rt-spoke-1_to_tgw-lab_ipv4" {
  route_table_id         = aws_route_table.rt-spoke-1.id
  transit_gateway_id     = aws_ec2_transit_gateway.tgw-lab.id
  destination_cidr_block = "0.0.0.0/0"
  depends_on             = [aws_ec2_transit_gateway_vpc_attachment.att-spoke-1]
}

resource "aws_route" "route_rt-spoke-2_to_tgw-lab_ipv4" {
  route_table_id         = aws_route_table.rt-spoke-2.id
  transit_gateway_id     = aws_ec2_transit_gateway.tgw-lab.id
  destination_cidr_block = "0.0.0.0/0"
  depends_on             = [aws_ec2_transit_gateway_vpc_attachment.att-spoke-2]
}

resource "aws_route_table" "RT" {
  vpc_id = aws_vpc.vpc-hub.id
  tags = {
    Name           = "RT"
    State          = "transit-gateway-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route_table" "rt-hub-tgw-a" {
  vpc_id = aws_vpc.vpc-hub.id
  tags = {
    Name           = "rt-hub-tgw-a"
    State          = "transit-gateway-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route_table" "rt-hub-tgw-b" {
  vpc_id = aws_vpc.vpc-hub.id
  tags = {
    Name           = "rt-hub-tgw-b"
    State          = "transit-gateway-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route_table" "rt-hub-tgw-c" {
  vpc_id = aws_vpc.vpc-hub.id
  tags = {
    Name           = "rt-hub-tgw-c"
    State          = "transit-gateway-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route_table" "rt-spoke-1" {
  vpc_id = aws_vpc.vpc-spoke-1.id
  tags = {
    Name           = "rt-spoke-1"
    State          = "transit-gateway-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route_table" "rt-spoke-2" {
  vpc_id = aws_vpc.vpc-spoke-2.id
  tags = {
    Name           = "rt-spoke-2"
    State          = "transit-gateway-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route_table_association" "aws_route_table_association_Subnet_RT" {
  route_table_id = aws_route_table.RT.id
  subnet_id      = aws_subnet.Subnet.id
}

resource "aws_route_table_association" "aws_route_table_association_hub_public_b_RT" {
  route_table_id = aws_route_table.RT.id
  subnet_id      = aws_subnet.hub-public-b.id
}

resource "aws_route_table_association" "aws_route_table_association_hub_public_c_RT" {
  route_table_id = aws_route_table.RT.id
  subnet_id      = aws_subnet.hub-public-c.id
}

resource "aws_route_table_association" "aws_route_table_association_hub_tgw_a_rt_hub_tgw_a" {
  route_table_id = aws_route_table.rt-hub-tgw-a.id
  subnet_id      = aws_subnet.hub-tgw-a.id
}

resource "aws_route_table_association" "aws_route_table_association_hub_tgw_b_rt_hub_tgw_b" {
  route_table_id = aws_route_table.rt-hub-tgw-b.id
  subnet_id      = aws_subnet.hub-tgw-b.id
}

resource "aws_route_table_association" "aws_route_table_association_hub_tgw_c_rt_hub_tgw_c" {
  route_table_id = aws_route_table.rt-hub-tgw-c.id
  subnet_id      = aws_subnet.hub-tgw-c.id
}

resource "aws_route_table_association" "aws_route_table_association_spoke1_a_rt_spoke_1" {
  route_table_id = aws_route_table.rt-spoke-1.id
  subnet_id      = aws_subnet.spoke1-a.id
}

resource "aws_route_table_association" "aws_route_table_association_spoke1_b_rt_spoke_1" {
  route_table_id = aws_route_table.rt-spoke-1.id
  subnet_id      = aws_subnet.spoke1-b.id
}

resource "aws_route_table_association" "aws_route_table_association_spoke1_c_rt_spoke_1" {
  route_table_id = aws_route_table.rt-spoke-1.id
  subnet_id      = aws_subnet.spoke1-c.id
}

resource "aws_route_table_association" "aws_route_table_association_spoke2_a_rt_spoke_2" {
  route_table_id = aws_route_table.rt-spoke-2.id
  subnet_id      = aws_subnet.spoke2-a.id
}

resource "aws_route_table_association" "aws_route_table_association_spoke2_b_rt_spoke_2" {
  route_table_id = aws_route_table.rt-spoke-2.id
  subnet_id      = aws_subnet.spoke2-b.id
}

resource "aws_route_table_association" "aws_route_table_association_spoke2_c_rt_spoke_2" {
  route_table_id = aws_route_table.rt-spoke-2.id
  subnet_id      = aws_subnet.spoke2-c.id
}

resource "aws_security_group" "instance_spoke1-test_group" {
  name                   = "instance_spoke1-test_group"
  vpc_id                 = aws_vpc.vpc-spoke-1.id
  description            = "Test instance of the transit gateway lab"
  revoke_rules_on_delete = false
  tags = {
    Name           = "instance_spoke1-test_group"
    State          = "transit-gateway-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group" "instance_spoke2-test_group" {
  name                   = "instance_spoke2-test_group"
  vpc_id                 = aws_vpc.vpc-spoke-2.id
  description            = "Test instance of the transit gateway lab"
  revoke_rules_on_delete = false
  tags = {
    Name           = "instance_spoke2-test_group"
    State          = "transit-gateway-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group_rule" "rule_instance_spoke1_test_group_egress_all_protocols" {
  security_group_id = aws_security_group.instance_spoke1-test_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "rule_instance_spoke1_test_group_ingress_icmp__1" {
  security_group_id = aws_security_group.instance_spoke1-test_group.id
  cidr_blocks       = ["10.0.0.0/8"]
  description       = "Ping from the other VPCs of the lab"
  from_port         = -1
  protocol          = "icmp"
  to_port           = -1
  type              = "ingress"
}

resource "aws_security_group_rule" "rule_instance_spoke2_test_group_egress_all_protocols" {
  security_group_id = aws_security_group.instance_spoke2-test_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "rule_instance_spoke2_test_group_ingress_icmp__1" {
  security_group_id = aws_security_group.instance_spoke2-test_group.id
  cidr_blocks       = ["10.0.0.0/8"]
  description       = "Ping from the other VPCs of the lab"
  from_port         = -1
  protocol          = "icmp"
  to_port           = -1
  type              = "ingress"
}

resource "aws_ec2_transit_gateway" "tgw-lab" {
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  description                     = "Hub and spoke with centralized egress through vpc-hub"
  tags = {
    Name           = "tgw-lab"
    State          = "transit-gateway-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_ec2_transit_gateway_route" "tgw-rt-spokes_att-hub_0_0_0_0_0" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.att-hub.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw-rt-spokes.id
  destination_cidr_block         = "0.0.0.0/0"
}

resource "aws_ec2_transit_gateway_route" "tgw-rt-spokes_blackhole_10_0_0_0_8" {
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw-rt-spokes.id
  blackhole                      = true
  destination_cidr_block         = "10.0.0.0/8"
}

resource "aws_ec2_transit_gateway_route_table" "tgw-rt-hub" {
  transit_gateway_id = aws_ec2_transit_gateway.tgw-lab.id
  tags = {
    Name           = "tgw-rt-hub"
    State          = "transit-gateway-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_ec2_transit_gateway_route_table" "tgw-rt-spokes" {
  transit_gateway_id = aws_ec2_transit_gateway.tgw-lab.id
  tags = {
    Name           = "tgw-rt-spokes"
    State          = "transit-gateway-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_ec2_transit_gateway_route_table_association" "att-hub_tgw-rt-hub_association" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.att-hub.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw-rt-hub.id
}

resource "aws_ec2_transit_gateway_route_table_association" "att-spoke-1_tgw-rt-spokes_association" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.att-spoke-1.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw-rt-spokes.id
}

resource "aws_ec2_transit_gateway_route_table_association" "att-spoke-2_tgw-rt-spokes_association" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.att-spoke-2.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw-rt-spokes.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "att-hub_tgw-rt-spokes_propagation" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.att-hub.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw-rt-spokes.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "att-spoke-1_tgw-rt-hub_propagation" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.att-spoke-1.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw-rt-hub.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "att-spoke-2_tgw-rt-hub_propagation" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.att-spoke-2.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw-rt-hub.id
}

resource "aws_ec2_transit_gateway_vpc_attachment" "att-hub" {
  transit_gateway_id                              = aws_ec2_transit_gateway.tgw-lab.id
  vpc_id                                          = aws_vpc.vpc-hub.id
  subnet_ids                                      = [aws_subnet.hub-tgw-a.id, aws_subnet.hub-tgw-b.id, aws_subnet.hub-tgw-c.id]
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
  tags = {
    Name           = "att-hub"
    State          = "transit-gateway-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "att-spoke-1" {
  transit_gateway_id                              = aws_ec2_transit_gateway.tgw-lab.id
  vpc_id                                          = aws_vpc.vpc-spoke-1.id
  subnet_ids                                      = [aws_subnet.spoke1-a.id, aws_subnet.spoke1-b.id, aws_subnet.spoke1-c.id]
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
  tags = {
    Name           = "att-spoke-1"
    State          = "transit-gateway-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "att-spoke-2" {
  transit_gateway_id                              = aws_ec2_transit_gateway.tgw-lab.id
  vpc_id                                          = aws_vpc.vpc-spoke-2.id
  subnet_ids                                      = [aws_subnet.spoke2-a.id, aws_subnet.spoke2-b.id, aws_subnet.spoke2-c.id]
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
  tags = {
    Name           = "att-spoke-2"
    State          = "transit-gateway-lab"
    Struct8Creator = "Contato Struct"
  }
}




### CATEGORY: COMPUTE ###

data "aws_ami" "AMI_Data_Source_spoke1-test" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-kernel-6.1-arm64"]
  }
}

resource "aws_instance" "spoke1-test" {
  subnet_id                   = aws_subnet.spoke1-a.id
  ami                         = data.aws_ami.AMI_Data_Source_spoke1-test.id
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.spoke1-test_profile.name
  instance_type               = "t4g.nano"
  vpc_security_group_ids      = [aws_security_group.instance_spoke1-test_group.id]
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
    Struct8Debug   = "1777769e-5891-4b59-ba1b-e5964cef20eb"
    Name           = "spoke1-test"
    State          = "transit-gateway-lab"
    Struct8Creator = "Contato Struct"
  }
}

data "aws_ami" "AMI_Data_Source_spoke2-test" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-kernel-6.1-arm64"]
  }
}

resource "aws_instance" "spoke2-test" {
  subnet_id                   = aws_subnet.spoke2-a.id
  ami                         = data.aws_ami.AMI_Data_Source_spoke2-test.id
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.spoke2-test_profile.name
  instance_type               = "t4g.nano"
  vpc_security_group_ids      = [aws_security_group.instance_spoke2-test_group.id]
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
    Struct8Debug   = "991eeb51-f267-4468-b9a1-668aac78d0a0"
    Name           = "spoke2-test"
    State          = "transit-gateway-lab"
    Struct8Creator = "Contato Struct"
  }
}




### CATEGORY: CONFIG ###

resource "aws_ssm_document" "Struct8Probe-debug-spoke-1" {
  name = "Struct8Probe-1777769e-5891-4b59-ba1b-e5964cef20eb"
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

resource "aws_ssm_document" "Struct8Probe-debug-spoke-2" {
  name = "Struct8Probe-991eeb51-f267-4468-b9a1-668aac78d0a0"
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


