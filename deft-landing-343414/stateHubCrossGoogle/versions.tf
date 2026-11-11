terraform {
  required_providers {
    archive = {
      source = "hashicorp/archive"
    }
    google = {
      source = "hashicorp/google"
    }
  }

  backend "s3" {
    bucket  = "struct8-import"
    key     = "deft-landing-343414/stateHubCrossGoogle/main.tfstate"
    region  = "us-west-2"
    encrypt = true
  }
}
