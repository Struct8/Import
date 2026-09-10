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

### CATEGORY: NETWORK ###

resource "aws_vpc" "oregon-asg-vpc2" {
  assign_generated_ipv6_cidr_block     = true
  cidr_block                           = "10.30.0.0/16"
  enable_dns_support                   = true
  instance_tenancy                     = "default"
  ipv6_cidr_block_network_border_group = "us-west-2"
  tags = {
    Name           = "oregon-asg-vpc2"
    State          = "ImportVPC2"
    Struct8Creator = "Contato Struct"
    Project        = "oregon-asg"
  }
}

resource "aws_vpc_endpoint" "oregon-net2-vpce-s3_S3" {
  service_name      = "com.amazonaws.us-west-2.s3"
  vpc_id            = aws_vpc.oregon-asg-vpc2.id
  policy            = "{\"Statement\":[{\"Action\":\"*\",\"Effect\":\"Allow\",\"Principal\":\"*\",\"Resource\":\"*\"}],\"Version\":\"2008-10-17\"}"
  route_table_ids   = [aws_route_table.oregon-net2-rt-private.id]
  vpc_endpoint_type = "Gateway"
  tags = {
    Name           = "oregon-net2-vpce-s3"
    Project        = "oregon-net2"
    DifName        = "oregon-net2-vpce-s3"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "oregon-net2-private-c" {
  vpc_id                              = aws_vpc.oregon-asg-vpc2.id
  availability_zone                   = "us-west-2c"
  cidr_block                          = "10.30.80.0/24"
  map_public_ip_on_launch             = false
  private_dns_hostname_type_on_launch = "ip-name"
  tags = {
    Name           = "oregon-net2-private-c"
    Project        = "oregon-net2"
    Tier           = "private"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "oregon-net2-public-a" {
  vpc_id                              = aws_vpc.oregon-asg-vpc2.id
  availability_zone                   = "us-west-2a"
  cidr_block                          = "10.30.40.0/24"
  map_public_ip_on_launch             = true
  private_dns_hostname_type_on_launch = "ip-name"
  tags = {
    Name           = "oregon-net2-public-a"
    Project        = "oregon-net2"
    Tier           = "public"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "oregon-net2-public-b" {
  vpc_id                              = aws_vpc.oregon-asg-vpc2.id
  availability_zone                   = "us-west-2b"
  cidr_block                          = "10.30.41.0/24"
  map_public_ip_on_launch             = true
  private_dns_hostname_type_on_launch = "ip-name"
  tags = {
    Name           = "oregon-net2-public-b"
    Project        = "oregon-net2"
    Tier           = "public"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_internet_gateway" "oregon-net2-igw" {
  vpc_id = aws_vpc.oregon-asg-vpc2.id
  tags = {
    Name           = "oregon-net2-igw"
    Project        = "oregon-net2"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_egress_only_internet_gateway" "eigw-083dc9b065af87635" {
  vpc_id = aws_vpc.oregon-asg-vpc2.id
  tags = {
    Name           = "oregon-asg-eoigw"
    State          = "ImportVPC2"
    Struct8Creator = "Contato Struct"
    Project        = "oregon-asg"
  }
}

resource "aws_route" "route_oregon-net2-rt-public_to_oregon-net2-igw_ipv4" {
  gateway_id             = aws_internet_gateway.oregon-net2-igw.id
  route_table_id         = aws_route_table.oregon-net2-rt-public.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table" "oregon-net2-rt-private" {
  vpc_id = aws_vpc.oregon-asg-vpc2.id
  tags = {
    Name           = "oregon-net2-rt-private"
    Project        = "oregon-net2"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route_table" "oregon-net2-rt-public" {
  vpc_id = aws_vpc.oregon-asg-vpc2.id
  tags = {
    Name           = "oregon-net2-rt-public"
    Project        = "oregon-net2"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route_table_association" "aws_route_table_association_oregon_net2_private_c_oregon_net2_rt_private" {
  route_table_id = aws_route_table.oregon-net2-rt-private.id
  subnet_id      = aws_subnet.oregon-net2-private-c.id
}

resource "aws_route_table_association" "aws_route_table_association_oregon_net2_public_a_oregon_net2_rt_public" {
  route_table_id = aws_route_table.oregon-net2-rt-public.id
  subnet_id      = aws_subnet.oregon-net2-public-a.id
}

resource "aws_route_table_association" "aws_route_table_association_oregon_net2_public_b_oregon_net2_rt_public" {
  route_table_id = aws_route_table.oregon-net2-rt-public.id
  subnet_id      = aws_subnet.oregon-net2-public-b.id
}

resource "aws_network_acl" "oregon-net2-nacl" {
  vpc_id     = aws_vpc.oregon-asg-vpc2.id
  subnet_ids = [aws_subnet.oregon-net2-public-a.id]
  tags = {
    Name           = "oregon-net2-nacl"
    Project        = "oregon-net2"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_network_acl_rule" "in_acl-04ffdad4553bd4409_100_ingress_0_0_0_0_0_tcp_port_443" {
  network_acl_id = aws_network_acl.oregon-net2-nacl.id
  cidr_block     = "0.0.0.0/0"
  egress         = false
  from_port      = 443
  protocol       = "tcp"
  rule_action    = "allow"
  rule_number    = 100
  to_port        = 443
}

resource "aws_network_acl_rule" "in_acl-04ffdad4553bd4409_110_ingress_0_0_0_0_0_tcp_ports_1024_65535" {
  network_acl_id = aws_network_acl.oregon-net2-nacl.id
  cidr_block     = "0.0.0.0/0"
  egress         = false
  from_port      = 1024
  protocol       = "tcp"
  rule_action    = "allow"
  rule_number    = 110
  to_port        = 65535
}

resource "aws_network_acl_rule" "out_acl-04ffdad4553bd4409_100_egress_0_0_0_0_0_all_proto" {
  network_acl_id = aws_network_acl.oregon-net2-nacl.id
  cidr_block     = "0.0.0.0/0"
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  rule_number    = 100
}

resource "aws_security_group" "oregon-net2-web" {
  name        = "oregon-net2-web"
  vpc_id      = aws_vpc.oregon-asg-vpc2.id
  description = "import lab -- web tier of the second vpc"
  lifecycle {
    ignore_changes = [revoke_rules_on_delete]
  }
  tags = {
    Name           = "oregon-net2-web"
    Project        = "oregon-net2"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group_rule" "rule_oregon_net2_web_egress_all_protocols" {
  security_group_id = aws_security_group.oregon-net2-web.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  ipv6_cidr_blocks  = ["::/0"]
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "rule_oregon_net2_web_ingress_tcp_443" {
  security_group_id = aws_security_group.oregon-net2-web.id
  cidr_blocks       = ["10.30.0.0/16"]
  from_port         = 443
  protocol          = "tcp"
  to_port           = 443
  type              = "ingress"
}

resource "aws_security_group_rule" "rule_oregon_net2_web_ingress_tcp_80" {
  security_group_id = aws_security_group.oregon-net2-web.id
  cidr_blocks       = ["10.20.0.0/16"]
  from_port         = 80
  protocol          = "tcp"
  to_port           = 80
  type              = "ingress"
}


