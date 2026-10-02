terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  backend "s3" {
    bucket  = "struct8-import"
    key     = "952133486861/ec2-nat-private-nattest/main.tfstate"
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

resource "aws_iam_instance_profile" "kuma-nattest_profile" {
  name = "kuma-nattest_profile"
  role = aws_iam_role.kuma-nattest_role.name
  tags = {
    Name           = "kuma-nattest_profile"
    State          = "ec2-nat-private-nattest"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_instance_profile" "nat-nattest_profile" {
  name = "nat-nattest_profile"
  role = aws_iam_role.nat-nattest_role.name
  tags = {
    Name           = "nat-nattest_profile"
    State          = "ec2-nat-private-nattest"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "kuma-nattest_role" {
  name = "kuma-nattest_role"
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
    Name           = "kuma-nattest_role"
    State          = "ec2-nat-private-nattest"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "nat-nattest_role" {
  name = "nat-nattest_role"
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
    Name           = "nat-nattest_role"
    State          = "ec2-nat-private-nattest"
    Struct8Creator = "Contato Struct"
  }
}




### CATEGORY: NETWORK ###

resource "aws_vpc" "ec2-nat-private-nattest" {
  cidr_block       = "10.4.0.0/16"
  instance_tenancy = "default"
  tags = {
    Name           = "ec2-nat-private-nattest"
    State          = "ec2-nat-private-nattest"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "private-nattest" {
  vpc_id                  = aws_vpc.ec2-nat-private-nattest.id
  availability_zone       = "us-west-2a"
  cidr_block              = "10.4.2.0/24"
  map_public_ip_on_launch = false
  tags = {
    Name           = "private-nattest"
    State          = "ec2-nat-private-nattest"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "public-nattest" {
  vpc_id                  = aws_vpc.ec2-nat-private-nattest.id
  availability_zone       = "us-west-2a"
  cidr_block              = "10.4.1.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name           = "public-nattest"
    State          = "ec2-nat-private-nattest"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_internet_gateway" "igw-nattest" {
  vpc_id = aws_vpc.ec2-nat-private-nattest.id
  tags = {
    Name           = "igw-nattest"
    State          = "ec2-nat-private-nattest"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route" "route_private-rt-nattest_to_nat-nattest_ipv4" {
  network_interface_id   = aws_instance.nat-nattest.primary_network_interface_id
  route_table_id         = aws_route_table.private-rt-nattest.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route" "route_public-rt-nattest_to_igw-nattest_ipv4" {
  gateway_id             = aws_internet_gateway.igw-nattest.id
  route_table_id         = aws_route_table.public-rt-nattest.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table" "private-rt-nattest" {
  vpc_id = aws_vpc.ec2-nat-private-nattest.id
  tags = {
    Name           = "private-rt-nattest"
    State          = "ec2-nat-private-nattest"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route_table" "public-rt-nattest" {
  vpc_id = aws_vpc.ec2-nat-private-nattest.id
  tags = {
    Name           = "public-rt-nattest"
    State          = "ec2-nat-private-nattest"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route_table_association" "aws_route_table_association_private_nattest_private_rt_nattest" {
  route_table_id = aws_route_table.private-rt-nattest.id
  subnet_id      = aws_subnet.private-nattest.id
}

resource "aws_route_table_association" "aws_route_table_association_public_nattest_public_rt_nattest" {
  route_table_id = aws_route_table.public-rt-nattest.id
  subnet_id      = aws_subnet.public-nattest.id
}

resource "aws_security_group" "instance_kuma-nattest_group" {
  name                   = "instance_kuma-nattest_group"
  vpc_id                 = aws_vpc.ec2-nat-private-nattest.id
  description            = "Uptime Kuma public access"
  revoke_rules_on_delete = false
  tags = {
    Name           = "instance_kuma-nattest_group"
    State          = "ec2-nat-private-nattest"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group" "instance_nat-nattest_group" {
  name                   = "instance_nat-nattest_group"
  vpc_id                 = aws_vpc.ec2-nat-private-nattest.id
  description            = "NAT instance"
  revoke_rules_on_delete = false
  tags = {
    Name           = "instance_nat-nattest_group"
    State          = "ec2-nat-private-nattest"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group_rule" "rule_instance_kuma_nattest_group_egress_all_protocols" {
  security_group_id = aws_security_group.instance_kuma-nattest_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "All outbound"
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "rule_instance_kuma_nattest_group_ingress_tcp_3001" {
  security_group_id = aws_security_group.instance_kuma-nattest_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Kuma web UI"
  from_port         = 3001
  protocol          = "tcp"
  to_port           = 3001
  type              = "ingress"
}

resource "aws_security_group_rule" "rule_instance_nat_nattest_group_egress_all_protocols" {
  security_group_id = aws_security_group.instance_nat-nattest_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "All outbound"
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "rule_instance_nat_nattest_group_ingress_all_protocols" {
  security_group_id = aws_security_group.instance_nat-nattest_group.id
  cidr_blocks       = ["10.4.0.0/16"]
  description       = "All from VPC"
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "ingress"
}

resource "aws_security_group_rule" "rule_instance_nat_nattest_group_ingress_tcp_3001" {
  security_group_id = aws_security_group.instance_nat-nattest_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Kuma UI (forwarded to private)"
  from_port         = 3001
  protocol          = "tcp"
  to_port           = 3001
  type              = "ingress"
}




### CATEGORY: COMPUTE ###

data "local_file" "UserData_kuma-nattest" {
  filename = "${path.module}/.external_modules/struct8-templates/templates/ec2-nat-private/v1/user_data/Kuma.sh"
}

data "aws_ami" "AMI_Data_Source_kuma-nattest" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-kernel-6.1-x86_64"]
  }
}

resource "aws_instance" "kuma-nattest" {
  subnet_id                   = aws_subnet.private-nattest.id
  ami                         = data.aws_ami.AMI_Data_Source_kuma-nattest.id
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.kuma-nattest_profile.name
  instance_type               = "t3.nano"
  private_ip                  = "10.4.2.10"
  user_data_base64 = base64encode(<<-EOFUData
#!/bin/bash

${data.local_file.UserData_kuma-nattest.content}
EOFUData
)
  vpc_security_group_ids = [aws_security_group.instance_kuma-nattest_group.id]
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
    Name           = "kuma-nattest"
    State          = "ec2-nat-private-nattest"
    Struct8Creator = "Contato Struct"
  }
}

data "local_file" "UserData_nat-nattest" {
  filename = "${path.module}/.external_modules/struct8-templates/templates/ec2-nat-private/v1/user_data/Nat.sh"
}

data "aws_ami" "AMI_Data_Source_nat-nattest" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-kernel-6.1-x86_64"]
  }
}

resource "aws_instance" "nat-nattest" {
  subnet_id                   = aws_subnet.public-nattest.id
  ami                         = data.aws_ami.AMI_Data_Source_nat-nattest.id
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.nat-nattest_profile.name
  instance_type               = "t3.nano"
  source_dest_check           = false
  user_data_base64 = base64encode(<<-EOFUData
#!/bin/bash

# --- BEGIN STRUCT8 VARIABLES ---
cat << 'EOFENV' > /etc/struct8_env
FORWARD_PORT="3001"
FORWARD_TARGET="10.4.2.10"
NAME="nat-nattest"
REGION="${data.aws_region.current.region}"
ACCOUNT="${data.aws_caller_identity.current.account_id}"
EOFENV
cat /etc/struct8_env >> /etc/environment
sed 's/^/export /' /etc/struct8_env > /etc/profile.d/struct8_vars.sh
chmod +x /etc/profile.d/struct8_vars.sh
chmod 644 /etc/struct8_env
# --- END STRUCT8 VARIABLES ---

${data.local_file.UserData_nat-nattest.content}
EOFUData
)
  vpc_security_group_ids = [aws_security_group.instance_nat-nattest_group.id]
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
    Name           = "nat-nattest"
    State          = "ec2-nat-private-nattest"
    Struct8Creator = "Contato Struct"
  }
}


