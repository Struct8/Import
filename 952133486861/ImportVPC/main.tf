terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  backend "s3" {
    bucket  = "struct8-import"
    key     = "952133486861/ImportVPC/main.tfstate"
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

resource "aws_vpc" "oregon-net-vpc" {
  cidr_block           = "10.20.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default"
  tags = {
    Project        = "oregon-net"
    Name           = "oregon-net-vpc"
    State          = "ImportVPC"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_vpc_endpoint" "oregon-net-vpce-dynamodb_DynamoDB" {
  service_name      = "com.amazonaws.us-west-2.dynamodb"
  vpc_id            = aws_vpc.oregon-net-vpc.id
  policy            = "{\"Statement\":[{\"Action\":\"*\",\"Effect\":\"Allow\",\"Principal\":\"*\",\"Resource\":\"*\"}],\"Version\":\"2008-10-17\"}"
  route_table_ids   = [aws_route_table.oregon-net-rt-private-c.id, aws_route_table.oregon-net-rt-private-b.id, aws_route_table.oregon-net-rt-private-a.id]
  vpc_endpoint_type = "Gateway"
  tags = {
    DifName        = "oregon-net-vpce-dynamodb"
    Project        = "oregon-net"
    Name           = "oregon-net-vpce-dynamodb"
    State          = "ImportVPC"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_vpc_endpoint" "oregon-net-vpce-s3_S3" {
  service_name      = "com.amazonaws.us-west-2.s3"
  vpc_id            = aws_vpc.oregon-net-vpc.id
  policy            = "{\"Statement\":[{\"Action\":\"*\",\"Effect\":\"Allow\",\"Principal\":\"*\",\"Resource\":\"*\"}],\"Version\":\"2008-10-17\"}"
  route_table_ids   = [aws_route_table.oregon-net-rt-private-c.id, aws_route_table.oregon-net-rt-private-b.id, aws_route_table.oregon-net-rt-private-a.id]
  vpc_endpoint_type = "Gateway"
  tags = {
    DifName        = "oregon-net-vpce-s3"
    Project        = "oregon-net"
    Name           = "oregon-net-vpce-s3"
    State          = "ImportVPC"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "oregon-net-private-a" {
  vpc_id                              = aws_vpc.oregon-net-vpc.id
  availability_zone                   = "us-west-2a"
  cidr_block                          = "10.20.10.0/24"
  map_public_ip_on_launch             = false
  private_dns_hostname_type_on_launch = "ip-name"
  tags = {
    Project        = "oregon-net"
    Name           = "oregon-net-private-a"
    State          = "ImportVPC"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "oregon-net-private-b" {
  vpc_id                              = aws_vpc.oregon-net-vpc.id
  availability_zone                   = "us-west-2b"
  cidr_block                          = "10.20.11.0/24"
  map_public_ip_on_launch             = false
  private_dns_hostname_type_on_launch = "ip-name"
  tags = {
    Project        = "oregon-net"
    Name           = "oregon-net-private-b"
    State          = "ImportVPC"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "oregon-net-private-c" {
  vpc_id                              = aws_vpc.oregon-net-vpc.id
  availability_zone                   = "us-west-2c"
  cidr_block                          = "10.20.12.0/24"
  map_public_ip_on_launch             = false
  private_dns_hostname_type_on_launch = "ip-name"
  tags = {
    Project        = "oregon-net"
    Name           = "oregon-net-private-c"
    State          = "ImportVPC"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "oregon-net-public-a" {
  vpc_id                              = aws_vpc.oregon-net-vpc.id
  availability_zone                   = "us-west-2a"
  cidr_block                          = "10.20.0.0/24"
  map_public_ip_on_launch             = true
  private_dns_hostname_type_on_launch = "ip-name"
  tags = {
    Project        = "oregon-net"
    Name           = "oregon-net-public-a"
    State          = "ImportVPC"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "oregon-net-public-b" {
  vpc_id                              = aws_vpc.oregon-net-vpc.id
  availability_zone                   = "us-west-2b"
  cidr_block                          = "10.20.1.0/24"
  map_public_ip_on_launch             = true
  private_dns_hostname_type_on_launch = "ip-name"
  tags = {
    Project        = "oregon-net"
    Name           = "oregon-net-public-b"
    State          = "ImportVPC"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "oregon-net-public-c" {
  vpc_id                              = aws_vpc.oregon-net-vpc.id
  availability_zone                   = "us-west-2c"
  cidr_block                          = "10.20.2.0/24"
  map_public_ip_on_launch             = true
  private_dns_hostname_type_on_launch = "ip-name"
  tags = {
    Project        = "oregon-net"
    Name           = "oregon-net-public-c"
    State          = "ImportVPC"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_internet_gateway" "oregon-net-igw" {
  vpc_id = aws_vpc.oregon-net-vpc.id
  tags = {
    Project        = "oregon-net"
    Name           = "oregon-net-igw"
    State          = "ImportVPC"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route" "route_oregon-net-rt-public_to_oregon-net-igw_ipv4" {
  gateway_id             = aws_internet_gateway.oregon-net-igw.id
  route_table_id         = aws_route_table.oregon-net-rt-public.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table" "oregon-net-rt-private-a" {
  vpc_id = aws_vpc.oregon-net-vpc.id
  tags = {
    Project        = "oregon-net"
    Name           = "oregon-net-rt-private-a"
    State          = "ImportVPC"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route_table" "oregon-net-rt-private-b" {
  vpc_id = aws_vpc.oregon-net-vpc.id
  tags = {
    Project        = "oregon-net"
    Name           = "oregon-net-rt-private-b"
    State          = "ImportVPC"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route_table" "oregon-net-rt-private-c" {
  vpc_id = aws_vpc.oregon-net-vpc.id
  tags = {
    Project        = "oregon-net"
    Name           = "oregon-net-rt-private-c"
    State          = "ImportVPC"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route_table" "oregon-net-rt-public" {
  vpc_id = aws_vpc.oregon-net-vpc.id
  tags = {
    Project        = "oregon-net"
    Name           = "oregon-net-rt-public"
    State          = "ImportVPC"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route_table_association" "aws_route_table_association_oregon_net_private_a_oregon_net_rt_private_a" {
  route_table_id = aws_route_table.oregon-net-rt-private-a.id
  subnet_id      = aws_subnet.oregon-net-private-a.id
}

resource "aws_route_table_association" "aws_route_table_association_oregon_net_private_b_oregon_net_rt_private_b" {
  route_table_id = aws_route_table.oregon-net-rt-private-b.id
  subnet_id      = aws_subnet.oregon-net-private-b.id
}

resource "aws_route_table_association" "aws_route_table_association_oregon_net_private_c_oregon_net_rt_private_c" {
  route_table_id = aws_route_table.oregon-net-rt-private-c.id
  subnet_id      = aws_subnet.oregon-net-private-c.id
}

resource "aws_route_table_association" "aws_route_table_association_oregon_net_public_a_oregon_net_rt_public" {
  route_table_id = aws_route_table.oregon-net-rt-public.id
  subnet_id      = aws_subnet.oregon-net-public-a.id
}

resource "aws_route_table_association" "aws_route_table_association_oregon_net_public_b_oregon_net_rt_public" {
  route_table_id = aws_route_table.oregon-net-rt-public.id
  subnet_id      = aws_subnet.oregon-net-public-b.id
}

resource "aws_route_table_association" "aws_route_table_association_oregon_net_public_c_oregon_net_rt_public" {
  route_table_id = aws_route_table.oregon-net-rt-public.id
  subnet_id      = aws_subnet.oregon-net-public-c.id
}

resource "aws_network_acl" "oregon-asg-nacl" {
  vpc_id     = aws_vpc.oregon-net-vpc.id
  subnet_ids = [aws_subnet.oregon-net-public-a.id, aws_subnet.oregon-net-public-c.id, aws_subnet.oregon-net-public-b.id]
  tags = {
    Project        = "oregon-asg"
    Name           = "oregon-asg-nacl"
    State          = "ImportVPC"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_network_acl_rule" "in_acl-09b3a9f00f5142610_100_ingress_0_0_0_0_0_tcp_port_443" {
  network_acl_id = aws_network_acl.oregon-asg-nacl.id
  cidr_block     = "0.0.0.0/0"
  egress         = false
  from_port      = 443
  protocol       = "tcp"
  rule_action    = "allow"
  rule_number    = 100
  to_port        = 443
}

resource "aws_network_acl_rule" "in_acl-09b3a9f00f5142610_110_ingress_0_0_0_0_0_tcp_ports_1024_65535" {
  network_acl_id = aws_network_acl.oregon-asg-nacl.id
  cidr_block     = "0.0.0.0/0"
  egress         = false
  from_port      = 1024
  protocol       = "tcp"
  rule_action    = "allow"
  rule_number    = 110
  to_port        = 65535
}

resource "aws_network_acl_rule" "in_internet_return_tcp_oregon-asg-nacl_ephemeral" {
  network_acl_id = aws_network_acl.oregon-asg-nacl.id
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

resource "aws_network_acl_rule" "in_internet_return_udp_oregon-asg-nacl_ephemeral" {
  network_acl_id = aws_network_acl.oregon-asg-nacl.id
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

resource "aws_network_acl_rule" "out_acl-09b3a9f00f5142610_100_egress_0_0_0_0_0_all_proto" {
  network_acl_id = aws_network_acl.oregon-asg-nacl.id
  cidr_block     = "0.0.0.0/0"
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  rule_number    = 100
}

resource "aws_network_acl_rule" "out_internet_oregon-asg-nacl_port_123_udp" {
  network_acl_id = aws_network_acl.oregon-asg-nacl.id
  cidr_block     = "0.0.0.0/0"
  egress         = true
  from_port      = 123
  protocol       = "udp"
  rule_action    = "allow"
  rule_number    = 4479
  to_port        = 123
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_network_acl_rule" "out_internet_oregon-asg-nacl_port_443_tcp" {
  network_acl_id = aws_network_acl.oregon-asg-nacl.id
  cidr_block     = "0.0.0.0/0"
  egress         = true
  from_port      = 443
  protocol       = "tcp"
  rule_action    = "allow"
  rule_number    = 25911
  to_port        = 443
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_network_acl_rule" "out_internet_oregon-asg-nacl_port_53_tcp" {
  network_acl_id = aws_network_acl.oregon-asg-nacl.id
  cidr_block     = "0.0.0.0/0"
  egress         = true
  from_port      = 53
  protocol       = "tcp"
  rule_action    = "allow"
  rule_number    = 11123
  to_port        = 53
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_network_acl_rule" "out_internet_oregon-asg-nacl_port_53_udp" {
  network_acl_id = aws_network_acl.oregon-asg-nacl.id
  cidr_block     = "0.0.0.0/0"
  egress         = true
  from_port      = 53
  protocol       = "udp"
  rule_action    = "allow"
  rule_number    = 21753
  to_port        = 53
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "oregon-asg-nodes" {
  name        = "oregon-asg-nodes"
  vpc_id      = aws_vpc.oregon-net-vpc.id
  description = "import lab -- nodes launched by the auto scaling group"
  tags = {
    Name           = "oregon-asg-nodes"
    Project        = "oregon-asg"
    State          = "ImportVPC"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group_rule" "rule_oregon_asg_nodes_egress_all_protocols" {
  security_group_id = aws_security_group.oregon-asg-nodes.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "rule_oregon_asg_nodes_ingress_tcp_443" {
  security_group_id = aws_security_group.oregon-asg-nodes.id
  cidr_blocks       = ["10.20.0.0/16"]
  from_port         = 443
  protocol          = "tcp"
  to_port           = 443
  type              = "ingress"
}




### CATEGORY: COMPUTE ###

resource "aws_launch_template" "lt-0c672bbb12a42eab9" {
  image_id               = "ami-08a26983500a08011"
  key_name               = "oregon-asg-key"
  name                   = "oregon-asg-lt"
  default_version        = 1
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.oregon-asg-nodes.id]
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      delete_on_termination = true
      encrypted             = true
      volume_size           = 8
      volume_type           = "gp3"
    }
  }
  metadata_options {
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 2
    http_tokens                 = "required"
  }
  monitoring {
    enabled = false
  }
  tag_specifications {
    resource_type = "instance"
    tags = {
    Name    = "oregon-asg-node"
    Project = "oregon-asg"
  }
  }
  tag_specifications {
    resource_type = "volume"
    tags = {
    Project        = "oregon-asg"
    Name           = "oregon-asg-node"
    State          = "ImportVPC"
    Struct8Creator = "Contato Struct"
  }
  }
  tags = {
    Project        = "oregon-asg"
    Name           = "oregon-asg-lt"
    State          = "ImportVPC"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_autoscaling_group" "oregon-asg-group" {
  name                    = "oregon-asg-group"
  default_instance_warmup = 0
  desired_capacity        = 0
  health_check_type       = "EC2"
  max_instance_lifetime   = 0
  max_size                = 2
  min_size                = 0
  vpc_zone_identifier     = [aws_subnet.oregon-net-private-a.id, aws_subnet.oregon-net-private-c.id, aws_subnet.oregon-net-private-b.id]
  availability_zone_distribution {
    capacity_distribution_strategy = "balanced-best-effort"
  }
  capacity_reservation_specification {
    capacity_reservation_preference = "default"
  }
  launch_template {
    version = "$Latest"
    id      = aws_launch_template.lt-0c672bbb12a42eab9.id
  }
  tag {
    key                 = "Project"
    propagate_at_launch = true
    value               = "oregon-asg"
  }
  tag {
    key                 = "Tier"
    propagate_at_launch = false
    value               = "lab"
  }
  tag {
    key                 = "Name"
    propagate_at_launch = true
    value               = "oregon-asg-node"
  }
  tag {
    key                 = "State"
    propagate_at_launch = true
    value               = "ImportVPC"
  }
  tag {
    key                 = "Struct8Creator"
    propagate_at_launch = true
    value               = "Contato Struct"
  }
}


