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

### RENAMES ###

moved {
  from = aws_route_table_association.aws_route_table_association_oregon_net2_private_c_oregon_net2_rt_private
  to   = aws_route_table_association.aws_route_table_association_oregon_net2_private_c_j_oregon_net2_rt_private
}

moved {
  from = aws_subnet.oregon-net2-private-c
  to   = aws_subnet.oregon-net2-private-c-j
}




### CATEGORY: IAM ###

resource "aws_iam_instance_profile" "ASG1_profile" {
  name = "ASG1_profile"
  role = aws_iam_role.ASG1_role.name
  tags = {
    Name           = "ASG1_profile"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "ASG1_role" {
  name = "ASG1_role"
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
    Name           = "ASG1_role"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}




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
    DifName        = "oregon-net2-vpce-s3"
    Project        = "oregon-net2"
    Name           = "oregon-net2-vpce-s3"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "oregon-net2-private-c-j" {
  vpc_id                              = aws_vpc.oregon-asg-vpc2.id
  availability_zone                   = "us-west-2c"
  cidr_block                          = "10.30.80.0/24"
  map_public_ip_on_launch             = false
  private_dns_hostname_type_on_launch = "ip-name"
  tags = {
    Project        = "oregon-net2"
    Tier           = "private"
    Name           = "oregon-net2-private-c-j"
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

resource "aws_route_table_association" "aws_route_table_association_oregon_net2_private_c_j_oregon_net2_rt_private" {
  route_table_id = aws_route_table.oregon-net2-rt-private.id
  subnet_id      = aws_subnet.oregon-net2-private-c-j.id
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

resource "aws_network_acl_rule" "out_acl-04ffdad4553bd4409_100_egress_0_0_0_0_0_all_proto" {
  network_acl_id = aws_network_acl.oregon-net2-nacl.id
  cidr_block     = "0.0.0.0/0"
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  rule_number    = 100
}

resource "aws_security_group" "autoscaling_group_ASG1_group" {
  name                   = "autoscaling_group_ASG1_group"
  vpc_id                 = aws_vpc.oregon-asg-vpc2.id
  revoke_rules_on_delete = false
  tags = {
    Name           = "autoscaling_group_ASG1_group"
    State          = "State3"
    Struct8Creator = "Contato Struct"
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

resource "aws_security_group_rule" "rule_autoscaling_group_ASG1_group_egress_all_protocols" {
  security_group_id = aws_security_group.autoscaling_group_ASG1_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
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




### CATEGORY: COMPUTE ###

data "aws_ami" "AMI_Data_Source_Template1" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-kernel-6.1-x86_64"]
  }
}

resource "aws_launch_template" "Template1" {
  image_id               = data.aws_ami.AMI_Data_Source_Template1.id
  name                   = "Template1"
  instance_type          = "t3.micro"
  update_default_version = true
  user_data = base64encode(<<-EOFUData
#!/bin/bash

# --- BEGIN STRUCT8 VARIABLES ---
cat << 'EOFENV' > /etc/struct8_env
NAME    = "ASG1"
REGION  = "${data.aws_region.current.region}"
ACCOUNT = "${data.aws_caller_identity.current.account_id}"
EOFENV
cat /etc/struct8_env >> /etc/environment
sed 's/^/export /' /etc/struct8_env > /etc/profile.d/struct8_vars.sh
chmod +x /etc/profile.d/struct8_vars.sh
chmod 644 /etc/struct8_env
# --- END STRUCT8 VARIABLES ---


EOFUData
)
  vpc_security_group_ids = [aws_security_group.autoscaling_group_ASG1_group.id]
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
    name = aws_iam_instance_profile.ASG1_profile.name
  }
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
  tag_specifications {
    resource_type = "volume"
    tags = {
    Name           = "ASG1"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
  }
  tags = {
    Name           = "Template1"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_autoscaling_group" "ASG1" {
  name                    = "ASG1"
  default_instance_warmup = 0
  desired_capacity        = 0
  health_check_type       = "EC2"
  max_instance_lifetime   = 0
  max_size                = 0
  metrics_granularity     = "1Minute"
  min_elb_capacity        = 0
  min_size                = 0
  termination_policies    = ["Default"]
  vpc_zone_identifier     = [aws_subnet.oregon-net2-public-b.id]
  wait_for_elb_capacity   = 0
  launch_template {
    version = aws_launch_template.Template1.latest_version
    id      = aws_launch_template.Template1.id
  }
  tag {
    key                 = "Name"
    propagate_at_launch = true
    value               = "ASG1"
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


