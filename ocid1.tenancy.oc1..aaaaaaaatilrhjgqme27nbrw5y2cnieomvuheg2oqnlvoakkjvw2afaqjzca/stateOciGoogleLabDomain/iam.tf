resource "oci_identity_domain" "struct8-google-lab" {
  compartment_id     = one([for it in data.oci_identity_compartments.lab-oci-google.compartments : it.id if it.name == "lab-oci-google"])
  display_name       = "struct8-google-lab"
  description        = "Identity domain for the OCI function that calls Google Cloud (lab of direction 10)"
  home_region        = "sa-saopaulo-1"
  is_hidden_on_login = true
  license_type       = "free"
}

resource "oci_identity_domains_setting" "struct8-google-lab" {
  setting_id                 = "Settings"
  csr_access                 = coalesce(data.oci_identity_domains_setting.struct8-google-lab_settings.csr_access, "none")
  idcs_endpoint              = oci_identity_domain.struct8-google-lab.url
  issuer                     = trimsuffix(oci_identity_domain.struct8-google-lab.url, ":443")
  schemas                    = ["urn:ietf:params:scim:schemas:oracle:idcs:Settings"]
  signing_cert_public_access = true
  depends_on                 = [terraform_data.struct8-google-lab_deactivate]
}
