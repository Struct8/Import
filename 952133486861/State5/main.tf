terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  backend "s3" {
    bucket  = "struct8-import"
    key     = "952133486861/State5/main.tfstate"
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

data "aws_vpc" "oregon-asg-vpc2" {
  filter {
    name   = "tag:Name"
    values = ["oregon-asg-vpc2"]
  }
}

data "aws_vpc" "oregon-net-vpc" {
  filter {
    name   = "tag:Name"
    values = ["oregon-net-vpc"]
  }
}

data "aws_route_table" "oregon-net-rt-public" {
  filter {
    name   = "tag:Name"
    values = ["oregon-net-rt-public"]
  }
}




### CATEGORY: NETWORK ###

resource "aws_vpc_peering_connection" "pcx-0659fe288fc855311" {
  peer_vpc_id = data.aws_vpc.oregon-asg-vpc2.id
  vpc_id      = data.aws_vpc.oregon-net-vpc.id
  accepter {
    allow_remote_vpc_dns_resolution = false
  }
  requester {
    allow_remote_vpc_dns_resolution = false
  }
  tags = {
    Name           = "oregon-asg-pcx"
    State          = "Import"
    Struct8Creator = "Contato Struct"
    Project        = "oregon-asg"
  }
}

resource "aws_route" "route_oregon-net-rt-public_to_pcx-0659fe288fc855311_10_30_0_0_16" {
  route_table_id            = data.aws_route_table.oregon-net-rt-public.id
  vpc_peering_connection_id = aws_vpc_peering_connection.pcx-0659fe288fc855311.id
  destination_cidr_block    = "10.30.0.0/16"
}


