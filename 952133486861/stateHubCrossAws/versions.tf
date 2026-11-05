terraform {
  required_providers {
    archive = {
      source = "hashicorp/archive"
    }
    aws = {
      source = "hashicorp/aws"
    }
  }

  backend "s3" {
    bucket  = "struct8-import"
    key     = "952133486861/stateHubCrossAws/main.tfstate"
    region  = "us-west-2"
    encrypt = true
  }
}
