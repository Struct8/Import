terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  backend "s3" {
    bucket  = "struct8-import"
    key     = "952133486861/State-Peering/main.tfstate"
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

data "aws_vpc" "VPC-Monitored" {
  filter {
    name   = "tag:Name"
    values = ["VPC-Monitored"]
  }
}

data "aws_vpc" "VPC-Monitoring" {
  filter {
    name   = "tag:Name"
    values = ["VPC-Monitoring"]
  }
}

data "aws_route_table" "RT-private-a" {
  filter {
    name   = "tag:Name"
    values = ["RT-private-a"]
  }
}

data "aws_route_table" "RT-private-b" {
  filter {
    name   = "tag:Name"
    values = ["RT-private-b"]
  }
}

data "aws_route_table" "RT-public-a" {
  filter {
    name   = "tag:Name"
    values = ["RT-public-a"]
  }
}

data "aws_route_table" "RT-public-b" {
  filter {
    name   = "tag:Name"
    values = ["RT-public-b"]
  }
}




### CATEGORY: NETWORK ###

resource "aws_vpc_peering_connection" "Peering-Monitoring-to-Monitored" {
  peer_vpc_id = data.aws_vpc.VPC-Monitored.id
  vpc_id      = data.aws_vpc.VPC-Monitoring.id
  auto_accept = true
  tags = {
    Name           = "Peering-Monitoring-to-Monitored"
    State          = "State-Peering"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route" "route_RT-private-a_to_Peering-Monitoring-to-Monitored_10_1_0_0_16" {
  route_table_id            = data.aws_route_table.RT-private-a.id
  vpc_peering_connection_id = aws_vpc_peering_connection.Peering-Monitoring-to-Monitored.id
  destination_cidr_block    = "10.1.0.0/16"
}

resource "aws_route" "route_RT-private-b_to_Peering-Monitoring-to-Monitored_10_5_0_0_16" {
  route_table_id            = data.aws_route_table.RT-private-b.id
  vpc_peering_connection_id = aws_vpc_peering_connection.Peering-Monitoring-to-Monitored.id
  destination_cidr_block    = "10.5.0.0/16"
}

resource "aws_route" "route_RT-public-a_to_Peering-Monitoring-to-Monitored_10_1_0_0_24" {
  route_table_id            = data.aws_route_table.RT-public-a.id
  vpc_peering_connection_id = aws_vpc_peering_connection.Peering-Monitoring-to-Monitored.id
  destination_cidr_block    = "10.1.0.0/24"
}

resource "aws_route" "route_RT-public-b_to_Peering-Monitoring-to-Monitored_10_5_0_0_24" {
  route_table_id            = data.aws_route_table.RT-public-b.id
  vpc_peering_connection_id = aws_vpc_peering_connection.Peering-Monitoring-to-Monitored.id
  destination_cidr_block    = "10.5.0.0/24"
}


