terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  backend "s3" {
    bucket  = "struct8-import"
    key     = "952133486861/State/main.tfstate"
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
    State          = "State"
    Struct8Creator = "Contato Struct"
  }
}


