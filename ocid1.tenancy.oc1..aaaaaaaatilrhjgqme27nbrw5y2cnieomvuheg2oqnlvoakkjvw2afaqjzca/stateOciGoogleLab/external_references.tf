data "oci_identity_compartments" "lab-oci-google" {
  compartment_id            = "ocid1.tenancy.oc1..aaaaaaaatilrhjgqme27nbrw5y2cnieomvuheg2oqnlvoakkjvw2afaqjzca"
  name                      = "lab-oci-google"
  access_level              = "ANY"
  compartment_id_in_subtree = true
  state                     = "ACTIVE"
}

data "oci_identity_domains" "struct8-google-lab" {
  compartment_id = one([for it in data.oci_identity_compartments.lab-oci-google.compartments : it.id if it.name == "lab-oci-google"])
  display_name   = "struct8-google-lab"
  state          = "ACTIVE"
}
