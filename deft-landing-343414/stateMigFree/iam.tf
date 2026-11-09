resource "google_service_account" "mig-template_sa" {
  account_id                   = "mig-template-sa"
  create_ignore_already_exists = false
  deletion_policy              = "DELETE"
  disabled                     = false
  depends_on                   = [google_project_service.iam]
}
