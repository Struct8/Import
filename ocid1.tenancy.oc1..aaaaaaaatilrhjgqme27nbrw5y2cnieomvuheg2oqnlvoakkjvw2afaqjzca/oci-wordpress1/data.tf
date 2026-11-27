data "oci_core_images" "wordpress1_image" {
  compartment_id = "ocid1.tenancy.oc1..aaaaaaaatilrhjgqme27nbrw5y2cnieomvuheg2oqnlvoakkjvw2afaqjzca"
  shape          = "VM.Standard.A1.Flex"
  sort_by        = "TIMECREATED"
  sort_order     = "DESC"
  filter {
    name   = "display_name"
    regex  = true
    values = ["^Canonical-Ubuntu-24\\.04(\\.[0-9]+)?(-aarch64)?-[0-9]{4}\\.[0-9]{2}\\.[0-9]{2}-[0-9]+$"]
  }
}

data "oci_identity_domains_identity_propagation_trusts" "struct8_reader" {
  attribute_sets                    = ["all"]
  idcs_endpoint                     = "https://idcs-b4fd5c4293ab48539b64c95eeb70df35.identity.oraclecloud.com"
  identity_propagation_trust_filter = "name eq \"struct8-reader\""
}
