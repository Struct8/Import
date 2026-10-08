terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  backend "s3" {
    bucket  = "struct8-import"
    key     = "952133486861/ec2-windows-secure/main.tfstate"
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

resource "aws_iam_instance_profile" "nat-windows-secure_profile" {
  name = "nat-windows-secure_profile"
  role = aws_iam_role.nat-windows-secure_role.name
  tags = {
    Name           = "nat-windows-secure_profile"
    State          = "ec2-windows-secure"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_instance_profile" "windows-secure_profile" {
  name = "windows-secure_profile"
  role = aws_iam_role.windows-secure_role.name
  tags = {
    Name           = "windows-secure_profile"
    State          = "ec2-windows-secure"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "nat-windows-secure_role" {
  name = "nat-windows-secure_role"
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
    Name           = "nat-windows-secure_role"
    State          = "ec2-windows-secure"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "windows-secure_role" {
  name = "windows-secure_role"
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
    Name           = "windows-secure_role"
    State          = "ec2-windows-secure"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role_policy_attachment" "AmazonSSMManagedInstanceCore_to_windows-secure_attach" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.windows-secure_role.name
}

resource "aws_iam_role_policy_attachment" "AmazonSSMManagedInstanceCore_to_windows-secure_profile_attach" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.windows-secure_role.name
}




### CATEGORY: NETWORK ###

resource "aws_vpc" "vpc-windows-secure" {
  cidr_block       = "10.4.0.0/16"
  instance_tenancy = "default"
  tags = {
    Name           = "vpc-windows-secure"
    State          = "ec2-windows-secure"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "private-windows-secure" {
  vpc_id                  = aws_vpc.vpc-windows-secure.id
  availability_zone       = "us-west-2a"
  cidr_block              = "10.4.2.0/24"
  map_public_ip_on_launch = false
  tags = {
    Name           = "private-windows-secure"
    State          = "ec2-windows-secure"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "public-windows-secure" {
  vpc_id                  = aws_vpc.vpc-windows-secure.id
  availability_zone       = "us-west-2a"
  cidr_block              = "10.4.1.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name           = "public-windows-secure"
    State          = "ec2-windows-secure"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_internet_gateway" "igw-windows-secure" {
  vpc_id = aws_vpc.vpc-windows-secure.id
  tags = {
    Name           = "igw-windows-secure"
    State          = "ec2-windows-secure"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route" "route_rt-private-windows-secure_to_nat-windows-secure_ipv4" {
  network_interface_id   = aws_instance.nat-windows-secure.primary_network_interface_id
  route_table_id         = aws_route_table.rt-private-windows-secure.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route" "route_rt-public-windows-secure_to_igw-windows-secure_ipv4" {
  gateway_id             = aws_internet_gateway.igw-windows-secure.id
  route_table_id         = aws_route_table.rt-public-windows-secure.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table" "rt-private-windows-secure" {
  vpc_id = aws_vpc.vpc-windows-secure.id
  tags = {
    Name           = "rt-private-windows-secure"
    State          = "ec2-windows-secure"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route_table" "rt-public-windows-secure" {
  vpc_id = aws_vpc.vpc-windows-secure.id
  tags = {
    Name           = "rt-public-windows-secure"
    State          = "ec2-windows-secure"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route_table_association" "aws_route_table_association_private_windows_secure_rt_private_windows_secure" {
  route_table_id = aws_route_table.rt-private-windows-secure.id
  subnet_id      = aws_subnet.private-windows-secure.id
}

resource "aws_route_table_association" "aws_route_table_association_public_windows_secure_rt_public_windows_secure" {
  route_table_id = aws_route_table.rt-public-windows-secure.id
  subnet_id      = aws_subnet.public-windows-secure.id
}

resource "aws_security_group" "instance_nat-windows-secure_group" {
  name                   = "instance_nat-windows-secure_group"
  vpc_id                 = aws_vpc.vpc-windows-secure.id
  description            = "NAT instance of the Windows lab"
  revoke_rules_on_delete = false
  tags = {
    Name           = "instance_nat-windows-secure_group"
    State          = "ec2-windows-secure"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group" "instance_windows-secure_group" {
  name                   = "instance_windows-secure_group"
  vpc_id                 = aws_vpc.vpc-windows-secure.id
  description            = "Windows lab instance, no inbound rules"
  revoke_rules_on_delete = false
  tags = {
    Name           = "instance_windows-secure_group"
    State          = "ec2-windows-secure"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group_rule" "rule_instance_nat_windows_secure_group_egress_all_protocols" {
  security_group_id = aws_security_group.instance_nat-windows-secure_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "All outbound"
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "rule_instance_nat_windows_secure_group_ingress_all_protocols" {
  security_group_id = aws_security_group.instance_nat-windows-secure_group.id
  cidr_blocks       = ["10.4.0.0/16"]
  description       = "All from VPC"
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "ingress"
}

resource "aws_security_group_rule" "rule_instance_windows_secure_group_egress_all_protocols" {
  security_group_id = aws_security_group.instance_windows-secure_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}




### CATEGORY: COMPUTE ###

data "local_file" "UserData_nat-windows-secure" {
  filename = "${path.module}/.external_modules/struct8-templates/templates/ec2-nat-private/v1/user_data/Nat.sh"
}

data "aws_ami" "AMI_Data_Source_nat-windows-secure" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-kernel-6.1-x86_64"]
  }
}

resource "aws_instance" "nat-windows-secure" {
  subnet_id                   = aws_subnet.public-windows-secure.id
  ami                         = data.aws_ami.AMI_Data_Source_nat-windows-secure.id
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.nat-windows-secure_profile.name
  instance_type               = "t3.nano"
  source_dest_check           = false
  user_data_base64 = base64encode(<<-EOFUData
#!/bin/bash

${data.local_file.UserData_nat-windows-secure.content}
EOFUData
)
  vpc_security_group_ids = [aws_security_group.instance_nat-windows-secure_group.id]
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
    Name           = "nat-windows-secure"
    State          = "ec2-windows-secure"
    Struct8Creator = "Contato Struct"
  }
}

data "aws_ami" "AMI_Data_Source_windows-secure" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["Windows_Server-2025-English-Full-Base-*"]
  }
}

resource "aws_instance" "windows-secure" {
  key_name                    = aws_cloudformation_stack.windows-secure-key.outputs["KeyName"]
  subnet_id                   = aws_subnet.private-windows-secure.id
  ami                         = data.aws_ami.AMI_Data_Source_windows-secure.id
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.windows-secure_profile.name
  instance_type               = "t3.medium"
  vpc_security_group_ids      = [aws_security_group.instance_windows-secure_group.id]
  lifecycle {
    ignore_changes = [ami, user_data]
  }
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
  root_block_device {
    encrypted   = true
    iops        = 3000
    throughput  = 125
    volume_size = 75
    volume_type = "gp3"
  }
  tags = {
    Name           = "windows-secure"
    State          = "ec2-windows-secure"
    Struct8Creator = "Contato Struct"
  }
}




### CATEGORY: MISC ###

resource "aws_cloudformation_stack" "windows-secure-key" {
  name          = "struct8-keypair-windows-secure-key"
  template_body = jsonencode({ Resources = { KeyPair = { Type = "AWS::EC2::KeyPair", Properties = { KeyName = "windows-secure-key", KeyType = "rsa", KeyFormat = "pem" } } }, Outputs = { KeyName = { Value = { Ref = "KeyPair" } }, KeyPairId = { Value = { "Fn::GetAtt" = ["KeyPair", "KeyPairId"] } } } })
  tags = {
    Name           = "windows-secure-key"
    State          = "ec2-windows-secure"
    Struct8Creator = "Contato Struct"
  }
}


