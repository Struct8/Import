resource "google_project_service" "dns" {
  disable_on_destroy = false
  service            = "dns.googleapis.com"
}
