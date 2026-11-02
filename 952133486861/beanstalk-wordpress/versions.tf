terraform {
  required_providers {
    archive = {
      source = "hashicorp/archive"
    }
    aws = {
      source = "hashicorp/aws"
    }
    random = {
      source = "hashicorp/random"
    }
  }

  backend "s3" {
    bucket  = "struct8-import"
    key     = "952133486861/beanstalk-wordpress/main.tfstate"
    region  = "us-west-2"
    encrypt = true
  }
}
