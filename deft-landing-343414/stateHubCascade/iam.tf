resource "google_project_iam_member" "marisa-demo1-hub-api_sa-cloudtrace-agent" {
  member  = google_service_account.hub-api_sa.member
  project = "deft-landing-343414"
  role    = "roles/cloudtrace.agent"
}

resource "google_project_iam_member" "marisa-demo1-hub-api_sa-servicemanagement-serviceController" {
  member  = google_service_account.hub-api_sa.member
  project = "deft-landing-343414"
  role    = "roles/servicemanagement.serviceController"
}

resource "google_service_account" "hub-api_sa" {
  account_id                   = "hub-api-sa"
  create_ignore_already_exists = false
  deletion_policy              = "DELETE"
  disabled                     = false
  depends_on                   = [google_project_service.iam]
}

resource "google_service_account" "hub-entry_sa" {
  account_id                   = "hub-entry-sa"
  create_ignore_already_exists = false
  deletion_policy              = "DELETE"
  disabled                     = false
  depends_on                   = [google_project_service.iam]
}

resource "google_service_account" "hub-relay_sa" {
  account_id                   = "hub-relay-sa"
  create_ignore_already_exists = false
  deletion_policy              = "DELETE"
  disabled                     = false
  depends_on                   = [google_project_service.iam]
}

resource "google_service_account" "hub-sink_sa" {
  account_id                   = "hub-sink-sa"
  create_ignore_already_exists = false
  deletion_policy              = "DELETE"
  disabled                     = false
  depends_on                   = [google_project_service.iam]
}

resource "google_secret_manager_secret" "hub-last-message" {
  secret_id           = "hub-last-message"
  deletion_policy     = "DELETE"
  deletion_protection = false
  replication {
    user_managed {
      replicas {
        location = "us-central1"
      }
    }
  }
  depends_on = [google_project_service.secretmanager]
}

resource "google_secret_manager_secret_iam_member" "hub-last-message-hub-relay_sa-secretmanager-secretVersionAdder" {
  secret_id = google_secret_manager_secret.hub-last-message.secret_id
  member    = google_service_account.hub-relay_sa.member
  role      = "roles/secretmanager.secretVersionAdder"
}

resource "time_sleep" "hub-events-archive-iam-wait" {
  create_duration = "120s"
  depends_on      = [google_storage_bucket_iam_member.deft-landing-343414-hub-archive-pubsub-storage-objectCreator, google_storage_bucket_iam_member.deft-landing-343414-hub-archive-pubsub-storage-legacyBucketReader]
}
