terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  backend "s3" {
    bucket  = "struct8-import"
    key     = "952133486861/ImportVPC2/main.tfstate"
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
    State          = "ImportVPC2"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_egress_only_internet_gateway" "eigw-083dc9b065af87635" {
  vpc_id = aws_vpc.oregon-asg-vpc2.id
  tags = {
    Project        = "oregon-asg"
    Name           = "oregon-asg-eoigw"
    State          = "ImportVPC2"
    Struct8Creator = "Contato Struct"
  }
}


