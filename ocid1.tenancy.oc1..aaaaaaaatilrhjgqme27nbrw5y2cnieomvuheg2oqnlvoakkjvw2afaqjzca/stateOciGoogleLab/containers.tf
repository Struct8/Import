resource "oci_artifacts_container_repository" "oci-google-reader" {
  compartment_id = one([for it in data.oci_identity_compartments.lab-oci-google.compartments : it.id if it.name == "lab-oci-google"])
  display_name   = "oci-google-reader"
  is_public      = false
  freeform_tags = {
    Name           = "oci-google-reader"
    State          = "stateOciGoogleLab"
    Struct8Creator = "Contato Struct"
  }
}
