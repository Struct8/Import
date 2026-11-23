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

resource "google_project_service" "iam" {
  disable_on_destroy = false
  service            = "iam.googleapis.com"
}

resource "google_project_service" "run" {
  disable_on_destroy = false
  service            = "run.googleapis.com"
}

resource "google_project_service" "storage" {
  disable_on_destroy = false
  service            = "storage.googleapis.com"
}
