terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }
  }

  backend "s3" {
    bucket  = "struct8-import"
    key     = "deft-landing-343414/stateDebugLab/main.tfstate"
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

resource "google_project_service" "compute" {
  disable_on_destroy = false
  service            = "compute.googleapis.com"
}

resource "google_project_service" "iam" {
  disable_on_destroy = false
  service            = "iam.googleapis.com"
}




### CATEGORY: IAM ###

resource "google_project_iam_member" "debug-vm-log-writer" {
  member     = google_service_account.debug-vm-sa.member
  project    = "deft-landing-343414"
  role       = "roles/logging.logWriter"
  depends_on = [google_project_service.cloudresourcemanager]
}

resource "google_service_account" "debug-vm-sa" {
  account_id                   = "debug-vm-sa"
  create_ignore_already_exists = false
  deletion_policy              = "DELETE"
  disabled                     = false
  depends_on                   = [google_project_service.iam]
}

resource "google_service_account" "struct8-reader" {
  account_id                   = "struct8-reader"
  display_name                 = "Struct8 reader (debug lab)"
  create_ignore_already_exists = false
  deletion_policy              = "DELETE"
  disabled                     = false
  depends_on                   = [google_project_service.iam]
}

resource "google_service_account_iam_member" "reader-inspector-token" {
  service_account_id = google_service_account.struct8-reader.name
  member             = "serviceAccount:struct8-inspector@deft-landing-343414.iam.gserviceaccount.com"
  role               = "roles/iam.serviceAccountTokenCreator"
  depends_on         = [google_project_service.iam]
}




### CATEGORY: NETWORK ###

resource "google_compute_network" "debug-lab-vpc" {
  name                                      = "debug-lab-vpc"
  auto_create_subnetworks                   = false
  delete_bgp_always_compare_med             = false
  delete_default_routes_on_create           = false
  deletion_policy                           = "DELETE"
  enable_ula_internal_ipv6                  = false
  network_firewall_policy_enforcement_order = "AFTER_CLASSIC_FIREWALL"
  routing_mode                              = "REGIONAL"
  depends_on                                = [google_project_service.compute]
}

resource "google_compute_subnetwork" "debug-lab-subnet" {
  name                             = "debug-lab-subnet"
  allow_subnet_cidr_routes_overlap = false
  deletion_policy                  = "DELETE"
  ip_cidr_range                    = "10.20.0.0/24"
  network                          = google_compute_network.debug-lab-vpc.id
  private_ip_google_access         = true
  purpose                          = "PRIVATE"
  region                           = "us-central1"
  send_secondary_ip_range_if_empty = false
  stack_type                       = "IPV4_ONLY"
  depends_on                       = [google_project_service.compute]
}

resource "google_compute_firewall" "debug-lab-iap-ssh" {
  name            = "debug-lab-iap-ssh"
  deletion_policy = "DELETE"
  direction       = "INGRESS"
  disabled        = false
  enable_logging  = false
  network         = google_compute_network.debug-lab-vpc.id
  priority        = 1000
  source_ranges   = ["35.235.240.0/20"]
  target_tags     = ["fw-debug-lab-iap-ssh"]
  allow {
    ports    = ["22"]
    protocol = "tcp"
  }
  depends_on = [google_project_service.compute]
}




### CATEGORY: COMPUTE ###

resource "google_compute_instance" "debug-vm" {
  name                      = "debug-vm"
  allow_stopping_for_update = false
  can_ip_forward            = false
  deletion_policy           = "DELETE"
  deletion_protection       = false
  desired_status            = "RUNNING"
  enable_display            = false
  machine_type              = "e2-micro"
  tags                      = ["fw-debug-lab-iap-ssh"]
  zone                      = "us-central1-a"
  boot_disk {
    auto_delete  = true
    force_attach = false
    mode         = "READ_WRITE"
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = 10
      type  = "pd-standard"
    }
  }
  metadata = {
    startup-script = <<EOF
#!/bin/sh
# Lab: stands for the user's own startup script. It writes one line to Cloud Logging, so the
# order of the two scripts shows there.
MD=http://metadata.google.internal/computeMetadata/v1
H="Metadata-Flavor: Google"
T=$(curl -sf -H "$H" $MD/instance/service-accounts/default/token | sed -n 's/.*"access_token" *: *"\([^"]*\)".*/\1/p')
P=$(curl -sf -H "$H" $MD/project/project-id)
ID=$(curl -sf -H "$H" $MD/instance/id)
Z=$(curl -sf -H "$H" $MD/instance/zone | sed 's|.*/||')
curl -s -o /dev/null -X POST -H "Authorization: Bearer $T" -H "Content-Type: application/json" https://logging.googleapis.com/v2/entries:write \
  -d "{\"entries\":[{\"logName\":\"projects/$P/logs/struct8-debug-lab\",\"resource\":{\"type\":\"gce_instance\",\"labels\":{\"instance_id\":\"$ID\",\"zone\":\"$Z\"}},\"textPayload\":\"startup-script (user): ran at $(date -u +%Y-%m-%dT%H:%M:%S.%NZ), exiting with 1\"}]}"
exit 1
    EOF
  }
  network_interface {
    subnetwork = google_compute_subnetwork.debug-lab-subnet.id
  }
  service_account {
    email  = google_service_account.debug-vm-sa.email
    scopes = ["cloud-platform"]
  }
  depends_on = [google_project_service.compute]
}


