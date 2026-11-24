# --- Main Cloud Provider ---
provider "oci" {
  region       = "sa-vinhedo-1"
  tenancy_ocid = "ocid1.tenancy.oc1..aaaaaaaatilrhjgqme27nbrw5y2cnieomvuheg2oqnlvoakkjvw2afaqjzca"
}

# --- Home region: IAM resources are written there ---
provider "oci" {
  alias        = "home"
  region       = "sa-saopaulo-1"
  tenancy_ocid = "ocid1.tenancy.oc1..aaaaaaaatilrhjgqme27nbrw5y2cnieomvuheg2oqnlvoakkjvw2afaqjzca"
}

data "oci_identity_availability_domains" "ads" {
  compartment_id = "ocid1.tenancy.oc1..aaaaaaaatilrhjgqme27nbrw5y2cnieomvuheg2oqnlvoakkjvw2afaqjzca"
}
