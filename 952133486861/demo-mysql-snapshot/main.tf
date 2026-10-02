terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  backend "s3" {
    bucket  = "struct8-import"
    key     = "952133486861/demo-mysql-snapshot/main.tfstate"
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

data "aws_db_instance" "demo-mysql" {
  db_instance_identifier = "demo-mysql"
}




### CATEGORY: DATABASE ###

resource "aws_db_snapshot" "DBSnapshot" {
  db_instance_identifier = data.aws_db_instance.demo-mysql.db_instance_identifier
  db_snapshot_identifier = "dbsnapshot"
  tags = {
    Name           = "DBSnapshot"
    State          = "demo-mysql-snapshot"
    Struct8Creator = "Contato Struct"
  }
}


