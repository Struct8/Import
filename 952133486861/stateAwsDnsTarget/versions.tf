terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    google = {
      source = "hashicorp/google"
    }
  }

  backend "s3" {
    bucket  = "struct8-import"
    key     = "952133486861/stateAwsDnsTarget/main.tfstate"
    region  = "us-west-2"
    encrypt = true
  }
}
