terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  backend "s3" {
    bucket  = "struct8-import"
    key     = "952133486861/State3/main.tfstate"
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

data "aws_vpc_endpoint_service" "gwlb-service" {
  filter {
    name   = "tag:Name"
    values = ["gwlb-service"]
  }
}

data "aws_ec2_transit_gateway" "tgw-lab" {
  filter {
    name   = "tag:Name"
    values = ["tgw-lab"]
  }
}

data "aws_ec2_transit_gateway_route_table" "tgw-rt-spokes" {
  filter {
    name   = "tag:Name"
    values = ["tgw-rt-spokes"]
  }
}

data "aws_ec2_transit_gateway_route_table" "tgw-rt-hub" {
  filter {
    name   = "tag:Name"
    values = ["tgw-rt-hub"]
  }
}




### CATEGORY: IAM ###

resource "aws_iam_instance_profile" "gwlb-appliances-asg_profile" {
  name = "gwlb-appliances-asg_profile"
  role = aws_iam_role.gwlb-appliances-asg_role.name
  tags = {
    Name           = "gwlb-appliances-asg_profile"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}

data "aws_iam_policy_document" "debug-gwlb-appliances_debug_permissions" {
  statement {
    sid       = "SendToTaggedInstancesOnly"
    effect    = "Allow"
    actions   = ["ssm:SendCommand"]
    resources = ["arn:aws:ec2:*:*:instance/*"]
    condition {
      test     = "StringEquals"
      values   = ["3747d641-2011-4e16-a9cc-2f21512cd864"]
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
      values   = ["3747d641-2011-4e16-a9cc-2f21512cd864"]
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

data "aws_iam_policy_document" "debug-gwlb-appliances_debug_trust" {
  statement {
    effect = "Allow"
    principals {
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/CrossAccountStruct8"]
      type        = "AWS"
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "Struct8Debug-debug-gwlb-appliances" {
  name                 = "Struct8Debug-3747d641-2011-4e16-a9cc-2f21512cd864"
  assume_role_policy   = data.aws_iam_policy_document.debug-gwlb-appliances_debug_trust.json
  max_session_duration = 3600
}

resource "aws_iam_role" "gwlb-appliances-asg_role" {
  name = "gwlb-appliances-asg_role"
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
    Name           = "gwlb-appliances-asg_role"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role_policy" "Struct8Debug-debug-gwlb-appliances_policy" {
  name   = "Struct8Debug-3747d641-2011-4e16-a9cc-2f21512cd864-policy"
  policy = data.aws_iam_policy_document.debug-gwlb-appliances_debug_permissions.json
  role   = aws_iam_role.Struct8Debug-debug-gwlb-appliances.id
}

resource "aws_iam_role_policy_attachment" "AmazonSSMManagedInstanceCore_to_gwlb-appliances-asg_attach" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.gwlb-appliances-asg_role.name
}




### CATEGORY: NETWORK ###

resource "aws_vpc" "vpc-hub" {
  cidr_block           = "10.30.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default"
  tags = {
    Name           = "vpc-hub"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_vpc_endpoint" "hub-gwlbe-a" {
  service_name      = data.aws_vpc_endpoint_service.gwlb-service.service_name
  vpc_id            = aws_vpc.vpc-hub.id
  ip_address_type   = "ipv4"
  subnet_ids        = [aws_subnet.hub-gwlbe-a.id]
  vpc_endpoint_type = "GatewayLoadBalancer"
  tags = {
    Name           = "hub-gwlbe-a"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_vpc_endpoint" "hub-gwlbe-b" {
  service_name      = data.aws_vpc_endpoint_service.gwlb-service.service_name
  vpc_id            = aws_vpc.vpc-hub.id
  ip_address_type   = "ipv4"
  subnet_ids        = [aws_subnet.hub-gwlbe-b.id]
  vpc_endpoint_type = "GatewayLoadBalancer"
  tags = {
    Name           = "hub-gwlbe-b"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_vpc_endpoint" "hub-gwlbe-c" {
  service_name      = data.aws_vpc_endpoint_service.gwlb-service.service_name
  vpc_id            = aws_vpc.vpc-hub.id
  ip_address_type   = "ipv4"
  subnet_ids        = [aws_subnet.hub-gwlbe-c.id]
  vpc_endpoint_type = "GatewayLoadBalancer"
  tags = {
    Name           = "hub-gwlbe-c"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_vpc_endpoint" "hub-ssm-endpoint_SSM" {
  service_name        = "com.amazonaws.${data.aws_region.current.region}.ssm"
  vpc_id              = aws_vpc.vpc-hub.id
  ip_address_type     = "ipv4"
  private_dns_enabled = false
  security_group_ids  = [aws_security_group.sg_vpce_hub-ssm-endpoint.id]
  subnet_ids          = [aws_subnet.Subnet.id]
  vpc_endpoint_type   = "Interface"
  tags = {
    Name           = "hub-ssm-endpoint"
    DifName        = "hub-ssm-endpoint_SSM"
    State          = "State3"
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
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "hub-gwlb-a" {
  vpc_id                  = aws_vpc.vpc-hub.id
  availability_zone       = "us-west-2a"
  cidr_block              = "10.30.111.0/28"
  map_public_ip_on_launch = false
  tags = {
    Name           = "hub-gwlb-a"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "hub-gwlb-b" {
  vpc_id                  = aws_vpc.vpc-hub.id
  availability_zone       = "us-west-2b"
  cidr_block              = "10.30.111.16/28"
  map_public_ip_on_launch = false
  tags = {
    Name           = "hub-gwlb-b"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "hub-gwlb-c" {
  vpc_id                  = aws_vpc.vpc-hub.id
  availability_zone       = "us-west-2c"
  cidr_block              = "10.30.111.32/28"
  map_public_ip_on_launch = false
  tags = {
    Name           = "hub-gwlb-c"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "hub-gwlbe-a" {
  vpc_id                  = aws_vpc.vpc-hub.id
  availability_zone       = "us-west-2a"
  cidr_block              = "10.30.112.0/28"
  map_public_ip_on_launch = false
  tags = {
    Name           = "hub-gwlbe-a"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "hub-gwlbe-b" {
  vpc_id                  = aws_vpc.vpc-hub.id
  availability_zone       = "us-west-2b"
  cidr_block              = "10.30.112.16/28"
  map_public_ip_on_launch = false
  tags = {
    Name           = "hub-gwlbe-b"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "hub-gwlbe-c" {
  vpc_id                  = aws_vpc.vpc-hub.id
  availability_zone       = "us-west-2c"
  cidr_block              = "10.30.112.32/28"
  map_public_ip_on_launch = false
  tags = {
    Name           = "hub-gwlbe-c"
    State          = "State3"
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
    State          = "State3"
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
    State          = "State3"
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
    State          = "State3"
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
    State          = "State3"
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
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_internet_gateway" "IGW" {
  vpc_id = aws_vpc.vpc-hub.id
  tags = {
    Name           = "IGW"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_nat_gateway" "NAT1" {
  vpc_id            = aws_vpc.vpc-hub.id
  availability_mode = "regional"
  connectivity_type = "public"
  tags = {
    Name           = "NAT1"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_internet_gateway.IGW]
}

resource "aws_route" "route_NAT1_to_tgw-lab_ipv4" {
  route_table_id         = aws_nat_gateway.NAT1.route_table_id
  transit_gateway_id     = data.aws_ec2_transit_gateway.tgw-lab.id
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
  transit_gateway_id     = data.aws_ec2_transit_gateway.tgw-lab.id
  destination_cidr_block = "10.0.0.0/8"
  depends_on             = [aws_ec2_transit_gateway_vpc_attachment.att-hub]
}

resource "aws_route" "route_rt-hub-appliance_to_NAT1_ipv4" {
  nat_gateway_id         = aws_nat_gateway.NAT1.id
  route_table_id         = aws_route_table.rt-hub-appliance.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route" "route_rt-hub-gwlbe_to_NAT1_ipv4" {
  nat_gateway_id         = aws_nat_gateway.NAT1.id
  route_table_id         = aws_route_table.rt-hub-gwlbe.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route" "route_rt-hub-tgw-a_to_hub-gwlbe-a_ipv4" {
  route_table_id         = aws_route_table.rt-hub-tgw-a.id
  vpc_endpoint_id        = aws_vpc_endpoint.hub-gwlbe-a.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route" "route_rt-hub-tgw-b_to_hub-gwlbe-b_ipv4" {
  route_table_id         = aws_route_table.rt-hub-tgw-b.id
  vpc_endpoint_id        = aws_vpc_endpoint.hub-gwlbe-b.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route" "route_rt-hub-tgw-c_to_hub-gwlbe-c_ipv4" {
  route_table_id         = aws_route_table.rt-hub-tgw-c.id
  vpc_endpoint_id        = aws_vpc_endpoint.hub-gwlbe-c.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route53_record" "alias_a_aws_vpc_endpoint_hub-ssm-endpoint_SSM_ssm_us-west-2_amazonaws_com" {
  name    = "ssm.us-west-2.amazonaws.com"
  zone_id = aws_route53_zone.ssm-private-zone.zone_id
  type    = "A"
  alias {
    name                   = aws_vpc_endpoint.hub-ssm-endpoint_SSM.dns_entry[0].dns_name
    zone_id                = aws_vpc_endpoint.hub-ssm-endpoint_SSM.dns_entry[0].hosted_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_zone" "ssm-private-zone" {
  name          = "ssm.us-west-2.amazonaws.com"
  force_destroy = false
  lifecycle {
    ignore_changes = [vpc]
  }
  tags = {
    Name           = "ssm-private-zone"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
  vpc {
    vpc_id = aws_vpc.vpc-hub.id
  }
}

resource "aws_route_table" "RT" {
  vpc_id = aws_vpc.vpc-hub.id
  tags = {
    Name           = "RT"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route_table" "rt-hub-appliance" {
  vpc_id = aws_vpc.vpc-hub.id
  tags = {
    Name           = "rt-hub-appliance"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route_table" "rt-hub-gwlbe" {
  vpc_id = aws_vpc.vpc-hub.id
  tags = {
    Name           = "rt-hub-gwlbe"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route_table" "rt-hub-tgw-a" {
  vpc_id = aws_vpc.vpc-hub.id
  tags = {
    Name           = "rt-hub-tgw-a"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route_table" "rt-hub-tgw-b" {
  vpc_id = aws_vpc.vpc-hub.id
  tags = {
    Name           = "rt-hub-tgw-b"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route_table" "rt-hub-tgw-c" {
  vpc_id = aws_vpc.vpc-hub.id
  tags = {
    Name           = "rt-hub-tgw-c"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route_table_association" "aws_route_table_association_Subnet_RT" {
  route_table_id = aws_route_table.RT.id
  subnet_id      = aws_subnet.Subnet.id
}

resource "aws_route_table_association" "aws_route_table_association_hub_gwlb_a_rt_hub_appliance" {
  route_table_id = aws_route_table.rt-hub-appliance.id
  subnet_id      = aws_subnet.hub-gwlb-a.id
}

resource "aws_route_table_association" "aws_route_table_association_hub_gwlb_b_rt_hub_appliance" {
  route_table_id = aws_route_table.rt-hub-appliance.id
  subnet_id      = aws_subnet.hub-gwlb-b.id
}

resource "aws_route_table_association" "aws_route_table_association_hub_gwlb_c_rt_hub_appliance" {
  route_table_id = aws_route_table.rt-hub-appliance.id
  subnet_id      = aws_subnet.hub-gwlb-c.id
}

resource "aws_route_table_association" "aws_route_table_association_hub_gwlbe_a_rt_hub_gwlbe" {
  route_table_id = aws_route_table.rt-hub-gwlbe.id
  subnet_id      = aws_subnet.hub-gwlbe-a.id
}

resource "aws_route_table_association" "aws_route_table_association_hub_gwlbe_b_rt_hub_gwlbe" {
  route_table_id = aws_route_table.rt-hub-gwlbe.id
  subnet_id      = aws_subnet.hub-gwlbe-b.id
}

resource "aws_route_table_association" "aws_route_table_association_hub_gwlbe_c_rt_hub_gwlbe" {
  route_table_id = aws_route_table.rt-hub-gwlbe.id
  subnet_id      = aws_subnet.hub-gwlbe-c.id
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

resource "aws_security_group" "autoscaling_group_gwlb-appliances-asg_group" {
  name                   = "autoscaling_group_gwlb-appliances-asg_group"
  vpc_id                 = aws_vpc.vpc-hub.id
  revoke_rules_on_delete = false
  tags = {
    Name           = "autoscaling_group_gwlb-appliances-asg_group"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group" "sg_vpce_hub-ssm-endpoint" {
  name        = "vpce-sg-hub-ssm-endpoint"
  vpc_id      = aws_vpc.vpc-hub.id
  description = "Auto-generated SG for hub-ssm-endpoint"
  tags = {
    Name           = "hub-ssm-endpoint"
    DifName        = "sg_vpce_hub-ssm-endpoint"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group_rule" "rule_autoscaling_group_gwlb_appliances_asg_group_egress_all_protocols" {
  security_group_id = aws_security_group.autoscaling_group_gwlb-appliances-asg_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "rule_autoscaling_group_gwlb_appliances_asg_group_ingress_tcp_8060" {
  security_group_id = aws_security_group.autoscaling_group_gwlb-appliances-asg_group.id
  cidr_blocks       = ["10.30.111.0/28", "10.30.111.16/28", "10.30.111.32/28"]
  description       = "Health check from the Gateway Load Balancer"
  from_port         = 8060
  protocol          = "tcp"
  to_port           = 8060
  type              = "ingress"
}

resource "aws_security_group_rule" "rule_autoscaling_group_gwlb_appliances_asg_group_ingress_udp_6081" {
  security_group_id = aws_security_group.autoscaling_group_gwlb-appliances-asg_group.id
  cidr_blocks       = ["10.30.111.0/28", "10.30.111.16/28", "10.30.111.32/28"]
  description       = "GENEVE from the Gateway Load Balancer"
  from_port         = 6081
  protocol          = "udp"
  to_port           = 6081
  type              = "ingress"
}

resource "aws_security_group_rule" "rule_sg_vpce_hub_ssm_endpoint_egress_all_protocols" {
  security_group_id = aws_security_group.sg_vpce_hub-ssm-endpoint.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow all outbound traffic"
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "rule_sg_vpce_hub_ssm_endpoint_ingress_tcp_443" {
  security_group_id = aws_security_group.sg_vpce_hub-ssm-endpoint.id
  cidr_blocks       = ["10.30.0.0/16", "10.2.0.0/16", "10.6.0.0/16"]
  description       = "Allow HTTPS from VPC and the VPCs sharing this endpoint"
  from_port         = 443
  protocol          = "tcp"
  to_port           = 443
  type              = "ingress"
}

resource "aws_lb" "hub-gwlb" {
  name                             = "hub-gwlb"
  enable_cross_zone_load_balancing = true
  load_balancer_type               = "gateway"
  subnets                          = [aws_subnet.hub-gwlb-a.id, aws_subnet.hub-gwlb-b.id, aws_subnet.hub-gwlb-c.id]
  tags = {
    Name           = "hub-gwlb"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_lb_listener" "gwlb-listener" {
  load_balancer_arn = aws_lb.hub-gwlb.arn
  default_action {
    order            = 1
    target_group_arn = aws_lb_target_group.gwlb-appliances.arn
    type             = "forward"
    forward {
      target_group {
        arn = aws_lb_target_group.gwlb-appliances.arn
      }
    }
  }
  tags = {
    Name           = "gwlb-listener"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_lb_target_group" "gwlb-appliances" {
  name                 = "gwlb-appliances"
  vpc_id               = aws_vpc.vpc-hub.id
  deregistration_delay = "300"
  ip_address_type      = "ipv4"
  port                 = 6081
  protocol             = "GENEVE"
  target_type          = "instance"
  health_check {
    port     = "8060"
    protocol = "TCP"
  }
  tags = {
    Name           = "gwlb-appliances"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_ec2_transit_gateway_route" "tgw-rt-spokes_att-hub_0_0_0_0_0" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.att-hub.id
  transit_gateway_route_table_id = data.aws_ec2_transit_gateway_route_table.tgw-rt-spokes.id
  destination_cidr_block         = "0.0.0.0/0"
}

resource "aws_ec2_transit_gateway_route_table_association" "att-hub_tgw-rt-hub_association" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.att-hub.id
  transit_gateway_route_table_id = data.aws_ec2_transit_gateway_route_table.tgw-rt-hub.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "att-hub_tgw-rt-spokes_propagation" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.att-hub.id
  transit_gateway_route_table_id = data.aws_ec2_transit_gateway_route_table.tgw-rt-spokes.id
}

resource "aws_ec2_transit_gateway_vpc_attachment" "att-hub" {
  transit_gateway_id                              = data.aws_ec2_transit_gateway.tgw-lab.id
  vpc_id                                          = aws_vpc.vpc-hub.id
  appliance_mode_support                          = "enable"
  subnet_ids                                      = [aws_subnet.hub-tgw-a.id, aws_subnet.hub-tgw-b.id, aws_subnet.hub-tgw-c.id]
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
  tags = {
    Name           = "att-hub"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}




### CATEGORY: COMPUTE ###

data "local_file" "UserData_gwlb-appliance-lt" {
  filename = "${path.module}/.external_modules/struct8-templates/templates/gwlb-inspection/v1/user_data/Inspect.sh"
}

data "aws_ami" "AMI_Data_Source_gwlb-appliance-lt" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-kernel-6.1-arm64"]
  }
}

resource "aws_launch_template" "gwlb-appliance-lt" {
  image_id               = data.aws_ami.AMI_Data_Source_gwlb-appliance-lt.id
  name                   = "gwlb-appliance-lt"
  instance_type          = "t4g.small"
  update_default_version = true
  user_data = base64encode(<<-EOFUData
#!/bin/bash

# --- BEGIN STRUCT8 VARIABLES ---
cat << 'EOFENV' > /etc/struct8_env
NAME="gwlb-appliances-asg"
REGION="${data.aws_region.current.region}"
ACCOUNT="${data.aws_caller_identity.current.account_id}"
EOFENV
cat /etc/struct8_env >> /etc/environment
sed 's/^/export /' /etc/struct8_env > /etc/profile.d/struct8_vars.sh
chmod +x /etc/profile.d/struct8_vars.sh
chmod 644 /etc/struct8_env
# --- END STRUCT8 VARIABLES ---

${data.local_file.UserData_gwlb-appliance-lt.content}
EOFUData
)
  vpc_security_group_ids = [aws_security_group.autoscaling_group_gwlb-appliances-asg_group.id]
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      delete_on_termination = true
      encrypted             = true
      iops                  = 3000
      throughput            = 125
      volume_size           = 8
      volume_type           = "gp3"
    }
  }
  iam_instance_profile {
    name = aws_iam_instance_profile.gwlb-appliances-asg_profile.name
  }
  metadata_options {
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 1
    http_tokens                 = "required"
  }
  tag_specifications {
    resource_type = "volume"
    tags = {
    Struct8Debug   = "3747d641-2011-4e16-a9cc-2f21512cd864"
    Name           = "gwlb-appliances-asg"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
  }
  tags = {
    Name           = "gwlb-appliance-lt"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_autoscaling_group" "gwlb-appliances-asg" {
  name                    = "gwlb-appliances-asg"
  default_instance_warmup = 0
  desired_capacity        = 3
  enabled_metrics         = ["GroupInServiceInstances"]
  health_check_type       = "EC2"
  max_instance_lifetime   = 0
  max_size                = 3
  metrics_granularity     = "1Minute"
  min_elb_capacity        = 0
  min_size                = 3
  target_group_arns       = [aws_lb_target_group.gwlb-appliances.arn]
  termination_policies    = ["Default"]
  vpc_zone_identifier     = [aws_subnet.hub-gwlb-a.id, aws_subnet.hub-gwlb-b.id, aws_subnet.hub-gwlb-c.id]
  wait_for_elb_capacity   = 0
  launch_template {
    version = aws_launch_template.gwlb-appliance-lt.latest_version
    id      = aws_launch_template.gwlb-appliance-lt.id
  }
  tag {
    key                 = "Struct8Debug"
    propagate_at_launch = true
    value               = "3747d641-2011-4e16-a9cc-2f21512cd864"
  }
  tag {
    key                 = "Name"
    propagate_at_launch = true
    value               = "gwlb-appliances-asg"
  }
  tag {
    key                 = "State"
    propagate_at_launch = true
    value               = "State3"
  }
  tag {
    key                 = "Struct8Creator"
    propagate_at_launch = true
    value               = "Contato Struct"
  }
}


