resource "oci_identity_compartment" "lab-oci-google" {
  compartment_id = "ocid1.tenancy.oc1..aaaaaaaatilrhjgqme27nbrw5y2cnieomvuheg2oqnlvoakkjvw2afaqjzca"
  name           = "lab-oci-google"
  description    = "Struct8 lab: OCI function to Google Cloud Storage through cldmn_workload_identity (direction 10)."
  enable_delete  = true
}
