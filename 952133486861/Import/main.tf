terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  backend "s3" {
    bucket  = "struct8-import"
    key     = "952133486861/Import/main.tfstate"
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
  from = aws_route_table_association.aws_route_table_association_oregon_net_public_ax_oregon_net_rt_public
  to   = aws_route_table_association.aws_route_table_association_oregon_net_public_ay_oregon_net_rt_public
}

moved {
  from = aws_subnet.oregon-net-public-ax
  to   = aws_subnet.oregon-net-public-ay
}




### CATEGORY: NETWORK ###

resource "aws_vpc" "oregon-net-vpc" {
  cidr_block           = "10.20.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default"
  tags = {
    Project        = "oregon-net"
    Name           = "oregon-net-vpc"
    State          = "Import"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_vpc_endpoint" "oregon-net-vpce-s3_DynamoDB" {
  service_name      = "com.amazonaws.us-west-2.dynamodb"
  vpc_id            = aws_vpc.oregon-net-vpc.id
  policy            = "{\"Statement\":[{\"Action\":\"*\",\"Effect\":\"Allow\",\"Principal\":\"*\",\"Resource\":\"*\"}],\"Version\":\"2008-10-17\"}"
  route_table_ids   = [aws_route_table.oregon-net-rt-private-a.id, aws_route_table.oregon-net-rt-private-c.id, aws_route_table.oregon-net-rt-private-b.id]
  vpc_endpoint_type = "Gateway"
  tags = {
    DifName        = "oregon-net-vpce-s3_DynamoDB"
    Name           = "oregon-net-vpce-s3"
    State          = "Import"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_vpc_endpoint" "oregon-net-vpce-s3_S3" {
  service_name      = "com.amazonaws.us-west-2.s3"
  vpc_id            = aws_vpc.oregon-net-vpc.id
  policy            = "{\"Statement\":[{\"Action\":\"*\",\"Effect\":\"Allow\",\"Principal\":\"*\",\"Resource\":\"*\"}],\"Version\":\"2008-10-17\"}"
  route_table_ids   = [aws_route_table.oregon-net-rt-private-a.id, aws_route_table.oregon-net-rt-private-c.id, aws_route_table.oregon-net-rt-private-b.id]
  vpc_endpoint_type = "Gateway"
  tags = {
    DifName        = "oregon-net-vpce-s3"
    Name           = "oregon-net-vpce-s3"
    State          = "Import"
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
    State          = "Import"
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
    State          = "Import"
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
    State          = "Import"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "oregon-net-public-ay" {
  vpc_id                              = aws_vpc.oregon-net-vpc.id
  availability_zone                   = "us-west-2a"
  cidr_block                          = "10.20.0.0/24"
  map_public_ip_on_launch             = true
  private_dns_hostname_type_on_launch = "ip-name"
  tags = {
    Project        = "oregon-net"
    Name           = "oregon-net-public-ay"
    State          = "Import"
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
    State          = "Import"
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
    State          = "Import"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_internet_gateway" "oregon-net-igw" {
  vpc_id = aws_vpc.oregon-net-vpc.id
  tags = {
    Project        = "oregon-net"
    Name           = "oregon-net-igw"
    State          = "Import"
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
    State          = "Import"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route_table" "oregon-net-rt-private-b" {
  vpc_id = aws_vpc.oregon-net-vpc.id
  tags = {
    Project        = "oregon-net"
    Name           = "oregon-net-rt-private-b"
    State          = "Import"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route_table" "oregon-net-rt-private-c" {
  vpc_id = aws_vpc.oregon-net-vpc.id
  tags = {
    Project        = "oregon-net"
    Name           = "oregon-net-rt-private-c"
    State          = "Import"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route_table" "oregon-net-rt-public" {
  vpc_id = aws_vpc.oregon-net-vpc.id
  tags = {
    Project        = "oregon-net"
    Name           = "oregon-net-rt-public"
    State          = "Import"
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

resource "aws_route_table_association" "aws_route_table_association_oregon_net_public_ay_oregon_net_rt_public" {
  route_table_id = aws_route_table.oregon-net-rt-public.id
  subnet_id      = aws_subnet.oregon-net-public-ay.id
}

resource "aws_route_table_association" "aws_route_table_association_oregon_net_public_b_oregon_net_rt_public" {
  route_table_id = aws_route_table.oregon-net-rt-public.id
  subnet_id      = aws_subnet.oregon-net-public-b.id
}

resource "aws_route_table_association" "aws_route_table_association_oregon_net_public_c_oregon_net_rt_public" {
  route_table_id = aws_route_table.oregon-net-rt-public.id
  subnet_id      = aws_subnet.oregon-net-public-c.id
}


