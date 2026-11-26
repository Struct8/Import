data "oci_identity_compartments" "struct8-google-lab_compartment" {
  compartment_id            = "ocid1.tenancy.oc1..aaaaaaaatilrhjgqme27nbrw5y2cnieomvuheg2oqnlvoakkjvw2afaqjzca"
  compartment_id_in_subtree = true
  access_level              = "ANY"
  name                      = "lab-oci-google"
  state                     = "ACTIVE"
}

data "oci_identity_domains" "struct8-google-lab" {
  compartment_id = one(data.oci_identity_compartments.struct8-google-lab_compartment.compartments).id
  display_name   = "struct8-google-lab"
  state          = "ACTIVE"
}
