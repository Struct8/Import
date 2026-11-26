terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "9.13.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "3.5.0"
    }
    external = {
      source  = "hashicorp/external"
      version = "2.3.5"
    }
    time = {
      source  = "hashicorp/time"
      version = "0.14.2"
    }
  }
  backend "s3" {
    bucket  = "struct8-import"
    key     = "ocid1.tenancy.oc1..aaaaaaaatilrhjgqme27nbrw5y2cnieomvuheg2oqnlvoakkjvw2afaqjzca/stateCertLab/main.tfstate"
    region  = "us-west-2"
    encrypt = true
  }
}
