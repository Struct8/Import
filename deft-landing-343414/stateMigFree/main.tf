terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }
  }

  backend "s3" {
    bucket  = "struct8-import"
    key     = "deft-landing-343414/stateMigFree/main.tfstate"
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




### CATEGORY: IAM ###

resource "google_service_account" "mig-template_sa" {
  account_id                   = "mig-template-sa"
  create_ignore_already_exists = false
  deletion_policy              = "DELETE"
  disabled                     = false
  depends_on                   = [google_project_service.iam]
}




### CATEGORY: NETWORK ###

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




### CATEGORY: COMPUTE ###

resource "google_compute_instance_template" "mig-template" {
  can_ip_forward = false
  machine_type   = "e2-micro"
  name_prefix    = "mig-template"
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
    max_replicas    = 3
    min_replicas    = 2
    mode            = "ON"
    cpu_utilization {
      predictive_method = "NONE"
      target            = 0.6
    }
  }
  depends_on = [google_project_service.compute]
}


