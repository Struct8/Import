resource "google_project_service" "iam" {
  disable_on_destroy = false
  service            = "iam.googleapis.com"
}

resource "google_project_service" "iamcredentials" {
  disable_on_destroy = false
  service            = "iamcredentials.googleapis.com"
}

resource "google_project_service" "storage" {
  disable_on_destroy = false
  service            = "storage.googleapis.com"
}

resource "google_project_service" "sts" {
  disable_on_destroy = false
  service            = "sts.googleapis.com"
}
