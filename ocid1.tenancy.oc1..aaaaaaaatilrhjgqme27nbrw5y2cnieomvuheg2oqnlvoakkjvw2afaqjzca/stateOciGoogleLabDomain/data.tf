data "oci_identity_domains_setting" "struct8-google-lab_settings" {
  setting_id    = "Settings"
  idcs_endpoint = oci_identity_domain.struct8-google-lab.url
}
