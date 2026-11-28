resource "oci_identity_domains_app" "oci-google-reader_google" {
  display_name    = "oci-gcs-reader"
  active          = true
  allowed_grants  = ["client_credentials"]
  client_type     = "trusted"
  description     = "OCI function oci-google-reader calls Google Cloud through the component oci-gcs-reader."
  force_delete    = true
  idcs_endpoint   = one([for it in data.oci_identity_domains.struct8-google-lab.domains : it.url if it.display_name == "struct8-google-lab"])
  is_oauth_client = true
  schemas         = ["urn:ietf:params:scim:schemas:oracle:idcs:App"]
  allowed_scopes {
    fqs = "${oci_identity_domains_app.oci-google-reader_google_sts.audience}/"
  }
  based_on_template {
    value = "CustomWebAppTemplateId"
  }
  certificates {
    cert_alias = oci_identity_domains_oauth_client_certificate.oci-google-reader_google.certificate_alias
  }
  lifecycle {
    ignore_changes = [schemas]
  }
}

resource "oci_identity_domains_app" "oci-google-reader_google_sts" {
  display_name      = "oci-gcs-reader-sts"
  active            = true
  audience          = "sts.googleapis.com/oci-gcs-reader"
  description       = "OCI function oci-google-reader calls Google Cloud through the component oci-gcs-reader."
  force_delete      = true
  idcs_endpoint     = one([for it in data.oci_identity_domains.struct8-google-lab.domains : it.url if it.display_name == "struct8-google-lab"])
  is_oauth_resource = true
  schemas           = ["urn:ietf:params:scim:schemas:oracle:idcs:App"]
  based_on_template {
    value = "CustomWebAppTemplateId"
  }
  lifecycle {
    ignore_changes = [schemas]
  }
  scopes {
    value = "/"
  }
}

resource "oci_identity_domains_oauth_client_certificate" "oci-google-reader_google" {
  certificate_alias     = "oci-gcs-reader-client"
  idcs_endpoint         = one([for it in data.oci_identity_domains.struct8-google-lab.domains : it.url if it.display_name == "struct8-google-lab"])
  schemas               = ["urn:ietf:params:scim:schemas:oracle:idcs:OAuthClientCertificate"]
  x509base64certificate = textencodebase64(join("", [textdecodebase64("MIICuQ==", "ISO-8859-1"), textdecodebase64(local.oci-google-reader_google_certificate_tbs, "ISO-8859-1"), textdecodebase64("MA0GCSqGSIb3DQEBCwUAA4IBAQA=", "ISO-8859-1"), textdecodebase64(oci_kms_sign.oci-google-reader_google_certificate.signature, "ISO-8859-1")]), "ISO-8859-1")
}

resource "oci_identity_dynamic_group" "oci-google-reader_grants" {
  compartment_id = "ocid1.tenancy.oc1..aaaaaaaatilrhjgqme27nbrw5y2cnieomvuheg2oqnlvoakkjvw2afaqjzca"
  name           = "stateOciGoogleLab-oci-google-reader"
  description    = "Function oci-google-reader, for the permissions its connections grant."
  matching_rule  = "ALL {resource.type = 'fnfunc', resource.id = '${oci_functions_function.oci-google-reader.id}'}"
}

resource "oci_identity_policy" "oci-google-reader_grants" {
  compartment_id = "ocid1.tenancy.oc1..aaaaaaaatilrhjgqme27nbrw5y2cnieomvuheg2oqnlvoakkjvw2afaqjzca"
  name           = "stateOciGoogleLab-oci-google-reader-access"
  description    = "The permissions the connections of oci-google-reader grant."
  statements     = ["Allow dynamic-group id ${oci_identity_dynamic_group.oci-google-reader_grants.id} to use keys in compartment id ${one([for it in data.oci_identity_compartments.lab-oci-google.compartments : it.id if it.name == "lab-oci-google"])} where target.key.id = '${oci_kms_key.oci-google-signing.id}'"]
}

resource "oci_kms_key" "oci-google-signing" {
  compartment_id      = one([for it in data.oci_identity_compartments.lab-oci-google.compartments : it.id if it.name == "lab-oci-google"])
  display_name        = "oci-google-signing"
  desired_state       = "ENABLED"
  management_endpoint = oci_kms_vault.oci-google-vault.management_endpoint
  protection_mode     = "HSM"
  freeform_tags = {
    Name           = "oci-google-signing"
    State          = "stateOciGoogleLab"
    Struct8Creator = "Contato Struct"
  }
  key_shape {
    algorithm = "RSA"
    length    = 256
  }
}

data "oci_kms_key_version" "oci-google-reader_google_certificate" {
  key_id              = oci_kms_key.oci-google-signing.id
  key_version_id      = oci_kms_key.oci-google-signing.current_key_version
  management_endpoint = oci_kms_vault.oci-google-vault.management_endpoint
}

data "external" "oci-google-reader_google_certificate_digest" {
  program = ["/bin/sh", "-c", "m=$(sed -n 's/.*\"message\" *: *\"\\([^\"]*\\)\".*/\\1/p'); d=$(printf '%s' \"$m\" | openssl base64 -d -A | openssl dgst -sha256 -binary | openssl base64 -A); if [ -z \"$m\" ] || [ -z \"$d\" ]; then echo 'openssl did not compute the SHA-256 of the certificate.' >&2; exit 1; fi; printf '{\"digest\":\"%s\"}' \"$d\""]
  query   = { message = local.oci-google-reader_google_certificate_tbs }
}

locals {
  oci-google-reader_google_certificate_spki    = replace(replace(data.oci_kms_key_version.oci-google-reader_google_certificate.public_key, "/-----[A-Z ]+-----/", ""), "/\\s/", "")
  oci-google-reader_google_certificate_created = format("%sZ", join("T", regex("^([0-9]{4}-[0-9]{2}-[0-9]{2})[ T]([0-9]{2}:[0-9]{2}:[0-9]{2})", data.oci_kms_key_version.oci-google-reader_google_certificate.time_created)))
  oci-google-reader_google_certificate_tbs     = textencodebase64(join("", [textdecodebase64("MIIBoaADAgECAgEBMA0GCSqGSIb3DQEBCwUAMCAxHjAcBgNVBAMMFW9jaS1nY3MtcmVhZGVyLWNsaWVudA==", "ISO-8859-1"), textdecodebase64("MB4XDQ==", "ISO-8859-1"), "${formatdate("YYMMDDhhmmss", local.oci-google-reader_google_certificate_created)}Z", textdecodebase64("Fw0=", "ISO-8859-1"), "${formatdate("YYMMDDhhmmss", timeadd(local.oci-google-reader_google_certificate_created, "87600h"))}Z", textdecodebase64("MCAxHjAcBgNVBAMMFW9jaS1nY3MtcmVhZGVyLWNsaWVudA==", "ISO-8859-1"), textdecodebase64(local.oci-google-reader_google_certificate_spki, "ISO-8859-1")]), "ISO-8859-1")
}

# The Vault signs the certificate oci-gcs-reader-client: the SHA-256 of its to-be-signed part, computed by openssl on the machine that runs Terraform.
resource "oci_kms_sign" "oci-google-reader_google_certificate" {
  key_id            = oci_kms_key.oci-google-signing.id
  key_version_id    = oci_kms_key.oci-google-signing.current_key_version
  crypto_endpoint   = oci_kms_vault.oci-google-vault.crypto_endpoint
  message           = data.external.oci-google-reader_google_certificate_digest.result.digest
  message_type      = "DIGEST"
  signing_algorithm = "SHA_256_RSA_PKCS1_V1_5"
}

resource "oci_kms_vault" "oci-google-vault" {
  compartment_id = one([for it in data.oci_identity_compartments.lab-oci-google.compartments : it.id if it.name == "lab-oci-google"])
  display_name   = "oci-google-vault"
  vault_type     = "DEFAULT"
  freeform_tags = {
    Name           = "oci-google-vault"
    State          = "stateOciGoogleLab"
    Struct8Creator = "Contato Struct"
  }
}
