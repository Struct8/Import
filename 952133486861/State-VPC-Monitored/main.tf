terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  backend "s3" {
    bucket  = "struct8-import"
    key     = "952133486861/State-VPC-Monitored/main.tfstate"
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

resource "aws_vpc" "VPC-Monitored" {
  cidr_block       = "10.1.0.0/16"
  instance_tenancy = "default"
  tags = {
    Name           = "VPC-Monitored"
    State          = "State-VPC-Monitored"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "subnet-private-b" {
  vpc_id                  = aws_vpc.VPC-Monitored.id
  availability_zone       = "us-west-2a"
  cidr_block              = "10.1.1.0/24"
  map_public_ip_on_launch = false
  tags = {
    Name           = "subnet-private-b"
    State          = "State-VPC-Monitored"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "subnet-public-b" {
  vpc_id                  = aws_vpc.VPC-Monitored.id
  availability_zone       = "us-west-2a"
  cidr_block              = "10.1.0.0/24"
  map_public_ip_on_launch = false
  tags = {
    Name           = "subnet-public-b"
    State          = "State-VPC-Monitored"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route_table" "RT-private-b" {
  vpc_id = aws_vpc.VPC-Monitored.id
  tags = {
    Name           = "RT-private-b"
    State          = "State-VPC-Monitored"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route_table" "RT-public-b" {
  vpc_id = aws_vpc.VPC-Monitored.id
  tags = {
    Name           = "RT-public-b"
    State          = "State-VPC-Monitored"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route_table_association" "aws_route_table_association_subnet_private_b_RT_private_b" {
  route_table_id = aws_route_table.RT-private-b.id
  subnet_id      = aws_subnet.subnet-private-b.id
}

resource "aws_route_table_association" "aws_route_table_association_subnet_public_b_RT_public_b" {
  route_table_id = aws_route_table.RT-public-b.id
  subnet_id      = aws_subnet.subnet-public-b.id
}


