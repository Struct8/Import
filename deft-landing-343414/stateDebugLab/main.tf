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

resource "google_project_service" "compute" {
  disable_on_destroy = false
  service            = "compute.googleapis.com"
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




### CATEGORY: IAM ###

resource "google_service_account" "debug-lab-access" {
  account_id   = "s8-debug-wbmavl"
  display_name = "Struct8 debug access debug-lab-access"
  description  = "Acted as by Struct8 to publish debug commands and read their output. Written by the Debug Access component debug-lab-access."
  depends_on   = [google_project_service.iam, google_project_service.iamcredentials]
}

resource "google_service_account" "debug-vm-min_sa" {
  account_id                   = "debug-vm-min-sa"
  create_ignore_already_exists = false
  deletion_policy              = "DELETE"
  disabled                     = false
  depends_on                   = [google_project_service.iam]
}

resource "google_service_account_iam_member" "debug-lab-access_token" {
  service_account_id = google_service_account.debug-lab-access.name
  member             = "serviceAccount:struct8-reader@${google_service_account.debug-lab-access.project}.iam.gserviceaccount.com"
  role               = "roles/iam.serviceAccountTokenCreator"
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




### CATEGORY: COMPUTE ###

data "local_file" "debug_program_debug-lab-access" {
  filename = "${path.module}/.external_modules/struct8-debug-agent/gce/struct8-debug.sh"
}

resource "google_compute_instance" "debug-vm-min" {
  name                      = "debug-vm-min"
  allow_stopping_for_update = false
  can_ip_forward            = false
  deletion_policy           = "DELETE"
  deletion_protection       = false
  desired_status            = "RUNNING"
  enable_display            = false
  machine_type              = "e2-micro"
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
  labels = {
    struct8-debug = "wbmavl"
  }
  metadata = {
    startup-script = <<EOF
#!/bin/bash
# --- BEGIN STRUCT8 DEBUG ACCESS ---
mkdir -p /var/lib/struct8-debug
for i in 1 2 3 4 5 6; do
  curl -sf --max-time 10 -H 'Metadata-Flavor: Google' -o /var/lib/struct8-debug/struct8-debug.sh.new \
    http://metadata.google.internal/computeMetadata/v1/instance/attributes/struct8-debug-program && break
  sleep 5
done
[ -s /var/lib/struct8-debug/struct8-debug.sh.new ] && mv /var/lib/struct8-debug/struct8-debug.sh.new /var/lib/struct8-debug/struct8-debug.sh
cat > /etc/struct8-debug.env << 'STRUCT8_DEBUG_ENV'
STRUCT8_DEBUG_SUBSCRIPTION=${google_pubsub_subscription.debug-lab-access_debug-vm-min.id}
STRUCT8_DEBUG_OUTPUT_TOPIC=${google_pubsub_topic.debug-lab-access_output.id}
STRUCT8_DEBUG_ENV
if command -v systemctl >/dev/null 2>&1; then
cat > /etc/systemd/system/struct8-debug.service << 'STRUCT8_DEBUG_UNIT'
[Unit]
Description=Struct8 debug access
Wants=network-online.target
After=network-online.target
[Service]
EnvironmentFile=/etc/struct8-debug.env
ExecStart=/bin/sh /var/lib/struct8-debug/struct8-debug.sh
Restart=on-failure
RestartSec=10
[Install]
WantedBy=multi-user.target
STRUCT8_DEBUG_UNIT
systemctl daemon-reload
systemctl enable struct8-debug.service
systemctl restart struct8-debug.service
else
(set -a; . /etc/struct8-debug.env; set +a; nohup /bin/sh /var/lib/struct8-debug/struct8-debug.sh >> /var/log/struct8-debug.log 2>&1 &)
fi
# --- END STRUCT8 DEBUG ACCESS ---
    EOF
    struct8-debug-program = data.local_file.debug_program_debug-lab-access.content
    struct8-debug-level   = "shell"
  }
  network_interface {
    subnetwork = google_compute_subnetwork.debug-lab-subnet.id
  }
  service_account {
    email  = google_service_account.debug-vm-min_sa.email
    scopes = ["cloud-platform"]
  }
  depends_on = [google_project_service.compute]
}




### CATEGORY: INTEGRATION ###

resource "google_pubsub_subscription" "debug-lab-access_debug-vm-min" {
  name                         = "struct8-debug-cmd-wbmavl-debug-vm-min"
  ack_deadline_seconds         = 600
  enable_exactly_once_delivery = true
  filter                       = "attributes.instance = \"debug-vm-min\""
  message_retention_duration   = "600s"
  topic                        = google_pubsub_topic.debug-lab-access_commands.id
  expiration_policy {
    ttl = ""
  }
  depends_on = [google_project_service.pubsub]
}

resource "google_pubsub_subscription" "debug-lab-access_output" {
  name                 = "struct8-debug-out-wbmavl"
  ack_deadline_seconds = 60
  topic                = google_pubsub_topic.debug-lab-access_output.id
  expiration_policy {
    ttl = ""
  }
  depends_on = [google_project_service.pubsub]
}

resource "google_pubsub_subscription_iam_member" "debug-lab-access_debug-vm-min_pull" {
  member       = google_service_account.debug-vm-min_sa.member
  role         = "roles/pubsub.subscriber"
  subscription = google_pubsub_subscription.debug-lab-access_debug-vm-min.name
}

resource "google_pubsub_subscription_iam_member" "debug-lab-access_read_output" {
  member       = google_service_account.debug-lab-access.member
  role         = "roles/pubsub.subscriber"
  subscription = google_pubsub_subscription.debug-lab-access_output.name
}

resource "google_pubsub_topic" "debug-lab-access_commands" {
  name       = "struct8-debug-cmd-wbmavl"
  depends_on = [google_project_service.pubsub]
}

resource "google_pubsub_topic" "debug-lab-access_output" {
  name       = "struct8-debug-out-wbmavl"
  depends_on = [google_project_service.pubsub]
}

resource "google_pubsub_topic_iam_member" "debug-lab-access_debug-vm-min_send_output" {
  member = google_service_account.debug-vm-min_sa.member
  role   = "roles/pubsub.publisher"
  topic  = google_pubsub_topic.debug-lab-access_output.name
}

resource "google_pubsub_topic_iam_member" "debug-lab-access_send_commands" {
  member = google_service_account.debug-lab-access.member
  role   = "roles/pubsub.publisher"
  topic  = google_pubsub_topic.debug-lab-access_commands.name
}


