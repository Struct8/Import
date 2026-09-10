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
    Project        = "oregon-asg"
    Name           = "oregon-asg-vpc2"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_vpc_endpoint" "oregon-net2-vpce-s3_S3" {
  service_name      = "com.amazonaws.us-west-2.s3"
  vpc_id            = aws_vpc.oregon-asg-vpc2.id
  policy            = "{\"Statement\":[{\"Action\":\"*\",\"Effect\":\"Allow\",\"Principal\":\"*\",\"Resource\":\"*\"}],\"Version\":\"2008-10-17\"}"
  route_table_ids   = [aws_route_table.oregon-net2-rt-private.id]
  vpc_endpoint_type = "Gateway"
  tags = {
    Project        = "oregon-net2"
    DifName        = "oregon-net2-vpce-s3"
    Name           = "oregon-net2-vpce-s3"
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
    Project        = "oregon-net2"
    Tier           = "private"
    Name           = "oregon-net2-private-c"
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
    Project        = "oregon-net2"
    Tier           = "public"
    Name           = "oregon-net2-public-a"
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
    Project        = "oregon-net2"
    Tier           = "public"
    Name           = "oregon-net2-public-b"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_internet_gateway" "oregon-net2-igw" {
  vpc_id = aws_vpc.oregon-asg-vpc2.id
  tags = {
    Project        = "oregon-net2"
    Name           = "oregon-net2-igw"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_egress_only_internet_gateway" "eigw-083dc9b065af87635" {
  vpc_id = aws_vpc.oregon-asg-vpc2.id
  tags = {
    Project        = "oregon-asg"
    Name           = "oregon-asg-eoigw"
    State          = "State3"
    Struct8Creator = "Contato Struct"
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
    Project        = "oregon-net2"
    Name           = "oregon-net2-rt-private"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route_table" "oregon-net2-rt-public" {
  vpc_id = aws_vpc.oregon-asg-vpc2.id
  tags = {
    Project        = "oregon-net2"
    Name           = "oregon-net2-rt-public"
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
    Project        = "oregon-net2"
    Name           = "oregon-net2-nacl"
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

resource "aws_network_acl_rule" "in_internet_return_tcp_oregon-net2-nacl_ephemeral" {
  network_acl_id = aws_network_acl.oregon-net2-nacl.id
  cidr_block     = "0.0.0.0/0"
  egress         = false
  from_port      = 32768
  protocol       = "tcp"
  rule_action    = "allow"
  rule_number    = 1001
  to_port        = 61000
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_network_acl_rule" "in_internet_return_udp_oregon-net2-nacl_ephemeral" {
  network_acl_id = aws_network_acl.oregon-net2-nacl.id
  cidr_block     = "0.0.0.0/0"
  egress         = false
  from_port      = 32768
  protocol       = "udp"
  rule_action    = "allow"
  rule_number    = 1002
  to_port        = 61000
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_network_acl_rule" "out_acl-04ffdad4553bd4409_100_egress_0_0_0_0_0_all_proto" {
  network_acl_id = aws_network_acl.oregon-net2-nacl.id
  cidr_block     = "0.0.0.0/0"
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  rule_number    = 100
}

resource "aws_network_acl_rule" "out_internet_oregon-net2-nacl_port_123_udp" {
  network_acl_id = aws_network_acl.oregon-net2-nacl.id
  cidr_block     = "0.0.0.0/0"
  egress         = true
  from_port      = 123
  protocol       = "udp"
  rule_action    = "allow"
  rule_number    = 14695
  to_port        = 123
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_network_acl_rule" "out_internet_oregon-net2-nacl_port_443_tcp" {
  network_acl_id = aws_network_acl.oregon-net2-nacl.id
  cidr_block     = "0.0.0.0/0"
  egress         = true
  from_port      = 443
  protocol       = "tcp"
  rule_action    = "allow"
  rule_number    = 4534
  to_port        = 443
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_network_acl_rule" "out_internet_oregon-net2-nacl_port_53_tcp" {
  network_acl_id = aws_network_acl.oregon-net2-nacl.id
  cidr_block     = "0.0.0.0/0"
  egress         = true
  from_port      = 53
  protocol       = "tcp"
  rule_action    = "allow"
  rule_number    = 3145
  to_port        = 53
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_network_acl_rule" "out_internet_oregon-net2-nacl_port_53_udp" {
  network_acl_id = aws_network_acl.oregon-net2-nacl.id
  cidr_block     = "0.0.0.0/0"
  egress         = true
  from_port      = 53
  protocol       = "udp"
  rule_action    = "allow"
  rule_number    = 7185
  to_port        = 53
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "oregon-net2-web" {
  name        = "oregon-net2-web"
  vpc_id      = aws_vpc.oregon-asg-vpc2.id
  description = "import lab -- web tier of the second vpc"
  tags = {
    Project        = "oregon-net2"
    Name           = "oregon-net2-web"
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


