terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }
    oci = {
      source = "oracle/oci"
    }
  }

  backend "s3" {
    bucket  = "struct8-import"
    key     = "deft-landing-343414/stateOciGoogleLabGcp/main.tfstate"
    region  = "us-west-2"
    encrypt = true
  }
}
