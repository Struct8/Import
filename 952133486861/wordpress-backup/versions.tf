terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    random = {
      source = "hashicorp/random"
    }
  }

  backend "s3" {
    bucket  = "struct8-import"
    key     = "952133486861/wordpress-backup/main.tfstate"
    region  = "us-west-2"
    encrypt = true
  }
}
