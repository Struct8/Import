resource "oci_identity_compartment" "wordpress" {
  compartment_id = "ocid1.tenancy.oc1..aaaaaaaatilrhjgqme27nbrw5y2cnieomvuheg2oqnlvoakkjvw2afaqjzca"
  name           = "wordpress"
  description    = "WordPress site: compute instance and MySQL DB system"
  enable_delete  = true
}
