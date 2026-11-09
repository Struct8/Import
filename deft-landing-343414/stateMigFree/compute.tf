data "local_file" "startup_script_mig-template" {
  filename = "${path.module}/.external_modules/struct8-templates/templates/multi-cloud-uptime-kuma/v1/user_data/Kuma.sh"
}

resource "google_compute_instance_template" "mig-template" {
  can_ip_forward = false
  machine_type   = "e2-micro"
  metadata_startup_script = <<EOF
#!/bin/bash
# --- BEGIN STRUCT8 VARIABLES ---
STRUCT8_MD=http://metadata.google.internal/computeMetadata/v1
STRUCT8_ZONE="$(curl -sf --retry 5 -H 'Metadata-Flavor: Google' "$STRUCT8_MD/instance/zone")"
STRUCT8_ZONE="$(echo "$STRUCT8_ZONE" | sed 's|.*/||')"
: > /etc/struct8_env
echo "PROJECT=\"$(curl -sf --retry 5 -H 'Metadata-Flavor: Google' "$STRUCT8_MD/project/project-id")\"" >> /etc/struct8_env
echo "ZONE=\"$STRUCT8_ZONE\"" >> /etc/struct8_env
echo "REGION=\"$(echo "$STRUCT8_ZONE" | sed 's/-[^-]*$//')\"" >> /etc/struct8_env
cat << 'EOFENV' >> /etc/struct8_env
NAME="mig-template"
GOOGLE_COMPUTE_REGION_INSTANCE_GROUP_MANAGER_NAME_0="mig-group"
EOFENV
chmod 644 /etc/struct8_env
sed 's/^/export /' /etc/struct8_env > /etc/profile.d/struct8_vars.sh
chmod 644 /etc/profile.d/struct8_vars.sh
touch /etc/environment
sed -i '/^# BEGIN STRUCT8$/,/^# END STRUCT8$/d' /etc/environment
{ echo '# BEGIN STRUCT8'; cat /etc/struct8_env; echo '# END STRUCT8'; } >> /etc/environment
set -a
. /etc/struct8_env
set +a
# --- END STRUCT8 VARIABLES ---

${data.local_file.startup_script_mig-template.content}
  EOF
  name_prefix = "mig-template"
  disk {
    auto_delete  = true
    boot         = true
    disk_size_gb = 10
    disk_type    = "pd-standard"
    source_image = "debian-cloud/debian-12"
  }
  lifecycle {
    create_before_destroy = true
  }
  network_interface {
    stack_type = "IPV4_ONLY"
    subnetwork = google_compute_subnetwork.mig-subnet.id
    access_config {
      network_tier = "PREMIUM"
    }
    ipv6_access_config {
      network_tier = "PREMIUM"
    }
  }
  service_account {
    email  = google_service_account.mig-template_sa.email
    scopes = ["cloud-platform"]
  }
  depends_on = [google_project_service.compute]
}

resource "google_compute_region_instance_group_manager" "mig-group" {
  version {
    instance_template = google_compute_instance_template.mig-template.self_link_unique
  }
  base_instance_name               = "mig-vm"
  name                             = "mig-group"
  deletion_policy                  = "DELETE"
  distribution_policy_target_shape = "EVEN"
  distribution_policy_zones        = ["us-central1-a", "us-central1-b"]
  region                           = "us-central1"
  target_stopped_size              = 0
  target_suspended_size            = 0
  wait_for_instances               = false
  depends_on                       = [google_project_service.compute]
}

resource "google_compute_region_autoscaler" "mig-autoscaler" {
  name            = "mig-autoscaler"
  deletion_policy = "DELETE"
  region          = "us-central1"
  target          = google_compute_region_instance_group_manager.mig-group.id
  autoscaling_policy {
    cooldown_period = 60
    max_replicas    = 1
    min_replicas    = 1
    mode            = "ON"
    cpu_utilization {
      predictive_method = "NONE"
      target            = 0.6
    }
  }
  depends_on = [google_project_service.compute]
}
