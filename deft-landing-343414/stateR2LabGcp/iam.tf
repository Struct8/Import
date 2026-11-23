resource "google_service_account" "r2-lab-gcp-fn_sa" {
  account_id                   = "r2-lab-gcp-fn-sa"
  create_ignore_already_exists = false
  deletion_policy              = "DELETE"
  disabled                     = false
  depends_on                   = [google_project_service.iam]
}

resource "google_service_account" "r2-lab-gcp-intruder_sa" {
  account_id                   = "r2-lab-gcp-intruder-sa"
  create_ignore_already_exists = false
  deletion_policy              = "DELETE"
  disabled                     = false
  depends_on                   = [google_project_service.iam]
}
