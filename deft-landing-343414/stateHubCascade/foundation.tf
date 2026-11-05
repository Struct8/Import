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

resource "google_project_service" "endpoints" {
  disable_on_destroy = false
  service            = "endpoints.googleapis.com"
}

resource "google_project_service" "hub-api-enable" {
  disable_on_destroy = false
  service            = google_endpoints_service.hub-api.service_name
}

resource "google_project_service" "iam" {
  disable_on_destroy = false
  service            = "iam.googleapis.com"
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

resource "google_project_service" "servicecontrol" {
  disable_on_destroy = false
  service            = "servicecontrol.googleapis.com"
}

resource "google_project_service" "servicemanagement" {
  disable_on_destroy = false
  service            = "servicemanagement.googleapis.com"
}

resource "google_project_service" "storage" {
  disable_on_destroy = false
  service            = "storage.googleapis.com"
}
