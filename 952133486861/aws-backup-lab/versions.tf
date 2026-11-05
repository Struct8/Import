terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  backend "s3" {
    bucket  = "struct8-import"
    key     = "952133486861/aws-backup-lab/main.tfstate"
    region  = "us-west-2"
    encrypt = true
  }
}
