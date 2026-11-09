resource "google_compute_network" "mig-vpc" {
  name                                      = "mig-vpc"
  auto_create_subnetworks                   = false
  delete_bgp_always_compare_med             = false
  delete_default_routes_on_create           = false
  deletion_policy                           = "DELETE"
  enable_ula_internal_ipv6                  = false
  network_firewall_policy_enforcement_order = "AFTER_CLASSIC_FIREWALL"
  routing_mode                              = "REGIONAL"
  depends_on                                = [google_project_service.compute]
}

resource "google_compute_subnetwork" "mig-subnet" {
  name                             = "mig-subnet"
  allow_subnet_cidr_routes_overlap = false
  deletion_policy                  = "DELETE"
  ip_cidr_range                    = "10.30.0.0/24"
  network                          = google_compute_network.mig-vpc.id
  private_ip_google_access         = true
  purpose                          = "PRIVATE"
  region                           = "us-central1"
  send_secondary_ip_range_if_empty = false
  stack_type                       = "IPV4_ONLY"
  depends_on                       = [google_project_service.compute]
}

resource "google_compute_firewall" "kuma-3001" {
  name            = "kuma-3001"
  deletion_policy = "DELETE"
  direction       = "INGRESS"
  disabled        = false
  enable_logging  = false
  network         = google_compute_network.mig-vpc.id
  priority        = 1000
  source_ranges   = ["45.166.205.227/32"]
  allow {
    ports    = ["3001"]
    protocol = "tcp"
  }
  depends_on = [google_project_service.compute]
}
