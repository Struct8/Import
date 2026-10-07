terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  backend "s3" {
    bucket  = "struct8-import"
    key     = "952133486861/demo-mysql-vpc/main.tfstate"
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

resource "aws_kms_alias" "demo-mysql-kms_cross_state_alias" {
  name          = "alias/demo-mysql-kms--LhD-paX"
  target_key_id = aws_kms_key.demo-mysql-kms.key_id
}

resource "aws_kms_key" "demo-mysql-kms" {
  bypass_policy_lockout_safety_check = false
  customer_master_key_spec           = "SYMMETRIC_DEFAULT"
  deletion_window_in_days            = 30
  description                        = "CMK da demo RDS: criptografa o storage do demo-mysql e os CloudWatch Log Groups."
  enable_key_rotation                = true
  is_enabled                         = true
  key_usage                          = "ENCRYPT_DECRYPT"
  multi_region                       = false
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Enable IAM User Permissions",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      },
      "Action": "kms:*",
      "Resource": "*"
    }
  ]
}
  EOF
  rotation_period_in_days = 365
  tags = {
    Name           = "demo-mysql-kms"
    State          = "demo-mysql-vpc"
    Struct8Creator = "Contato Struct"
  }
}




### CATEGORY: NETWORK ###

resource "aws_vpc" "demo-mysql-vpc" {
  cidr_block       = "10.7.0.0/16"
  instance_tenancy = "default"
  tags = {
    Name           = "demo-mysql-vpc"
    State          = "demo-mysql-vpc"
    Struct8Creator = "Contato Struct"
  }
}




### CATEGORY: DATABASE ###

resource "aws_db_option_group" "demo-mysql-options" {
  engine_name              = "mysql"
  major_engine_version     = "8.4"
  name_prefix              = "demo-mysql-options"
  option_group_description = "Option group MySQL 8.0 da demo com plugin de auditoria MariaDB."
  skip_destroy             = false
  lifecycle {
    create_before_destroy = false
  }
  option {
    option_name = "MARIADB_AUDIT_PLUGIN"
  }
  tags = {
    Name           = "demo-mysql-options"
    State          = "demo-mysql-vpc"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_db_parameter_group" "demo-mysql-params" {
  description  = "Parametros MySQL 8.0 para a demo: utf8mb4, limite de conexoes e slow query log habilitado."
  family       = "mysql8.4"
  name_prefix  = "demo-mysql-params"
  skip_destroy = false
  lifecycle {
    create_before_destroy = true
  }
  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }
  parameter {
    name  = "collation_server"
    value = "utf8mb4_unicode_ci"
  }
  parameter {
    name  = "max_connections"
    value = "200"
  }
  parameter {
    name  = "slow_query_log"
    value = "1"
  }
  parameter {
    name  = "long_query_time"
    value = "2"
  }
  tags = {
    Name           = "demo-mysql-params"
    State          = "demo-mysql-vpc"
    Struct8Creator = "Contato Struct"
  }
}


