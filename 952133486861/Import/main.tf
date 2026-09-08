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

### CATEGORY: IAM ###

resource "aws_iam_openid_connect_provider" "token_actions_githubusercontent_com" {
  name = "token_actions_githubusercontent_com"
  tags = {
    Name           = "token_actions_githubusercontent_com"
    State          = "Import"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "Struct8-Gitops-Struct8-import" {
  name                  = "Struct8-Gitops-Struct8-import"
  assume_role_policy    = "{\"Statement\":[{\"Action\":\"sts:AssumeRoleWithWebIdentity\",\"Condition\":{\"StringEquals\":{\"token.actions.githubusercontent.com:aud\":\"sts.amazonaws.com\"},\"StringEqualsIgnoreCase\":{\"token.actions.githubusercontent.com:sub\":[\"repo:Struct8@276103125/Import@1360758768:ref:refs/heads/main:job_workflow_ref:Struct8/cloudman-core/.github/workflows/engine.yml@refs/heads/devlocal\",\"repo:Struct8@276103125/Import@1360758768:ref:refs/heads/main:job_workflow_ref:Struct8/cloudman-core/.github/workflows/engine.yml@refs/heads/dev\",\"repo:Struct8@276103125/Import@1360758768:ref:refs/heads/main:job_workflow_ref:Struct8/cloudman-core/.github/workflows/engine.yml@refs/heads/test\",\"repo:Struct8@276103125/Import@1360758768:ref:refs/heads/main:job_workflow_ref:Struct8/cloudman-core/.github/workflows/engine.yml@refs/heads/alpha\",\"repo:Struct8@276103125/Import@1360758768:ref:refs/heads/main:job_workflow_ref:Struct8/cloudman-core/.github/workflows/engine.yml@refs/heads/main\",\"repo:Struct8@276103125/Import@1360758768:ref:refs/heads/main:job_workflow_ref:Struct8/cloudman-core/.github/workflows/lambda-sync.yml@refs/heads/main\"]}},\"Effect\":\"Allow\",\"Principal\":{\"Federated\":\"arn:aws:iam::952133486861:oidc-provider/token.actions.githubusercontent.com\"}}],\"Version\":\"2012-10-17\"}"
  force_detach_policies = false
  max_session_duration  = 3600
  path                  = "/"
  inline_policy {
    name   = "Struct8ProtectOwnTrust"
    policy = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Action\":[\"iam:UpdateAssumeRolePolicy\",\"iam:UpdateRole\",\"iam:DeleteRole\",\"iam:PutRolePolicy\",\"iam:DeleteRolePolicy\",\"iam:AttachRolePolicy\",\"iam:DetachRolePolicy\",\"iam:PutRolePermissionsBoundary\",\"iam:DeleteRolePermissionsBoundary\"],\"Effect\":\"Deny\",\"Resource\":\"arn:aws:iam::952133486861:role/Struct8-Gitops-Struct8-import\"},{\"Action\":[\"iam:DeleteOpenIDConnectProvider\",\"iam:UpdateOpenIDConnectProviderThumbprint\",\"iam:AddClientIDToOpenIDConnectProvider\",\"iam:RemoveClientIDFromOpenIDConnectProvider\"],\"Effect\":\"Deny\",\"Resource\":\"arn:aws:iam::952133486861:oidc-provider/token.actions.githubusercontent.com\"},{\"Action\":[\"cloudtrail:StopLogging\",\"cloudtrail:DeleteTrail\",\"cloudtrail:UpdateTrail\",\"cloudtrail:PutEventSelectors\"],\"Effect\":\"Deny\",\"Resource\":\"*\"}]}"
  }
  tags = {
    Name           = "Struct8-Gitops-Struct8-import"
    State          = "Struct8-Gitops-Struct8-import"
    Struct8User    = "Contato Struct"
    Struct8Creator = "Contato Struct"
  }
}




### CATEGORY: NETWORK ###

resource "aws_vpc" "oregon-net-vpc" {
  cidr_block           = "10.20.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default"
  tags = {
    Name           = "oregon-net-vpc"
    Project        = "oregon-net"
    State          = "Import"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_vpc_endpoint" "oregon-net-vpce-dynamodb_DynamoDB" {
  service_name      = "com.amazonaws.us-west-2.dynamodb"
  vpc_id            = aws_vpc.oregon-net-vpc.id
  policy            = "{\"Statement\":[{\"Action\":\"*\",\"Effect\":\"Allow\",\"Principal\":\"*\",\"Resource\":\"*\"}],\"Version\":\"2008-10-17\"}"
  route_table_ids   = [aws_route_table.oregon-net-rt-private-a.id, aws_route_table.oregon-net-rt-private-c.id, aws_route_table.oregon-net-rt-private-b.id]
  vpc_endpoint_type = "Gateway"
  tags = {
    Name           = "oregon-net-vpce-dynamodb"
    Project        = "oregon-net"
    DifName        = "oregon-net-vpce-dynamodb"
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
    Name           = "oregon-net-vpce-s3"
    Project        = "oregon-net"
    DifName        = "oregon-net-vpce-s3"
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
    Name           = "oregon-net-private-a"
    Project        = "oregon-net"
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
    Name           = "oregon-net-private-b"
    Project        = "oregon-net"
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
    Name           = "oregon-net-private-c"
    Project        = "oregon-net"
    State          = "Import"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "oregon-net-public-a" {
  vpc_id                              = aws_vpc.oregon-net-vpc.id
  availability_zone                   = "us-west-2a"
  cidr_block                          = "10.20.0.0/24"
  map_public_ip_on_launch             = true
  private_dns_hostname_type_on_launch = "ip-name"
  tags = {
    Name           = "oregon-net-public-a"
    Project        = "oregon-net"
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
    Name           = "oregon-net-public-b"
    Project        = "oregon-net"
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
    Name           = "oregon-net-public-c"
    Project        = "oregon-net"
    State          = "Import"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_internet_gateway" "oregon-net-igw" {
  vpc_id = aws_vpc.oregon-net-vpc.id
  tags = {
    Name           = "oregon-net-igw"
    Project        = "oregon-net"
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
    Name           = "oregon-net-rt-private-a"
    Project        = "oregon-net"
    State          = "Import"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route_table" "oregon-net-rt-private-b" {
  vpc_id = aws_vpc.oregon-net-vpc.id
  tags = {
    Name           = "oregon-net-rt-private-b"
    Project        = "oregon-net"
    State          = "Import"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route_table" "oregon-net-rt-private-c" {
  vpc_id = aws_vpc.oregon-net-vpc.id
  tags = {
    Name           = "oregon-net-rt-private-c"
    Project        = "oregon-net"
    State          = "Import"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route_table" "oregon-net-rt-public" {
  vpc_id = aws_vpc.oregon-net-vpc.id
  tags = {
    Name           = "oregon-net-rt-public"
    Project        = "oregon-net"
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

resource "aws_route_table_association" "aws_route_table_association_oregon_net_public_a_oregon_net_rt_public" {
  route_table_id = aws_route_table.oregon-net-rt-public.id
  subnet_id      = aws_subnet.oregon-net-public-a.id
}

resource "aws_route_table_association" "aws_route_table_association_oregon_net_public_b_oregon_net_rt_public" {
  route_table_id = aws_route_table.oregon-net-rt-public.id
  subnet_id      = aws_subnet.oregon-net-public-b.id
}

resource "aws_route_table_association" "aws_route_table_association_oregon_net_public_c_oregon_net_rt_public" {
  route_table_id = aws_route_table.oregon-net-rt-public.id
  subnet_id      = aws_subnet.oregon-net-public-c.id
}


