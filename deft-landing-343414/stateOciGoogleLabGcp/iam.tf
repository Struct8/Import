resource "google_iam_workload_identity_pool" "oci-gcs-reader" {
  display_name              = "oci-gcs-reader"
  workload_identity_pool_id = "oci-gcs-reader"
  description               = "OCI function oci-google-reader, through the identity domain struct8-google-lab. Written by the component oci-gcs-reader."
  depends_on                = [google_project_service.iam, google_project_service.iamcredentials, google_project_service.sts]
}

resource "google_iam_workload_identity_pool_provider" "oci-gcs-reader" {
  display_name                       = "OCI struct8-google-lab"
  workload_identity_pool_id          = google_iam_workload_identity_pool.oci-gcs-reader.workload_identity_pool_id
  workload_identity_pool_provider_id = "oci-domain"
  attribute_mapping = {
    "google.subject" = "assertion.sub"
  }
  oidc {
    allowed_audiences = ["sts.googleapis.com/oci-gcs-reader"]
    issuer_uri        = trimsuffix(one([for it in data.oci_identity_domains.struct8-google-lab.domains : it.url if it.display_name == "struct8-google-lab"]), ":443")
  }
}

resource "google_service_account" "oci-gcs-reader" {
  account_id   = "oci-gcs-reader"
  display_name = "Cross-cloud oci-gcs-reader"
  description  = "Acted as by the OCI function oci-google-reader. Written by the component oci-gcs-reader."
  depends_on   = [google_project_service.iam]
}

resource "google_service_account_iam_member" "oci-gcs-reader" {
  service_account_id = google_service_account.oci-gcs-reader.name
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.oci-gcs-reader.name}/*"
  role               = "roles/iam.workloadIdentityUser"
}
