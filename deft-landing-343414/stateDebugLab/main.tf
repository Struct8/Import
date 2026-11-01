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

resource "google_project_service" "run" {
  disable_on_destroy = false
  service            = "run.googleapis.com"
}




### CATEGORY: IAM ###

resource "google_service_account" "cr-debug-sa" {
  account_id                   = "cr-debug-sa"
  create_ignore_already_exists = false
  deletion_policy              = "DELETE"
  disabled                     = false
  depends_on                   = [google_project_service.iam]
}

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

resource "google_compute_firewall" "debug-lab-allow-http" {
  name            = "debug-lab-allow-http"
  deletion_policy = "DELETE"
  direction       = "INGRESS"
  disabled        = false
  enable_logging  = false
  network         = google_compute_network.debug-lab-vpc.id
  priority        = 1000
  source_ranges   = ["45.166.205.227/32"]
  target_tags     = ["fw-debug-lab-allow-http"]
  allow {
    ports    = ["80"]
    protocol = "tcp"
  }
  depends_on = [google_project_service.compute]
}




### CATEGORY: COMPUTE ###

data "local_file" "startup_script_debug-vm-min" {
  filename = "${path.module}/.external_modules/struct8-templates/templates/gce-wordpress-debug/v1/user_data/wordpress.sh"
}

data "local_file" "debug_program_debug-lab-access" {
  filename = "${path.module}/.external_modules/struct8-templates/templates/gce-wordpress-debug/v1/debug/struct8-debug.sh"
}

resource "google_compute_instance" "debug-vm-min" {
  name                      = "debug-vm-min"
  allow_stopping_for_update = false
  can_ip_forward            = false
  deletion_policy           = "DELETE"
  deletion_protection       = false
  desired_status            = "RUNNING"
  enable_display            = false
  machine_type              = "e2-small"
  tags                      = ["fw-debug-lab-allow-http"]
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

${data.local_file.startup_script_debug-vm-min.content}
    EOF
    struct8-debug-program = data.local_file.debug_program_debug-lab-access.content
    struct8-debug-level   = "shell"
  }
  network_interface {
    subnetwork = google_compute_subnetwork.debug-lab-subnet.id
    access_config {
      network_tier = "PREMIUM"
    }
  }
  service_account {
    email  = google_service_account.debug-vm-min_sa.email
    scopes = ["cloud-platform"]
  }
  depends_on = [google_project_service.compute]
}

resource "google_cloud_run_v2_service" "cr-debug-lab" {
  name                 = "cr-debug-lab"
  default_uri_disabled = false
  deletion_protection  = false
  ingress              = "INGRESS_TRAFFIC_ALL"
  invoker_iam_disabled = false
  location             = "us-central1"
  template {
    execution_environment            = "EXECUTION_ENVIRONMENT_GEN2"
    max_instance_request_concurrency = 80
    service_account                  = google_service_account.cr-debug-sa.email
    timeout                          = "300s"
    containers {
      name = "app"
      resources {
        cpu_idle = false
        limits = {
    cpu    = "1"
    memory = "512Mi"
  }
      }
      image = "us-docker.pkg.dev/cloudrun/container/hello"
      ports {
        container_port = 8080
      }
    }
    containers {
      name = "struct8-debug"
      resources {
        cpu_idle = false
        limits = {
    cpu    = "1"
    memory = "512Mi"
  }
      }
      args    = ["printf %s \"$STRUCT8_DEBUG_PROGRAM\" | base64 -d > /tmp/struct8-debug.sh && exec sh /tmp/struct8-debug.sh"]
      command = ["/bin/sh", "-c"]
      image   = "gcr.io/google.com/cloudsdktool/google-cloud-cli:alpine"
      env {
        name  = "STRUCT8_DEBUG_SUBSCRIPTION"
        value = "projects/deft-landing-343414/subscriptions/cr-debug-cmd-sub"
      }
      env {
        name  = "STRUCT8_DEBUG_OUTPUT_TOPIC"
        value = "projects/deft-landing-343414/topics/struct8-debug-out-wbmavl"
      }
      env {
        name  = "STRUCT8_DEBUG_LEVEL"
        value = "shell"
      }
      env {
        name  = "STRUCT8_DEBUG_EXPIRES"
        value = "1793562803"
      }
      env {
        name  = "STRUCT8_DEBUG_INSTANCE"
        value = "cr-debug-lab"
      }
      env {
        name  = "STRUCT8_DEBUG_PROGRAM"
        value = "IyEvYmluL3NoCiMgU3RydWN0OCBkZWJ1ZyBhY2Nlc3MgZm9yIENsb3VkIFJ1biwgYXMgYSBzaWRlY2FyIGNvbnRhaW5lciBvZiB0aGUgc2VydmljZSAobGFiIHZlcnNpb24pLgojIFB1bGxzIG9uZSBjb21tYW5kIGF0IGEgdGltZSBmcm9tIGEgUHViL1N1YiBzdWJzY3JpcHRpb24sIHJ1bnMgaXQgd2hlbiB0aGUgbGV2ZWwgYWxsb3dzIGl0LAojIHB1Ymxpc2hlcyB0aGUgb3V0cHV0IGFuZCB0aGVuIGFja25vd2xlZGdlcy4KIyBFbnZpcm9ubWVudDoKIyAgIFNUUlVDVDhfREVCVUdfU1VCU0NSSVBUSU9OLCBTVFJVQ1Q4X0RFQlVHX09VVFBVVF9UT1BJQyAgcHJvamVjdHMvPHA+L3N1YnNjcmlwdGlvbnN8dG9waWNzLzxuYW1lPgojICAgU1RSVUNUOF9ERUJVR19MRVZFTCAgICBwcm9iZXMgfCBkaWFnbm9zdGljcyB8IHNoZWxsIChhIHJldmlzaW9uIGhhcyBubyBtZXRhZGF0YSBrZXlzIHRvIHJlYWQpCiMgICBTVFJVQ1Q4X0RFQlVHX0VYUElSRVMgIG9wdGlvbmFsLCBVbml4IHRpbWU7IGFmdGVyIGl0IHRoZSBsZXZlbCBmYWxscyBiYWNrIHRvIHByb2JlcwojICAgU1RSVUNUOF9ERUJVR19JTlNUQU5DRSB0aGUgbmFtZSBhbnN3ZXJlZCBpbiB0aGUgaW5zdGFuY2UgYXR0cmlidXRlIChkZWZhdWx0cyB0byBLX1NFUlZJQ0UpCgpWRVJTSU9OPTEuMC4xLWxhYi1jbG91ZHJ1bgoKTUQ9aHR0cDovL21ldGFkYXRhLmdvb2dsZS5pbnRlcm5hbC9jb21wdXRlTWV0YWRhdGEvdjEKQVBJPWh0dHBzOi8vcHVic3ViLmdvb2dsZWFwaXMuY29tL3YxClNVQj0iJFNUUlVDVDhfREVCVUdfU1VCU0NSSVBUSU9OIgpPVVQ9IiRTVFJVQ1Q4X0RFQlVHX09VVFBVVF9UT1BJQyIKU1RBVEU9L3RtcC9zdHJ1Y3Q4LWRlYnVnCk1BWF9PVVRQVVQ9NzAwMDAwMApESUFHTk9TVElDUz0icGluZyBkaWcgbnNsb29rdXAgdHJhY2Vyb3V0ZSBzcyBuZXRzdGF0IGlwIHJvdXRlIGhvc3RuYW1lIgoKbWtkaXIgLXAgIiRTVEFURSIKdG91Y2ggIiRTVEFURS9zZWVuIgoKbWQoKSB7IGN1cmwgLXNmIC0tbWF4LXRpbWUgMTAgLUggJ01ldGFkYXRhLUZsYXZvcjogR29vZ2xlJyAiJE1ELyQxIjsgfQoKZmllbGQoKSB7IHNlZCAtbiAicy8uKlwiJDFcIiAqOiAqXCJcKFteXCJdKlwpXCIuKi9cMS9wIiB8IHNlZCAncy9cXHUwMDNkLz0vZyc7IH0KCnJhbmsoKSB7IGNhc2UgIiQxIiBpbiBwcm9iZXMpIGVjaG8gMSA7OyBkaWFnbm9zdGljcykgZWNobyAyIDs7IHNoZWxsKSBlY2hvIDMgOzsgKikgZWNobyAwIDs7IGVzYWM7IH0KCm1hdGNoZXMoKSB7IHByaW50ZiAnJXNcbicgIiQyIiB8IGdyZXAgLUVxICIkMSI7IH0KCmFwaSgpIHsgY3VybCAtc1MgLS1tYXgtdGltZSA3MCAtWCBQT1NUIC1IICJBdXRob3JpemF0aW9uOiBCZWFyZXIgJFRPS0VOIiAtSCAnQ29udGVudC1UeXBlOiBhcHBsaWNhdGlvbi9qc29uJyAtLWRhdGEtYmluYXJ5ICIkMiIgIiRBUEkvJDEiOyB9CgojIFRoZSBsZXZlbCBpbiBmb3JjZTogdGhlIG9uZSBpbiB0aGUgcmV2aXNpb24sIG9yIHByb2JlcyBvbmNlIHRoZSBleHBpcnkgaGFzIHBhc3NlZC4KZ3JhbnRlZCgpIHsKICBpZiBbIC1uICIkU1RSVUNUOF9ERUJVR19FWFBJUkVTIiBdICYmIFsgIiQoZGF0ZSArJXMpIiAtZ2UgIiRTVFJVQ1Q4X0RFQlVHX0VYUElSRVMiIF07IHRoZW4KICAgIGVjaG8gcHJvYmVzCiAgZWxzZQogICAgZWNobyAiJHtTVFJVQ1Q4X0RFQlVHX0xFVkVMOi1wcm9iZXN9IgogIGZpCn0KCnJlZnVzZSgpIHsgZWNobyAic3RydWN0ODogJDEiID4gIiRPVVRGIjsgRVhJVD0kMjsgfQoKcnVuX3Byb2JlKCkgewogIHQ9JChwcmludGYgJyVzJyAiJFJFU1AiIHwgZmllbGQgdGFyZ2V0KQogIHA9JChwcmludGYgJyVzJyAiJFJFU1AiIHwgZmllbGQgcG9ydCkKICBbIC1uICIkcCIgXSB8fCBwPTQ0MwogIG1hdGNoZXMgJ15bQS1aYS16MC05Ll8tXXsxLDI1M30kJyAiJHQiIHx8IHsgcmVmdXNlICJ0aGUgcHJvYmUgdGFyZ2V0IG11c3QgYmUgYSBob3N0IG5hbWUgb3IgYW4gSVAgYWRkcmVzcyIgMjsgcmV0dXJuOyB9CiAgbWF0Y2hlcyAnXlswLTldezEsNX0kJyAiJHAiIHx8IHsgcmVmdXNlICJ0aGUgcHJvYmUgcG9ydCBtdXN0IGJlIGEgbnVtYmVyIiAyOyByZXR1cm47IH0KICB7CiAgICBlY2hvICctLS0gcmVzb2x2ZSAtLS0nCiAgICBnZXRlbnQgaG9zdHMgIiR0IiB8fCBuc2xvb2t1cCAiJHQiIDI+L2Rldi9udWxsIHx8IGVjaG8gIm5vIEROUyBhbnN3ZXIiCiAgICBlY2hvICctLS0gdGNwIC0tLScKICAgIGlmIGNvbW1hbmQgLXYgbmMgPi9kZXYvbnVsbCAyPiYxOyB0aGVuCiAgICAgIGlmIG5jIC16IC13IDUgIiR0IiAiJHAiIDI+L2Rldi9udWxsOyB0aGVuIGVjaG8gInBvcnQgJHAgb3BlbiI7IGVsc2UgZWNobyAicG9ydCAkcCBjbG9zZWQgb3IgZmlsdGVyZWQiOyBmaQogICAgZWxpZiBjb21tYW5kIC12IGJhc2ggPi9kZXYvbnVsbCAyPiYxOyB0aGVuCiAgICAgIGlmIHRpbWVvdXQgNSBiYXNoIC1jICdleGVjIDM8Pi9kZXYvdGNwLyIkMSIvIiQyIicgXyAiJHQiICIkcCIgMj4vZGV2L251bGw7IHRoZW4gZWNobyAicG9ydCAkcCBvcGVuIjsgZWxzZSBlY2hvICJwb3J0ICRwIGNsb3NlZCBvciBmaWx0ZXJlZCI7IGZpCiAgICBlbHNlCiAgICAgIGVjaG8gInRoZSBUQ1AgdGVzdCBuZWVkcyBiYXNoIG9yIG5jLCBhbmQgdGhpcyBjb250YWluZXIgaGFzIG5laXRoZXIiCiAgICBmaQogIH0gPiAiJE9VVEYiIDI+JjEKICBFWElUPTAKfQoKcnVuX2RpYWdub3N0aWNzKCkgewogIGM9JChwcmludGYgJyVzJyAiJFJFU1AiIHwgZmllbGQgY29tbWFuZCkKICBhPSQocHJpbnRmICclcycgIiRSRVNQIiB8IGZpZWxkIGFyZ3MpCiAgY2FzZSAiICRESUFHTk9TVElDUyAiIGluICoiICRjICIqKSA7OyAqKSByZWZ1c2UgIickYycgaXMgbm90IG9uIHRoZSBkaWFnbm9zdGljcyBsaXN0OiAkRElBR05PU1RJQ1MiIDI7IHJldHVybiA7OyBlc2FjCiAgaWYgWyAtbiAiJGEiIF0gJiYgISBtYXRjaGVzICdeW0EtWmEtejAtOSAuXzovPUAsKy1dezAsMjAwfSQnICIkYSI7IHRoZW4KICAgIHJlZnVzZSAidGhlIGFyZ3VtZW50cyBtYXkgaG9sZCBvbmx5IGxldHRlcnMsIGRpZ2l0cywgc3BhY2VzIGFuZCAuIF8gOiAvID0gQCAsICsgLSIgMjsgcmV0dXJuCiAgZmkKICBmb3IgdG9rIGluICRhOyBkbwogICAgY2FzZSAiJHRvayIgaW4gYWRkfGRlbHxkZWxldGV8c2V0fGZsdXNofGNoYW5nZXxyZXBsYWNlfGFwcGVuZHx1cGRhdGV8YXR0YWNofHVwfGRvd258ZXhlY3wtYnwtYmF0Y2h8LWZvcmNlKQogICAgICByZWZ1c2UgIm9wZXJhbmQgJyR0b2snIHdyaXRlczsgZGlhZ25vc3RpY3MgaXMgcmVhZC1vbmx5IiAyOyByZXR1cm4gOzsKICAgIGVzYWMKICBkb25lCiAgY29tbWFuZCAtdiAiJGMiID4vZGV2L251bGwgMj4mMSB8fCB7IHJlZnVzZSAiJGMgaXMgbm90IGluc3RhbGxlZCBpbiB0aGlzIGNvbnRhaW5lciIgMTI3OyByZXR1cm47IH0KICB0aW1lb3V0IDIwICIkYyIgJGEgPiAiJE9VVEYiIDI+JjEKICBFWElUPSQ/Cn0KCnJ1bl9zaGVsbCgpIHsKICBwcmludGYgJyVzJyAiJFJFU1AiIHwgZmllbGQgZGF0YSB8IGJhc2U2NCAtZCA+ICIkU1RBVEUvc2NyaXB0IiAyPi9kZXYvbnVsbCB8fCB7IHJlZnVzZSAidGhlIGNvbW1hbmQgaXMgbm90IHZhbGlkIGJhc2U2NCIgMjsgcmV0dXJuOyB9CiAgdGltZW91dCAzMDAgc2ggIiRTVEFURS9zY3JpcHQiID4gIiRPVVRGIiAyPiYxCiAgRVhJVD0kPwp9CgpwdWJsaXNoKCkgewogIHNpemU9JCh3YyAtYyA8ICIkT1VURiIpCiAgdHJ1bmNhdGVkPWZhbHNlCiAgWyAiJHNpemUiIC1ndCAiJE1BWF9PVVRQVVQiIF0gJiYgdHJ1bmNhdGVkPXRydWUKICB7CiAgICBwcmludGYgJ3sibWVzc2FnZXMiOlt7ImRhdGEiOiInCiAgICBoZWFkIC1jICIkTUFYX09VVFBVVCIgIiRPVVRGIiB8IGJhc2U2NCB8IHRyIC1kICdcbicKICAgIHByaW50ZiAnIiwiYXR0cmlidXRlcyI6eyJyZXF1ZXN0IjoiJXMiLCJpbnN0YW5jZSI6IiVzIiwicmVwbGljYSI6IiVzIiwiZXhpdCI6IiVzIiwidHJ1bmNhdGVkIjoiJXMiLCJ2ZXJzaW9uIjoiJXMiLCJsZXZlbCI6IiVzIn19XX0nIFwKICAgICAgIiRSRVEiICIkSU5TVEFOQ0UiICIkUkVQTElDQSIgIiRFWElUIiAiJHRydW5jYXRlZCIgIiRWRVJTSU9OIiAiJChncmFudGVkKSIKICB9ID4gIiRTVEFURS9wdWJsaXNoLmpzb24iCiAgYW5zd2VyPSQoYXBpICIkT1VUOnB1Ymxpc2giIEAiJFNUQVRFL3B1Ymxpc2guanNvbiIpIHx8IHJldHVybiAxCiAgY2FzZSAiJGFuc3dlciIgaW4gKm1lc3NhZ2VJZHMqKSByZXR1cm4gMCA7OyBlc2FjCiAgZWNobyAic3RydWN0OC1kZWJ1ZzogcHVibGlzaCBmYWlsZWQ6ICRhbnN3ZXIiID4mMgogIHJldHVybiAxCn0KCmFja25vd2xlZGdlKCkgeyBhcGkgIiRTVUI6YWNrbm93bGVkZ2UiICJ7XCJhY2tJZHNcIjpbXCIkQUNLXCJdfSIgPiAvZGV2L251bGw7IH0KCmhhbmRsZSgpIHsKICBNU0dfSUQ9JChwcmludGYgJyVzJyAiJFJFU1AiIHwgZmllbGQgbWVzc2FnZUlkKQogIE9VVEY9IiRTVEFURS9vdXRwdXQiCiAgaWYgZ3JlcCAtcXggIiRNU0dfSUQiICIkU1RBVEUvc2VlbiI7IHRoZW4KICAgIGlmIFsgIiQoY2F0ICIkU1RBVEUvbGFzdC5pZCIgMj4vZGV2L251bGwpIiA9ICIkTVNHX0lEIiBdICYmIFsgLWYgIiRTVEFURS9sYXN0Lm91dCIgXTsgdGhlbgogICAgICBPVVRGPSIkU1RBVEUvbGFzdC5vdXQiCiAgICAgIFJFUT0kKGNhdCAiJFNUQVRFL2xhc3QucmVxdWVzdCIpCiAgICAgIEVYSVQ9JChjYXQgIiRTVEFURS9sYXN0LmV4aXQiKQogICAgICBwdWJsaXNoIHx8IHJldHVybgogICAgZmkKICAgIGFja25vd2xlZGdlCiAgICByZXR1cm4KICBmaQoKICBSRVE9JChwcmludGYgJyVzJyAiJFJFU1AiIHwgZmllbGQgcmVxdWVzdCkKICBtYXRjaGVzICdeW0EtWmEtejAtOS5fLV17MSw2NH0kJyAiJFJFUSIgfHwgUkVRPXVua25vd24KICBtb2RlPSQocHJpbnRmICclcycgIiRSRVNQIiB8IGZpZWxkIG1vZGUpCiAgbGV2ZWw9JChncmFudGVkKQogIGlmIFsgIiQocmFuayAiJG1vZGUiKSIgLWVxIDAgXTsgdGhlbgogICAgcmVmdXNlICJ1bmtub3duIG1vZGUgJyRtb2RlJyIgMgogIGVsaWYgWyAiJChyYW5rICIkbW9kZSIpIiAtZ3QgIiQocmFuayAiJGxldmVsIikiIF07IHRoZW4KICAgIHJlZnVzZSAidGhpcyBzZXJ2aWNlIGdyYW50cyB0aGUgJGxldmVsIGxldmVsLCBiZWxvdyAkbW9kZSIgMwogIGVsc2UKICAgIGNhc2UgIiRtb2RlIiBpbgogICAgICBwcm9iZXMpIHJ1bl9wcm9iZSA7OwogICAgICBkaWFnbm9zdGljcykgcnVuX2RpYWdub3N0aWNzIDs7CiAgICAgIHNoZWxsKSBydW5fc2hlbGwgOzsKICAgIGVzYWMKICBmaQoKICBlY2hvICIkTVNHX0lEIiA+PiAiJFNUQVRFL3NlZW4iCiAgdGFpbCAtbiAyMDAgIiRTVEFURS9zZWVuIiA+ICIkU1RBVEUvc2Vlbi5uZXciICYmIG12ICIkU1RBVEUvc2Vlbi5uZXciICIkU1RBVEUvc2VlbiIKICBjcCAiJE9VVEYiICIkU1RBVEUvbGFzdC5vdXQiCiAgcHJpbnRmICclcycgIiRNU0dfSUQiID4gIiRTVEFURS9sYXN0LmlkIgogIHByaW50ZiAnJXMnICIkUkVRIiA+ICIkU1RBVEUvbGFzdC5yZXF1ZXN0IgogIHByaW50ZiAnJXMnICIkRVhJVCIgPiAiJFNUQVRFL2xhc3QuZXhpdCIKICBwdWJsaXNoIHx8IHJldHVybgogIGFja25vd2xlZGdlCn0KCkRFTEFZPTUKcGF1c2UoKSB7CiAgc2xlZXAgIiRERUxBWSIKICBERUxBWT0kKChERUxBWSAqIDIpKQogIFsgIiRERUxBWSIgLWd0IDMwMCBdICYmIERFTEFZPTMwMAp9CgpJTlNUQU5DRT0iJHtTVFJVQ1Q4X0RFQlVHX0lOU1RBTkNFOi0kS19TRVJWSUNFfSIKUkVQTElDQT0kKG1kIGluc3RhbmNlL2lkIHwgY3V0IC1jMS0xNikKZWNobyAic3RydWN0OC1kZWJ1ZzogJFZFUlNJT04gb24gJElOU1RBTkNFICgkUkVQTElDQSksIGxldmVsICQoZ3JhbnRlZCkiID4mMgp3aGlsZSA6OyBkbwogIFRPS0VOPSQobWQgaW5zdGFuY2Uvc2VydmljZS1hY2NvdW50cy9kZWZhdWx0L3Rva2VuIHwgdHIgLWQgJ1xuJyB8IGZpZWxkIGFjY2Vzc190b2tlbikKICBpZiBbIC16ICIkVE9LRU4iIF07IHRoZW4gZWNobyAic3RydWN0OC1kZWJ1Zzogbm8gdG9rZW4gZnJvbSB0aGUgbWV0YWRhdGEgc2VydmVyIiA+JjI7IHBhdXNlOyBjb250aW51ZTsgZmkKICBSRVNQPSQoYXBpICIkU1VCOnB1bGwiICd7Im1heE1lc3NhZ2VzIjoxfScgfCB0ciAtZCAnXG4nKQogIGNhc2UgIiRSRVNQIiBpbgogICAgKiciZXJyb3IiJyopIGVjaG8gInN0cnVjdDgtZGVidWc6IHB1bGwgZmFpbGVkOiAkUkVTUCIgPiYyOyBwYXVzZTsgY29udGludWUgOzsKICBlc2FjCiAgREVMQVk9NQogIEFDSz0kKHByaW50ZiAnJXMnICIkUkVTUCIgfCBmaWVsZCBhY2tJZCkKICBpZiBbIC16ICIkQUNLIiBdOyB0aGVuIHNsZWVwIDE7IGNvbnRpbnVlOyBmaQogIGhhbmRsZQpkb25lCg=="
      }
    }
    scaling {
      max_instance_count = 1
      min_instance_count = 1
    }
  }
  depends_on = [google_pubsub_subscription_iam_member.cr-debug-cmd-sub-cr-debug-sa-pubsub-subscriber, google_project_service.run]
}




### CATEGORY: INTEGRATION ###

resource "google_pubsub_subscription" "cr-debug-cmd-sub" {
  name                         = "cr-debug-cmd-sub"
  ack_deadline_seconds         = 600
  deletion_policy              = "DELETE"
  enable_exactly_once_delivery = false
  enable_message_ordering      = false
  message_retention_duration   = "3600s"
  retain_acked_messages        = false
  topic                        = google_pubsub_topic.cr-debug-cmd.name
  depends_on                   = [google_project_service.pubsub]
}

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

resource "google_pubsub_subscription_iam_member" "cr-debug-cmd-sub-cr-debug-sa-pubsub-subscriber" {
  member       = google_service_account.cr-debug-sa.member
  role         = "roles/pubsub.subscriber"
  subscription = google_pubsub_subscription.cr-debug-cmd-sub.name
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

resource "google_pubsub_topic" "cr-debug-cmd" {
  name                       = "cr-debug-cmd"
  deletion_policy            = "DELETE"
  message_retention_duration = "604800s"
  depends_on                 = [google_project_service.pubsub]
}

resource "google_pubsub_topic" "debug-lab-access_commands" {
  name       = "struct8-debug-cmd-wbmavl"
  depends_on = [google_project_service.pubsub]
}

resource "google_pubsub_topic" "debug-lab-access_output" {
  name       = "struct8-debug-out-wbmavl"
  depends_on = [google_project_service.pubsub]
}

resource "google_pubsub_topic_iam_member" "cr-debug-cmd-sender" {
  member     = "serviceAccount:s8-debug-wbmavl@deft-landing-343414.iam.gserviceaccount.com"
  role       = "roles/pubsub.publisher"
  topic      = google_pubsub_topic.cr-debug-cmd.name
  depends_on = [google_project_service.pubsub]
}

resource "google_pubsub_topic_iam_member" "cr-debug-out-publisher" {
  member     = google_service_account.cr-debug-sa.member
  role       = "roles/pubsub.publisher"
  topic      = "projects/deft-landing-343414/topics/struct8-debug-out-wbmavl"
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


