terraform {
  required_providers {
    external = {
      source = "hashicorp/external"
    }
    oci = {
      source = "oracle/oci"
    }
  }

  backend "s3" {
    bucket  = "struct8-import"
    key     = "ocid1.tenancy.oc1..aaaaaaaatilrhjgqme27nbrw5y2cnieomvuheg2oqnlvoakkjvw2afaqjzca/stateOciGoogleLab/main.tfstate"
    region  = "us-west-2"
    encrypt = true
  }
}
