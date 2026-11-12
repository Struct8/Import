resource "google_dns_managed_zone" "gcp-cloudman-pro" {
  dns_name        = "gcp.cloudman.pro."
  name            = "gcp-cloudman-pro"
  deletion_policy = "DELETE"
  description     = "Cloud DNS zone gcp.cloudman.pro, delegated from the Route 53 zone cloudman.pro"
  force_destroy   = false
  visibility      = "public"
  labels = {
    struct8_state   = "stategcpdns"
    struct8_creator = "contato_struct"
  }
  depends_on = [google_project_service.dns]
}

resource "google_dns_record_set" "test-txt" {
  name         = "test.gcp.cloudman.pro."
  managed_zone = google_dns_managed_zone.gcp-cloudman-pro.name
  rrdatas      = ["struct8-test"]
  ttl          = 300
  type         = "TXT"
  depends_on   = [google_project_service.dns]
}
