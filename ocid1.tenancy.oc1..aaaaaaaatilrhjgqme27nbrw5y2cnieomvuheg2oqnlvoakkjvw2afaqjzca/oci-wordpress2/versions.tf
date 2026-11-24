terraform {
  required_providers {
    oci = {
      source = "oracle/oci"
    }
  }

  backend "s3" {
    bucket  = "struct8-import"
    key     = "ocid1.tenancy.oc1..aaaaaaaatilrhjgqme27nbrw5y2cnieomvuheg2oqnlvoakkjvw2afaqjzca/oci-wordpress2/main.tfstate"
    region  = "us-west-2"
    encrypt = true
  }
}
