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

resource "google_project_service" "pubsub" {
  disable_on_destroy = false
  service            = "pubsub.googleapis.com"
}

resource "google_project_service" "storage" {
  disable_on_destroy = false
  service            = "storage.googleapis.com"
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




### CATEGORY: STORAGE ###

resource "google_storage_bucket" "struct8-debug-lab-m4x9" {
  name                        = "struct8-debug-lab-m4x9"
  default_event_based_hold    = false
  deletion_policy             = "DELETE"
  enable_object_retention     = false
  force_destroy               = true
  location                    = "US-CENTRAL1"
  public_access_prevention    = "enforced"
  requester_pays              = false
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  depends_on                  = [google_project_service.storage]
}

resource "google_storage_bucket_iam_member" "struct8-debug-lab-m4x9-debug-vm-sa-storage-objectViewer" {
  bucket = google_storage_bucket.struct8-debug-lab-m4x9.name
  member = google_service_account.debug-vm-sa.member
  role   = "roles/storage.objectViewer"
}

resource "google_storage_bucket_object" "runner-sh" {
  name   = "runner-sh"
  bucket = google_storage_bucket.struct8-debug-lab-m4x9.name
  content = <<EOF
#!/bin/sh
# Struct8 debug lab: the program the VM downloads through startup-script-url, on every boot.
# It installs a systemd service that pulls commands from the subscription debug-lab-cmd-vm,
# runs each one, publishes the output to the topic debug-lab-out and writes every step to the
# log struct8-debug-lab in Cloud Logging. Lab only: it runs ANY command, as root.
cat > /usr/local/bin/struct8-debug <<'S8EOF'
#!/bin/sh
MD=http://metadata.google.internal/computeMetadata/v1
H="Metadata-Flavor: Google"
md() { curl -sf -H "$H" "$MD/$1"; }
PROJECT=$(md project/project-id)
NAME=$(md instance/name)
ID=$(md instance/id)
ZONE=$(md instance/zone | sed 's|.*/||')
SUB="https://pubsub.googleapis.com/v1/projects/$PROJECT/subscriptions/debug-lab-cmd-vm"
OUT="https://pubsub.googleapis.com/v1/projects/$PROJECT/topics/debug-lab-out:publish"
LOGAPI="https://logging.googleapis.com/v2/entries:write"
token() { md instance/service-accounts/default/token | sed -n 's/.*"access_token" *: *"\([^"]*\)".*/\1/p'; }
esc() { sed 's/\\/\\\\/g; s/"/\\"/g; s/\t/ /g' | awk 'BEGIN { ORS = "" } { print sep $0; sep = "\\n" }'; }
now() { date -u +%Y-%m-%dT%H:%M:%S.%NZ; }
log() {
  M=$(printf '%s' "$1" | esc)
  curl -s -o /dev/null -X POST -H "Authorization: Bearer $(token)" -H "Content-Type: application/json" "$LOGAPI" \
    -d "{\"entries\":[{\"logName\":\"projects/$PROJECT/logs/struct8-debug-lab\",\"resource\":{\"type\":\"gce_instance\",\"labels\":{\"instance_id\":\"$ID\",\"zone\":\"$ZONE\"}},\"textPayload\":\"$M\"}]}"
}
if [ "$1" = "--log" ]; then log "$2"; exit 0; fi
log "runner: service started on $NAME at $(now)"
while true; do
  T=$(token)
  R=$(curl -s -X POST -H "Authorization: Bearer $T" -H "Content-Type: application/json" "$SUB:pull" -d '{"maxMessages":1}' | tr -d '\n')
  ACK=$(printf '%s' "$R" | sed -n 's/.*"ackId": *"\([^"]*\)".*/\1/p')
  if [ -z "$ACK" ]; then
    case "$R" in *'"error"'*) log "runner: pull failed: $R"; sleep 30 ;; *) sleep 1 ;; esac
    continue
  fi
  GOT=$(now)
  curl -s -o /dev/null -X POST -H "Authorization: Bearer $T" -H "Content-Type: application/json" "$SUB:acknowledge" -d "{\"ackIds\":[\"$ACK\"]}"
  MID=$(printf '%s' "$R" | sed -n 's/.*"messageId": *"\([^"]*\)".*/\1/p')
  PUB=$(printf '%s' "$R" | sed -n 's/.*"publishTime": *"\([^"]*\)".*/\1/p')
  CMD=$(printf '%s' "$R" | sed -n 's/.*"data": *"\([^"]*\)".*/\1/p' | base64 -d)
  timeout 30 sh -c "$CMD" > /tmp/struct8-debug.out 2>&1
  RC=$?
  DONE=$(now)
  DATA=$(head -c 8000 /tmp/struct8-debug.out | base64 -w0)
  curl -s -o /dev/null -X POST -H "Authorization: Bearer $T" -H "Content-Type: application/json" "$OUT" \
    -d "{\"messages\":[{\"data\":\"$DATA\",\"attributes\":{\"instance\":\"$NAME\",\"request\":\"$MID\",\"rc\":\"$RC\"}}]}"
  log "runner: message $MID published $PUB received $GOT done $DONE rc $RC
$(head -c 4000 /tmp/struct8-debug.out)"
done
S8EOF
chmod 755 /usr/local/bin/struct8-debug
/usr/local/bin/struct8-debug --log "startup-script-url: ran at $(date -u +%Y-%m-%dT%H:%M:%S.%NZ)"
cat > /etc/systemd/system/struct8-debug.service <<'S8EOF'
[Unit]
Description=Struct8 debug lab command reader
After=network-online.target
Wants=network-online.target

[Service]
ExecStart=/usr/local/bin/struct8-debug
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
S8EOF
systemctl daemon-reload
systemctl enable struct8-debug
systemctl restart struct8-debug
  EOF
  content_type = "text/x-shellscript"
  depends_on   = [google_project_service.storage]
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
  metadata_startup_script = <<EOF
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
  -d "{\"entries\":[{\"logName\":\"projects/$P/logs/struct8-debug-lab\",\"resource\":{\"type\":\"gce_instance\",\"labels\":{\"instance_id\":\"$ID\",\"zone\":\"$Z\"}},\"textPayload\":\"startup-script (user): ran at $(date -u +%Y-%m-%dT%H:%M:%S.%NZ)\"}]}"
exit 0
  EOF
  tags = ["fw-debug-lab-iap-ssh"]
  zone = "us-central1-a"
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
    startup-script-url = "gs://struct8-debug-lab-m4x9/runner-sh"
  }
  network_interface {
    subnetwork = google_compute_subnetwork.debug-lab-subnet.id
  }
  service_account {
    email  = google_service_account.debug-vm-sa.email
    scopes = ["cloud-platform"]
  }
  depends_on = [google_storage_bucket_iam_member.struct8-debug-lab-m4x9-debug-vm-sa-storage-objectViewer, google_pubsub_subscription_iam_member.debug-lab-cmd-vm-debug-vm-sa-pubsub-subscriber, google_pubsub_topic_iam_member.debug-lab-out-debug-vm-sa-pubsub-publisher, google_project_service.compute]
}




### CATEGORY: INTEGRATION ###

resource "google_pubsub_subscription" "debug-lab-cmd-vm" {
  name                         = "debug-lab-cmd-vm"
  ack_deadline_seconds         = 10
  deletion_policy              = "DELETE"
  enable_exactly_once_delivery = false
  enable_message_ordering      = false
  filter                       = "attributes.instance = \"debug-vm\""
  message_retention_duration   = "604800s"
  retain_acked_messages        = false
  topic                        = google_pubsub_topic.debug-lab-cmd.name
  depends_on                   = [google_project_service.pubsub]
}

resource "google_pubsub_subscription_iam_member" "debug-lab-cmd-vm-debug-vm-sa-pubsub-subscriber" {
  member       = google_service_account.debug-vm-sa.member
  role         = "roles/pubsub.subscriber"
  subscription = google_pubsub_subscription.debug-lab-cmd-vm.name
}

resource "google_pubsub_topic" "debug-lab-cmd" {
  name                       = "debug-lab-cmd"
  deletion_policy            = "DELETE"
  message_retention_duration = "604800s"
  depends_on                 = [google_project_service.pubsub]
}

resource "google_pubsub_topic" "debug-lab-out" {
  name                       = "debug-lab-out"
  deletion_policy            = "DELETE"
  message_retention_duration = "604800s"
  depends_on                 = [google_project_service.pubsub]
}

resource "google_pubsub_topic_iam_member" "debug-lab-cmd-inspector-publisher" {
  member     = "serviceAccount:struct8-inspector@deft-landing-343414.iam.gserviceaccount.com"
  role       = "roles/pubsub.publisher"
  topic      = google_pubsub_topic.debug-lab-cmd.name
  depends_on = [google_project_service.pubsub]
}

resource "google_pubsub_topic_iam_member" "debug-lab-out-debug-vm-sa-pubsub-publisher" {
  member = google_service_account.debug-vm-sa.member
  role   = "roles/pubsub.publisher"
  topic  = google_pubsub_topic.debug-lab-out.name
}


