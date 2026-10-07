terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  backend "s3" {
    bucket  = "struct8-import"
    key     = "952133486861/State3/main.tfstate"
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

data "aws_vpc" "demo-mysql-vpc" {
  filter {
    name   = "tag:Name"
    values = ["demo-mysql-vpc"]
  }
}

data "aws_kms_key" "demo-mysql-kms" {
  key_id = "alias/demo-mysql-kms--LhD-paX"
}




### CATEGORY: NETWORK ###

resource "aws_subnet" "Subnet" {
  vpc_id                  = data.aws_vpc.demo-mysql-vpc.id
  availability_zone       = "us-west-2a"
  cidr_block              = "10.7.2.0/24"
  map_public_ip_on_launch = false
  tags = {
    Name           = "Subnet"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "Subnet1" {
  vpc_id                  = data.aws_vpc.demo-mysql-vpc.id
  availability_zone       = "us-west-2b"
  cidr_block              = "10.7.3.0/24"
  map_public_ip_on_launch = false
  tags = {
    Name           = "Subnet1"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group" "db_instance_demo-mysql-new_group" {
  name                   = "db_instance_demo-mysql-new_group"
  vpc_id                 = data.aws_vpc.demo-mysql-vpc.id
  revoke_rules_on_delete = false
  tags = {
    Name           = "db_instance_demo-mysql-new_group"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group_rule" "rule_db_instance_demo_mysql_new_group_egress_all_protocols" {
  security_group_id = aws_security_group.db_instance_demo-mysql-new_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}




### CATEGORY: DATABASE ###

data "aws_resourcegroupstaggingapi_resources" "option_group_demo-mysql-options" {
  resource_type_filters = ["rds:og"]
  lifecycle {
    postcondition {
      condition     = length(self.resource_tag_mapping_list) > 0
      error_message = "No RDS option group tagged Name=demo-mysql-options exists in this region. Apply the state that creates it before this one."
    }
    postcondition {
      condition     = length(self.resource_tag_mapping_list) < 2
      error_message = "More than one RDS option group is tagged Name=demo-mysql-options in this region, and this state cannot tell which one to use. Leave one group with that name."
    }
  }
  tag_filter {
    key    = "Name"
    values = ["demo-mysql-options"]
  }
}

data "aws_resourcegroupstaggingapi_resources" "parameter_group_demo-mysql-params" {
  resource_type_filters = ["rds:pg"]
  lifecycle {
    postcondition {
      condition     = length(self.resource_tag_mapping_list) > 0
      error_message = "No RDS DB parameter group tagged Name=demo-mysql-params exists in this region. Apply the state that creates it before this one."
    }
    postcondition {
      condition     = length(self.resource_tag_mapping_list) < 2
      error_message = "More than one RDS DB parameter group is tagged Name=demo-mysql-params in this region, and this state cannot tell which one to use. Leave one group with that name."
    }
  }
  tag_filter {
    key    = "Name"
    values = ["demo-mysql-params"]
  }
}

resource "aws_db_instance" "demo-mysql-new" {
  db_subnet_group_name     = aws_db_subnet_group.subnet_group_demo-mysql-new.name
  kms_key_id               = data.aws_kms_key.demo-mysql-kms.arn
  option_group_name        = element(split(":", data.aws_resourcegroupstaggingapi_resources.option_group_demo-mysql-options.resource_tag_mapping_list[0].resource_arn), 6)
  parameter_group_name     = element(split(":", data.aws_resourcegroupstaggingapi_resources.parameter_group_demo-mysql-params.resource_tag_mapping_list[0].resource_arn), 6)
  allocated_storage        = 20
  availability_zone        = aws_subnet.Subnet.availability_zone
  backup_retention_period  = 0
  copy_tags_to_snapshot    = true
  delete_automated_backups = false
  engine_lifecycle_support = "open-source-rds-extended-support-disabled"
  identifier               = "demo-mysql-new"
  instance_class           = "db.t3.micro"
  max_allocated_storage    = 100
  skip_final_snapshot      = true
  snapshot_identifier      = "dbsnapshot"
  storage_encrypted        = true
  storage_type             = "gp3"
  upgrade_storage_config   = false
  vpc_security_group_ids   = [aws_security_group.db_instance_demo-mysql-new_group.id]
  lifecycle {
    ignore_changes = [snapshot_identifier]
  }
  tags = {
    Name           = "demo-mysql-new"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_db_subnet_group" "subnet_group_demo-mysql-new" {
  name       = "demo-mysql-new-subnet-group"
  subnet_ids = [aws_subnet.Subnet.id, aws_subnet.Subnet1.id]
  tags = {
    Name           = "subnet_group_demo-mysql-new"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}


