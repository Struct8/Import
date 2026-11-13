resource "google_project_service" "compute" {
  disable_on_destroy = false
  service            = "compute.googleapis.com"
}

resource "google_project_service" "dns" {
  disable_on_destroy = false
  service            = "dns.googleapis.com"
}
