terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  backend "s3" {
    bucket  = "struct8-import"
    key     = "952133486861/tgw-core-lab/main.tfstate"
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

resource "aws_ec2_transit_gateway" "tgw-lab" {
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  description                     = "Hub and spoke with centralized egress through vpc-hub"
  tags = {
    Name           = "tgw-lab"
    State          = "tgw-core-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_ec2_transit_gateway_route" "tgw-rt-spokes_blackhole_10_0_0_0_8" {
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw-rt-spokes.id
  blackhole                      = true
  destination_cidr_block         = "10.0.0.0/8"
}

resource "aws_ec2_transit_gateway_route_table" "tgw-rt-hub" {
  transit_gateway_id = aws_ec2_transit_gateway.tgw-lab.id
  tags = {
    Name           = "tgw-rt-hub"
    State          = "tgw-core-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_ec2_transit_gateway_route_table" "tgw-rt-spokes" {
  transit_gateway_id = aws_ec2_transit_gateway.tgw-lab.id
  tags = {
    Name           = "tgw-rt-spokes"
    State          = "tgw-core-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_ec2_transit_gateway_route_table_association" "onprem-vpn_tgw-rt-hub_association" {
  transit_gateway_attachment_id  = aws_vpn_connection.onprem-vpn.transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw-rt-hub.id
  replace_existing_association   = true
}

resource "aws_ec2_transit_gateway_route_table_propagation" "onprem-vpn_tgw-rt-spokes_propagation" {
  transit_gateway_attachment_id  = aws_vpn_connection.onprem-vpn.transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw-rt-spokes.id
}

resource "aws_vpn_connection" "onprem-vpn" {
  customer_gateway_id = aws_customer_gateway.onprem-cgw.id
  transit_gateway_id  = aws_ec2_transit_gateway.tgw-lab.id
  type                = "ipsec.1"
  tags = {
    Name           = "onprem-vpn"
    State          = "tgw-core-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_customer_gateway" "onprem-cgw" {
  # ajuste manual · lifecycle.create_before_destroy — Replacing the customer gateway (new ip_address) failed with 'The customer gateway is in use': the VPN connection still points at the old one when Terraform destroys it. Creating the new gateway first lets the VPN connection switch to it in place.
  bgp_asn    = "65000"
  ip_address = "18.217.1.198"
  type       = "ipsec.1"
  lifecycle {
    create_before_destroy = true
  }
  tags = {
    Name           = "onprem-cgw"
    State          = "tgw-core-lab"
    Struct8Creator = "Contato Struct"
  }
}


