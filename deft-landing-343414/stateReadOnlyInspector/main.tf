terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }
  }

  backend "s3" {
    bucket  = "struct8-import"
    key     = "deft-landing-343414/stateReadOnlyInspector/main.tfstate"
    region  = "us-west-2"
    encrypt = true
  }
}

# --- Main Cloud Provider ---
provider "google" {
  project = "deft-landing-343414"
}

### CATEGORY: FOUNDATION ###

resource "google_project_service" "cloudresourcemanager" {
  disable_on_destroy = false
  service            = "cloudresourcemanager.googleapis.com"
}

resource "google_project_service" "iam" {
  disable_on_destroy = false
  service            = "iam.googleapis.com"
}




### CATEGORY: IAM ###

resource "google_project_iam_member" "inspector-bigquery-metadata-viewer" {
  member     = google_service_account.struct8-inspector.member
  project    = "deft-landing-343414"
  role       = "roles/bigquery.metadataViewer"
  depends_on = [google_project_service.cloudresourcemanager]
}

resource "google_project_iam_member" "inspector-browser" {
  member     = google_service_account.struct8-inspector.member
  project    = "deft-landing-343414"
  role       = "roles/browser"
  depends_on = [google_project_service.cloudresourcemanager]
}

resource "google_project_iam_member" "inspector-cloudasset-viewer" {
  member     = google_service_account.struct8-inspector.member
  project    = "deft-landing-343414"
  role       = "roles/cloudasset.viewer"
  depends_on = [google_project_service.cloudresourcemanager]
}

resource "google_project_iam_member" "inspector-compute-viewer" {
  member     = google_service_account.struct8-inspector.member
  project    = "deft-landing-343414"
  role       = "roles/compute.viewer"
  depends_on = [google_project_service.cloudresourcemanager]
}

resource "google_project_iam_member" "inspector-functions-viewer" {
  member     = google_service_account.struct8-inspector.member
  project    = "deft-landing-343414"
  role       = "roles/cloudfunctions.viewer"
  depends_on = [google_project_service.cloudresourcemanager]
}

resource "google_project_iam_member" "inspector-logging-viewer" {
  member     = google_service_account.struct8-inspector.member
  project    = "deft-landing-343414"
  role       = "roles/logging.viewer"
  depends_on = [google_project_service.cloudresourcemanager]
}

resource "google_project_iam_member" "inspector-monitoring-viewer" {
  member     = google_service_account.struct8-inspector.member
  project    = "deft-landing-343414"
  role       = "roles/monitoring.viewer"
  depends_on = [google_project_service.cloudresourcemanager]
}

resource "google_project_iam_member" "inspector-pubsub-viewer" {
  member     = google_service_account.struct8-inspector.member
  project    = "deft-landing-343414"
  role       = "roles/pubsub.viewer"
  depends_on = [google_project_service.cloudresourcemanager]
}

resource "google_project_iam_member" "inspector-run-viewer" {
  member     = google_service_account.struct8-inspector.member
  project    = "deft-landing-343414"
  role       = "roles/run.viewer"
  depends_on = [google_project_service.cloudresourcemanager]
}

resource "google_project_iam_member" "inspector-scheduler-viewer" {
  member     = google_service_account.struct8-inspector.member
  project    = "deft-landing-343414"
  role       = "roles/cloudscheduler.viewer"
  depends_on = [google_project_service.cloudresourcemanager]
}

resource "google_project_iam_member" "inspector-secretmanager-viewer" {
  member     = google_service_account.struct8-inspector.member
  project    = "deft-landing-343414"
  role       = "roles/secretmanager.viewer"
  depends_on = [google_project_service.cloudresourcemanager]
}

resource "google_project_iam_member" "inspector-serviceusage-consumer" {
  member     = google_service_account.struct8-inspector.member
  project    = "deft-landing-343414"
  role       = "roles/serviceusage.serviceUsageConsumer"
  depends_on = [google_project_service.cloudresourcemanager]
}

resource "google_project_iam_member" "inspector-storage-bucketviewer" {
  member     = google_service_account.struct8-inspector.member
  project    = "deft-landing-343414"
  role       = "roles/storage.bucketViewer"
  depends_on = [google_project_service.cloudresourcemanager]
}

resource "google_project_iam_member" "inspector-tasks-viewer" {
  member     = google_service_account.struct8-inspector.member
  project    = "deft-landing-343414"
  role       = "roles/cloudtasks.viewer"
  depends_on = [google_project_service.cloudresourcemanager]
}

resource "google_project_iam_member" "inspector-workflows-viewer" {
  member     = google_service_account.struct8-inspector.member
  project    = "deft-landing-343414"
  role       = "roles/workflows.viewer"
  depends_on = [google_project_service.cloudresourcemanager]
}

resource "google_service_account" "struct8-inspector" {
  account_id                   = "struct8-inspector"
  display_name                 = "Struct8 read-only inspector"
  create_ignore_already_exists = false
  deletion_policy              = "DELETE"
  description                  = "Read-only identity an agent uses to check the project. No keys; used by impersonation."
  disabled                     = false
  depends_on                   = [google_project_service.iam]
}

resource "google_service_account_iam_member" "inspector-owner-token-creator" {
  service_account_id = google_service_account.struct8-inspector.name
  member             = "user:rbpmconsulting@gmail.com"
  role               = "roles/iam.serviceAccountTokenCreator"
  depends_on         = [google_project_service.iam]
}


