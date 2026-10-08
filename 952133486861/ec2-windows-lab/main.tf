terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    tls = {
      source = "hashicorp/tls"
    }
  }

  backend "s3" {
    bucket  = "struct8-import"
    key     = "952133486861/ec2-windows-lab/main.tfstate"
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

resource "aws_iam_instance_profile" "windows-lab_profile" {
  name = "windows-lab_profile"
  role = aws_iam_role.windows-lab_role.name
  tags = {
    Name           = "windows-lab_profile"
    State          = "ec2-windows-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "windows-lab_role" {
  name = "windows-lab_role"
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
    Name           = "windows-lab_role"
    State          = "ec2-windows-lab"
    Struct8Creator = "Contato Struct"
  }
}




### CATEGORY: NETWORK ###

resource "aws_vpc" "VPC" {
  cidr_block           = "10.25.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default"
  tags = {
    Name           = "VPC"
    State          = "ec2-windows-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "pubA2" {
  vpc_id                  = aws_vpc.VPC.id
  availability_zone       = "us-west-2a"
  cidr_block              = "10.25.1.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name           = "pubA2"
    State          = "ec2-windows-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_internet_gateway" "igw-windows-lab" {
  vpc_id = aws_vpc.VPC.id
  tags = {
    Name           = "igw-windows-lab"
    State          = "ec2-windows-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route" "route_rt-public-windows-lab_to_igw-windows-lab_ipv4" {
  gateway_id             = aws_internet_gateway.igw-windows-lab.id
  route_table_id         = aws_route_table.rt-public-windows-lab.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table" "rt-public-windows-lab" {
  vpc_id = aws_vpc.VPC.id
  tags = {
    Name           = "rt-public-windows-lab"
    State          = "ec2-windows-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route_table_association" "aws_route_table_association_pubA2_rt_public_windows_lab" {
  route_table_id = aws_route_table.rt-public-windows-lab.id
  subnet_id      = aws_subnet.pubA2.id
}

resource "aws_security_group" "instance_windows-lab_group" {
  name                   = "instance_windows-lab_group"
  vpc_id                 = aws_vpc.VPC.id
  description            = "RDP to the Windows lab instance, from one IP only"
  revoke_rules_on_delete = false
  tags = {
    Name           = "instance_windows-lab_group"
    State          = "ec2-windows-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group_rule" "rule_instance_windows_lab_group_egress_all_protocols" {
  security_group_id = aws_security_group.instance_windows-lab_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "rule_instance_windows_lab_group_ingress_tcp_3389" {
  security_group_id = aws_security_group.instance_windows-lab_group.id
  cidr_blocks       = ["45.166.205.227/32"]
  description       = "RDP from the student"
  from_port         = 3389
  protocol          = "tcp"
  to_port           = 3389
  type              = "ingress"
}

resource "aws_eip" "windows-lab-eip" {
  instance = aws_instance.windows-lab.id
  tags = {
    Name           = "windows-lab-eip"
    State          = "ec2-windows-lab"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_internet_gateway.igw-windows-lab]
}




### CATEGORY: COMPUTE ###

data "aws_ami" "AMI_Data_Source_windows-lab" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["Windows_Server-2025-English-Full-Base-*"]
  }
}

resource "aws_instance" "windows-lab" {
  key_name                    = aws_key_pair.windows-lab-key.key_name
  subnet_id                   = aws_subnet.pubA2.id
  ami                         = data.aws_ami.AMI_Data_Source_windows-lab.id
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.windows-lab_profile.name
  instance_type               = "t3.medium"
  vpc_security_group_ids      = [aws_security_group.instance_windows-lab_group.id]
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
    volume_size = 75
    volume_type = "gp3"
  }
  tags = {
    Name           = "windows-lab"
    State          = "ec2-windows-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_key_pair" "windows-lab-key" {
  key_name   = "windows-lab-key"
  public_key = tls_private_key.windows-lab-key.public_key_openssh
  tags = {
    Name           = "windows-lab-key"
    State          = "ec2-windows-lab"
    Struct8Creator = "Contato Struct"
  }
}




### CATEGORY: CONFIG ###

resource "aws_ssm_parameter" "windows-lab-key_private_key" {
  name        = "/ec2/keypair/${aws_key_pair.windows-lab-key.key_pair_id}"
  description = "Private key of the EC2 key pair ${aws_key_pair.windows-lab-key.key_name}, in PEM"
  type        = "SecureString"
  value       = tls_private_key.windows-lab-key.private_key_pem
  tags = {
    Name           = "windows-lab-key_private_key"
    State          = "ec2-windows-lab"
    Struct8Creator = "Contato Struct"
  }
}




### CATEGORY: MISC ###

resource "tls_private_key" "windows-lab-key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}


