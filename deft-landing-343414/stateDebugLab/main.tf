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

resource "google_project_service" "iamcredentials" {
  disable_on_destroy = false
  service            = "iamcredentials.googleapis.com"
}

resource "google_project_service" "pubsub" {
  disable_on_destroy = false
  service            = "pubsub.googleapis.com"
}




### CATEGORY: IAM ###

resource "google_project_iam_member" "debug-vm-log-writer" {
  member     = google_service_account.debug-vm-sa.member
  project    = "deft-landing-343414"
  role       = "roles/logging.logWriter"
  depends_on = [google_project_service.cloudresourcemanager]
}

resource "google_service_account" "debug-lab-access" {
  account_id   = "s8-debug-b3fzg5"
  display_name = "Struct8 debug access debug-lab-access"
  description  = "Acted as by Struct8 to publish debug commands and read their output. Written by the Debug Access component debug-lab-access."
  depends_on   = [google_project_service.iam, google_project_service.iamcredentials]
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

resource "google_service_account_iam_member" "debug-lab-access_token" {
  service_account_id = google_service_account.debug-lab-access.name
  member             = "serviceAccount:struct8-reader@${google_service_account.debug-lab-access.project}.iam.gserviceaccount.com"
  role               = "roles/iam.serviceAccountTokenCreator"
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
  labels = {
    struct8-debug = "b3fzg5"
  }
  metadata = {
    startup-script = <<EOF
#!/bin/bash
# --- BEGIN STRUCT8 DEBUG ACCESS ---
mkdir -p /var/lib/struct8-debug
cat > /var/lib/struct8-debug/struct8-debug.sh << 'STRUCT8_DEBUG_PROGRAM'
#!/bin/sh
# Struct8 debug access for Compute Engine (Linux).
# Pulls one command at a time from a Pub/Sub subscription, runs it when the level in the
# struct8-debug-level metadata key allows it, publishes the output and then acknowledges.
# Needs sh, coreutils, sed and curl. Environment: STRUCT8_DEBUG_SUBSCRIPTION and
# STRUCT8_DEBUG_OUTPUT_TOPIC, as projects/<project>/subscriptions|topics/<name>.

MD=http://metadata.google.internal/computeMetadata/v1
API=https://pubsub.googleapis.com/v1
SUB="$STRUCT8_DEBUG_SUBSCRIPTION"
OUT="$STRUCT8_DEBUG_OUTPUT_TOPIC"
STATE=/var/lib/struct8-debug
# Another state folder, for the test of the generator that runs this program.
[ -n "$STRUCT8_DEBUG_STATE" ] && STATE="$STRUCT8_DEBUG_STATE"
MAX_OUTPUT=7000000
DIAGNOSTICS="ping dig nslookup traceroute ss netstat ip route hostname"

mkdir -p "$STATE"
touch "$STATE/seen"

md() { curl -sf --max-time 10 -H 'Metadata-Flavor: Google' "$MD/$1"; }

# The value of a JSON string key in one line of JSON.
field() { sed -n "s/.*\"$1\" *: *\"\([^\"]*\)\".*/\1/p" | sed 's/\\u003d/=/g'; }

rank() { case "$1" in probes) echo 1 ;; diagnostics) echo 2 ;; shell) echo 3 ;; *) echo 0 ;; esac; }

matches() { printf '%s\n' "$2" | grep -Eq "$1"; }

api() { curl -sS --max-time 70 -X POST -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' --data-binary "$2" "$API/$1"; }

# The level key gone means the component was removed: the program removes itself. curl -f
# exits with 22 on an HTTP error, which the metadata server returns as 404 for a missing key.
removed() {
  curl -sf -o /dev/null --max-time 10 -H 'Metadata-Flavor: Google' "$MD/instance/attributes/struct8-debug-level"
  [ $? -eq 22 ]
}

uninstall() {
  echo "struct8-debug: the struct8-debug-level key is gone; removing the debug program" >&2
  if command -v systemctl >/dev/null 2>&1; then
    systemctl disable struct8-debug.service >/dev/null 2>&1
    rm -f /etc/systemd/system/struct8-debug.service
    systemctl daemon-reload >/dev/null 2>&1
  fi
  rm -f /etc/struct8-debug.env
  rm -rf "$STATE"
  exit 0
}

refuse() { echo "struct8: $1" > "$OUTF"; EXIT=$2; }

run_probe() {
  t=$(printf '%s' "$RESP" | field target)
  p=$(printf '%s' "$RESP" | field port)
  [ -n "$p" ] || p=443
  matches '^[A-Za-z0-9._-]{1,253}$' "$t" || { refuse "the probe target must be a host name or an IP address" 2; return; }
  matches '^[0-9]{1,5}$' "$p" || { refuse "the probe port must be a number" 2; return; }
  {
    echo '--- resolve ---'
    getent hosts "$t" || echo "no DNS answer"
    echo '--- icmp ---'
    if command -v ping >/dev/null 2>&1; then
      ping -c 3 -W 2 "$t" || echo "no ICMP reply (often filtered, not conclusive)"
    else
      echo "ping is not installed on this VM"
    fi
    echo '--- tcp ---'
    if command -v bash >/dev/null 2>&1; then
      if timeout 5 bash -c 'exec 3<>/dev/tcp/"$1"/"$2"' _ "$t" "$p" 2>/dev/null; then echo "port $p open"; else echo "port $p closed or filtered"; fi
    elif command -v nc >/dev/null 2>&1; then
      if nc -z -w 5 "$t" "$p" 2>/dev/null; then echo "port $p open"; else echo "port $p closed or filtered"; fi
    else
      echo "the TCP test needs bash or nc, and this VM has neither"
    fi
  } > "$OUTF" 2>&1
  EXIT=0
}

run_diagnostics() {
  c=$(printf '%s' "$RESP" | field command)
  a=$(printf '%s' "$RESP" | field args)
  case " $DIAGNOSTICS " in *" $c "*) ;; *) refuse "'$c' is not on the diagnostics list: $DIAGNOSTICS" 2; return ;; esac
  if [ -n "$a" ] && ! matches '^[A-Za-z0-9 ._:/=@,+-]{0,200}$' "$a"; then
    refuse "the arguments may hold only letters, digits, spaces and . _ : / = @ , + -" 2; return
  fi
  # ip, route and hostname are read-only only without these operands.
  for tok in $a; do
    case "$tok" in add|del|delete|set|flush|change|replace|append|update|attach|up|down|exec|-b|-batch|-force)
      refuse "operand '$tok' writes; diagnostics is read-only" 2; return ;;
    esac
  done
  if [ "$c" = hostname ]; then
    for tok in $a; do
      case "$tok" in -a|-A|-d|-f|-i|-I|-s|-y|--all-fqdns|--all-ip-addresses|--domain|--fqdn|--ip-address|--short|--long|--alias|--nis) ;;
        *) refuse "hostname takes no name here; diagnostics is read-only" 2; return ;;
      esac
    done
  fi
  command -v "$c" >/dev/null 2>&1 || { refuse "$c is not installed on this VM" 127; return; }
  timeout 20 "$c" $a > "$OUTF" 2>&1
  EXIT=$?
}

run_shell() {
  printf '%s' "$RESP" | field data | base64 -d > "$STATE/script" 2>/dev/null || { refuse "the command is not valid base64" 2; return; }
  timeout 300 sh "$STATE/script" > "$OUTF" 2>&1
  EXIT=$?
}

publish() {
  size=$(wc -c < "$OUTF")
  truncated=false
  [ "$size" -gt "$MAX_OUTPUT" ] && truncated=true
  {
    printf '{"messages":[{"data":"'
    head -c "$MAX_OUTPUT" "$OUTF" | base64 | tr -d '\n'
    printf '","attributes":{"request":"%s","instance":"%s","exit":"%s","truncated":"%s"}}]}' "$REQ" "$INSTANCE" "$EXIT" "$truncated"
  } > "$STATE/publish.json"
  answer=$(api "$OUT:publish" @"$STATE/publish.json") || return 1
  case "$answer" in *messageIds*) return 0 ;; esac
  echo "struct8-debug: publish failed: $answer" >&2
  return 1
}

acknowledge() { api "$SUB:acknowledge" "{\"ackIds\":[\"$ACK\"]}" > /dev/null; }

handle() {
  MSG_ID=$(printf '%s' "$RESP" | field messageId)
  OUTF="$STATE/output"
  # A command delivered again after its output went out is acknowledged, not run again.
  # One whose output did not go out has the output published again.
  if grep -qx "$MSG_ID" "$STATE/seen"; then
    if [ "$(cat "$STATE/last.id" 2>/dev/null)" = "$MSG_ID" ] && [ -f "$STATE/last.out" ]; then
      OUTF="$STATE/last.out"
      REQ=$(cat "$STATE/last.request")
      EXIT=$(cat "$STATE/last.exit")
      publish || return
    fi
    acknowledge
    return
  fi

  REQ=$(printf '%s' "$RESP" | field request)
  matches '^[A-Za-z0-9._-]{1,64}$' "$REQ" || REQ=unknown
  mode=$(printf '%s' "$RESP" | field mode)
  granted=$(md instance/attributes/struct8-debug-level)
  if [ "$(rank "$mode")" -eq 0 ]; then
    refuse "unknown mode '$mode'" 2
  elif [ "$(rank "$mode")" -gt "$(rank "$granted")" ]; then
    refuse "this VM grants the $granted level, below $mode" 3
  else
    case "$mode" in
      probes) run_probe ;;
      diagnostics) run_diagnostics ;;
      shell) run_shell ;;
    esac
  fi

  echo "$MSG_ID" >> "$STATE/seen"
  tail -n 200 "$STATE/seen" > "$STATE/seen.new" && mv "$STATE/seen.new" "$STATE/seen"
  cp "$OUTF" "$STATE/last.out"
  printf '%s' "$MSG_ID" > "$STATE/last.id"
  printf '%s' "$REQ" > "$STATE/last.request"
  printf '%s' "$EXIT" > "$STATE/last.exit"
  publish || return
  acknowledge
}

# On the first boot the permissions take about 30 seconds to reach Pub/Sub: wait longer
# after each failure, up to five minutes.
DELAY=5
pause() {
  sleep "$DELAY"
  DELAY=$((DELAY * 2))
  [ "$DELAY" -gt 300 ] && DELAY=300
}

INSTANCE=$(md instance/name)
while :; do
  removed && uninstall
  TOKEN=$(md instance/service-accounts/default/token | tr -d '\n' | field access_token)
  if [ -z "$TOKEN" ]; then echo "struct8-debug: no token from the metadata server" >&2; pause; continue; fi
  RESP=$(api "$SUB:pull" '{"maxMessages":1}' | tr -d '\n')
  case "$RESP" in
    *'"error"'*) echo "struct8-debug: pull failed: $RESP" >&2; pause; continue ;;
  esac
  DELAY=5
  ACK=$(printf '%s' "$RESP" | field ackId)
  if [ -z "$ACK" ]; then sleep 1; continue; fi
  handle
done
STRUCT8_DEBUG_PROGRAM
cat > /etc/struct8-debug.env << 'STRUCT8_DEBUG_ENV'
STRUCT8_DEBUG_SUBSCRIPTION=${google_pubsub_subscription.debug-lab-access_debug-vm.id}
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
    struct8-debug-level = "probes"
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




### CATEGORY: INTEGRATION ###

resource "google_pubsub_subscription" "debug-lab-access_debug-vm" {
  name                         = "struct8-debug-cmd-b3fzg5-debug-vm"
  ack_deadline_seconds         = 600
  enable_exactly_once_delivery = true
  filter                       = "attributes.instance = \"debug-vm\""
  message_retention_duration   = "600s"
  topic                        = google_pubsub_topic.debug-lab-access_commands.id
  expiration_policy {
    ttl = ""
  }
  depends_on = [google_project_service.pubsub]
}

resource "google_pubsub_subscription" "debug-lab-access_output" {
  name                 = "struct8-debug-out-b3fzg5"
  ack_deadline_seconds = 60
  topic                = google_pubsub_topic.debug-lab-access_output.id
  expiration_policy {
    ttl = ""
  }
  depends_on = [google_project_service.pubsub]
}

resource "google_pubsub_subscription_iam_member" "debug-lab-access_debug-vm_pull" {
  member       = google_service_account.debug-vm-sa.member
  role         = "roles/pubsub.subscriber"
  subscription = google_pubsub_subscription.debug-lab-access_debug-vm.name
}

resource "google_pubsub_subscription_iam_member" "debug-lab-access_read_output" {
  member       = google_service_account.debug-lab-access.member
  role         = "roles/pubsub.subscriber"
  subscription = google_pubsub_subscription.debug-lab-access_output.name
}

resource "google_pubsub_topic" "debug-lab-access_commands" {
  name       = "struct8-debug-cmd-b3fzg5"
  depends_on = [google_project_service.pubsub]
}

resource "google_pubsub_topic" "debug-lab-access_output" {
  name       = "struct8-debug-out-b3fzg5"
  depends_on = [google_project_service.pubsub]
}

resource "google_pubsub_topic_iam_member" "debug-lab-access_debug-vm_send_output" {
  member = google_service_account.debug-vm-sa.member
  role   = "roles/pubsub.publisher"
  topic  = google_pubsub_topic.debug-lab-access_output.name
}

resource "google_pubsub_topic_iam_member" "debug-lab-access_send_commands" {
  member = google_service_account.debug-lab-access.member
  role   = "roles/pubsub.publisher"
  topic  = google_pubsub_topic.debug-lab-access_commands.name
}


