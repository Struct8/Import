resource "oci_functions_application" "oci-google-lab" {
  compartment_id             = one([for it in data.oci_identity_compartments.lab-oci-google.compartments : it.id if it.name == "lab-oci-google"])
  display_name               = "oci-google-lab"
  network_security_group_ids = [oci_core_network_security_group.oci-google-lab_nsg.id]
  shape                      = "GENERIC_X86"
  subnet_ids                 = [oci_core_subnet.functions.id]
  freeform_tags = {
    Name           = "oci-google-lab"
    State          = "stateOciGoogleLab"
    Struct8Creator = "Contato Struct"
  }
}

resource "oci_functions_function" "oci-google-reader" {
  application_id     = oci_functions_application.oci-google-lab.id
  display_name       = "oci-google-reader"
  memory_in_mbs      = "256"
  timeout_in_seconds = 60
  config = {
    NAME                                      = "oci-google-reader"
    OCI_ARTIFACTS_CONTAINER_REPOSITORY_NAME_0 = "oci-google-reader"
    OCI_KMS_KEY_NAME_SIGNING                  = "oci-google-signing"
    OCI_KMS_KEY_ID_SIGNING                    = oci_kms_key.oci-google-signing.id
    OCI_KMS_KEY_CRYPTO_ENDPOINT_SIGNING       = oci_kms_vault.oci-google-vault.crypto_endpoint
    OCI_KMS_KEY_MANAGEMENT_ENDPOINT_SIGNING   = oci_kms_vault.oci-google-vault.management_endpoint
    GOOGLE_SERVICE_ACCOUNT                    = "oci-gcs-reader@deft-landing-343414.iam.gserviceaccount.com"
    GOOGLE_STORAGE_BUCKET_NAME_LAB            = "deft-landing-343414-oci-lab"
    GOOGLE_STORAGE_BUCKET_ACCOUNT_LAB         = "deft-landing-343414"
    GOOGLE_WORKLOAD_PROVIDER                  = "projects/233610591017/locations/global/workloadIdentityPools/oci-gcs-reader/providers/oci-domain"
    OIDC_AUDIENCE                             = "sts.googleapis.com/oci-gcs-reader"
    OCI_CERTIFICATE_ALIAS                     = "oci-gcs-reader-client"
    LAB_CONTROL_BUCKET                        = "deft-landing-343414-oci-lab-control"
    OCI_CLIENT_ID                             = oci_identity_domains_app.oci-google-reader_google.name
    OCI_IDENTITY_DOMAIN_URL                   = one([for it in data.oci_identity_domains.struct8-google-lab.domains : it.url if it.display_name == "struct8-google-lab"])
  }
  freeform_tags = {
    Name           = "oci-google-reader"
    State          = "stateOciGoogleLab"
    Struct8Creator = "Contato Struct"
  }
  source_details {
    image       = "gru.ocir.io/${oci_artifacts_container_repository.oci-google-reader.namespace}/${oci_artifacts_container_repository.oci-google-reader.display_name}:${terraform_data.seed_oci-google-reader.output}"
    source_type = "CONTAINER_IMAGE"
  }
  depends_on = [terraform_data.seed_oci-google-reader]
}
