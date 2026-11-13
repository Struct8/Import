terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }
  }

  backend "s3" {
    bucket  = "struct8-import"
    key     = "deft-landing-343414/stateGcpDnsTarget/main.tfstate"
    region  = "us-west-2"
    encrypt = true
  }
}
