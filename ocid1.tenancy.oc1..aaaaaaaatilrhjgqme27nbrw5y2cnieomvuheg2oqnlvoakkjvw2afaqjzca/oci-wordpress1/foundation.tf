resource "oci_identity_compartment" "wordpress1" {
  compartment_id = "ocid1.tenancy.oc1..aaaaaaaatilrhjgqme27nbrw5y2cnieomvuheg2oqnlvoakkjvw2afaqjzca"
  name           = "wordpress1"
  description    = "WordPress site: compute instance and MySQL DB system"
  enable_delete  = true
  freeform_tags = {
    Name           = "wordpress1"
    State          = "oci-wordpress1"
    Struct8Creator = "Contato Struct"
  }
}
