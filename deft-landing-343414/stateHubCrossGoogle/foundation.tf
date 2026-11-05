resource "google_project_service" "artifactregistry" {
  disable_on_destroy = false
  service            = "artifactregistry.googleapis.com"
}

resource "google_project_service" "cloudbuild" {
  disable_on_destroy = false
  service            = "cloudbuild.googleapis.com"
}

resource "google_project_service" "cloudfunctions" {
  disable_on_destroy = false
  service            = "cloudfunctions.googleapis.com"
}

resource "google_project_service" "eventarc" {
  disable_on_destroy = false
  service            = "eventarc.googleapis.com"
}

resource "google_project_service" "iam" {
  disable_on_destroy = false
  service            = "iam.googleapis.com"
}

resource "google_project_service" "iamcredentials" {
  disable_on_destroy = false
  service            = "iamcredentials.googleapis.com"
}

resource "google_project_service" "pubsub" {
  disable_on_destroy = false
  service            = "pubsub.googleapis.com"
}

resource "google_project_service" "run" {
  disable_on_destroy = false
  service            = "run.googleapis.com"
}

resource "google_project_service" "secretmanager" {
  disable_on_destroy = false
  service            = "secretmanager.googleapis.com"
}

resource "google_project_service" "storage" {
  disable_on_destroy = false
  service            = "storage.googleapis.com"
}

resource "google_project_service" "sts" {
  disable_on_destroy = false
  service            = "sts.googleapis.com"
}

resource "google_project_service" "telemetry" {
  disable_on_destroy = false
  service            = "telemetry.googleapis.com"
}
