resource "google_compute_global_address" "ip-gcp" {
  name            = "ip-gcp"
  address_type    = "EXTERNAL"
  deletion_policy = "DELETE"
  ip_version      = "IPV4"
  labels = {
    struct8_state   = "stategcpdnstarget"
    struct8_creator = "contato_struct"
  }
  depends_on = [google_project_service.compute]
}

resource "google_dns_record_set" "a_google_compute_global_address_ip_gcp_ip_gcp_cloudman_pro" {
  name         = "ip.gcp.cloudman.pro."
  managed_zone = data.google_dns_managed_zone.gcp-cloudman-pro.name
  rrdatas      = [google_compute_global_address.ip-gcp.address]
  ttl          = 300
  type         = "A"
}

resource "google_dns_record_set" "worker-cname" {
  name         = "worker.gcp.cloudman.pro."
  managed_zone = data.google_dns_managed_zone.gcp-cloudman-pro.name
  rrdatas      = ["saas-fallback.struct8.com."]
  ttl          = 300
  type         = "CNAME"
  depends_on   = [google_project_service.dns]
}
