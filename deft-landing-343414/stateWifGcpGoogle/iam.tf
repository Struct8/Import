resource "google_service_account" "wif-lab-job_sa" {
  account_id                   = "wif-lab-job-sa"
  create_ignore_already_exists = false
  deletion_policy              = "DELETE"
  disabled                     = false
  depends_on                   = [google_project_service.iam]
}
