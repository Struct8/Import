terraform {
  required_providers {
    archive = {
      source = "hashicorp/archive"
    }
    google = {
      source = "hashicorp/google"
    }
    time = {
      source = "hashicorp/time"
    }
  }

  backend "s3" {
    bucket  = "struct8-import"
    key     = "deft-landing-343414/stateHubFree/main.tfstate"
    region  = "us-west-2"
    encrypt = true
  }
}

# --- Main Cloud Provider ---
provider "google" {
  project = "deft-landing-343414"
}

### SYSTEM DATA SOURCES ###

data "google_project" "pubsub-project" {
}

data "google_storage_project_service_account" "notification-storage-agent" {
}




### RENAMES ###

moved {
  from = google_endpoints_service.free-api
  to   = google_endpoints_service.free-api-2
}

moved {
  from = google_service_account.free-api_sa
  to   = google_service_account.free-api-2_sa
}

moved {
  from = google_firestore_database.free-firestore
  to   = google_firestore_database.free-firestore-2
}

moved {
  from = google_iam_workload_identity_pool.free-pool
  to   = google_iam_workload_identity_pool.free-pool-2
}

moved {
  from = google_cloud_tasks_queue.free-queue
  to   = google_cloud_tasks_queue.free-queue-2
}




### CATEGORY: FOUNDATION ###

resource "google_project_service" "artifactregistry" {
  disable_on_destroy = false
  service            = "artifactregistry.googleapis.com"
}

resource "google_project_service" "bigquery" {
  disable_on_destroy = false
  service            = "bigquery.googleapis.com"
}

resource "google_project_service" "cloudbuild" {
  disable_on_destroy = false
  service            = "cloudbuild.googleapis.com"
}

resource "google_project_service" "cloudfunctions" {
  disable_on_destroy = false
  service            = "cloudfunctions.googleapis.com"
}

resource "google_project_service" "cloudscheduler" {
  disable_on_destroy = false
  service            = "cloudscheduler.googleapis.com"
}

resource "google_project_service" "cloudtasks" {
  disable_on_destroy = false
  service            = "cloudtasks.googleapis.com"
}

resource "google_project_service" "compute" {
  disable_on_destroy = false
  service            = "compute.googleapis.com"
}

resource "google_project_service" "endpoints" {
  disable_on_destroy = false
  service            = "endpoints.googleapis.com"
}

resource "google_project_service" "firestore" {
  disable_on_destroy = false
  service            = "firestore.googleapis.com"
}

resource "google_project_service" "free-api-2-enable" {
  disable_on_destroy = false
  service            = google_endpoints_service.free-api-2.service_name
}

resource "google_project_service" "iam" {
  disable_on_destroy = false
  service            = "iam.googleapis.com"
}

resource "google_project_service" "logging" {
  disable_on_destroy = false
  service            = "logging.googleapis.com"
}

resource "google_project_service" "monitoring" {
  disable_on_destroy = false
  service            = "monitoring.googleapis.com"
}

resource "google_project_service" "pubsub" {
  disable_on_destroy = false
  service            = "pubsub.googleapis.com"
}

resource "google_project_service" "run" {
  disable_on_destroy = false
  service            = "run.googleapis.com"
}

resource "google_project_service" "secretmanager" {
  disable_on_destroy = false
  service            = "secretmanager.googleapis.com"
}

resource "google_project_service" "servicecontrol" {
  disable_on_destroy = false
  service            = "servicecontrol.googleapis.com"
}

resource "google_project_service" "servicemanagement" {
  disable_on_destroy = false
  service            = "servicemanagement.googleapis.com"
}

resource "google_project_service" "storage" {
  disable_on_destroy = false
  service            = "storage.googleapis.com"
}

resource "google_project_service" "workflows" {
  disable_on_destroy = false
  service            = "workflows.googleapis.com"
}




### CATEGORY: IAM ###

resource "google_iam_workload_identity_pool" "free-pool-2" {
  workload_identity_pool_id = "free-pool-2"
  deletion_policy           = "DELETE"
  disabled                  = false
  mode                      = "FEDERATION_ONLY"
  depends_on                = [google_project_service.iam]
}

resource "google_iam_workload_identity_pool_provider" "free-provider" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.free-pool-2.workload_identity_pool_id
  workload_identity_pool_provider_id = "free-provider"
  attribute_condition                = "assertion.repository_owner == \"Struct8\""
  deletion_policy                    = "DELETE"
  disabled                           = false
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
  }
  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
  depends_on = [google_project_service.iam]
}

resource "google_project_iam_custom_role" "free-role" {
  role_id         = "free_role"
  deletion_policy = "DELETE"
  permissions     = ["storage.objects.get", "storage.objects.list"]
  stage           = "GA"
  title           = "Free read buckets"
  depends_on      = [google_project_service.iam]
}

resource "google_project_iam_member" "marisa-demo1-free-api-2_sa-cloudtrace-agent" {
  member  = google_service_account.free-api-2_sa.member
  project = "deft-landing-343414"
  role    = "roles/cloudtrace.agent"
}

resource "google_project_iam_member" "marisa-demo1-free-api-2_sa-servicemanagement-serviceController" {
  member  = google_service_account.free-api-2_sa.member
  project = "deft-landing-343414"
  role    = "roles/servicemanagement.serviceController"
}

resource "google_project_iam_member" "marisa-demo1-free-entry_sa-bigquery-jobUser" {
  member  = google_service_account.free-entry_sa.member
  project = "deft-landing-343414"
  role    = "roles/bigquery.jobUser"
}

resource "google_project_iam_member" "marisa-demo1-free-scheduler-sa-workflows-invoker" {
  member  = google_service_account.free-scheduler-sa.member
  project = "deft-landing-343414"
  role    = "roles/workflows.invoker"
}

resource "google_project_iam_member" "marisa-demo1-free-workflow_sa-logging-logWriter" {
  member  = google_service_account.free-workflow_sa.member
  project = "deft-landing-343414"
  role    = "roles/logging.logWriter"
}

resource "google_service_account" "free-api-2_sa" {
  account_id                   = "free-api-sa"
  create_ignore_already_exists = false
  deletion_policy              = "DELETE"
  disabled                     = false
  depends_on                   = [google_project_service.iam]
}

resource "google_service_account" "free-entry_sa" {
  account_id                   = "free-entry-sa"
  create_ignore_already_exists = false
  deletion_policy              = "DELETE"
  disabled                     = false
  depends_on                   = [google_project_service.iam]
}

resource "google_service_account" "free-job_sa" {
  account_id                   = "free-job-sa"
  create_ignore_already_exists = false
  deletion_policy              = "DELETE"
  disabled                     = false
  depends_on                   = [google_project_service.iam]
}

resource "google_service_account" "free-relay_sa" {
  account_id                   = "free-relay-sa"
  create_ignore_already_exists = false
  deletion_policy              = "DELETE"
  disabled                     = false
  depends_on                   = [google_project_service.iam]
}

resource "google_service_account" "free-scheduler-sa" {
  account_id                   = "free-scheduler-sa"
  create_ignore_already_exists = false
  deletion_policy              = "DELETE"
  disabled                     = false
  depends_on                   = [google_project_service.iam]
}

resource "google_service_account" "free-sink_sa" {
  account_id                   = "free-sink-sa"
  create_ignore_already_exists = false
  deletion_policy              = "DELETE"
  disabled                     = false
  depends_on                   = [google_project_service.iam]
}

resource "google_service_account" "free-template_sa" {
  account_id                   = "free-template-sa"
  create_ignore_already_exists = false
  deletion_policy              = "DELETE"
  disabled                     = false
  depends_on                   = [google_project_service.iam]
}

resource "google_service_account" "free-vm_sa" {
  account_id                   = "free-vm-sa"
  create_ignore_already_exists = false
  deletion_policy              = "DELETE"
  disabled                     = false
  depends_on                   = [google_project_service.iam]
}

resource "google_service_account" "free-workflow_sa" {
  account_id                   = "free-workflow-sa"
  create_ignore_already_exists = false
  deletion_policy              = "DELETE"
  disabled                     = false
  depends_on                   = [google_project_service.iam]
}

resource "google_secret_manager_secret" "free-last-message" {
  secret_id           = "free-last-message"
  deletion_policy     = "DELETE"
  deletion_protection = false
  replication {
    user_managed {
      replicas {
        location = "us-central1"
      }
    }
  }
  depends_on = [google_project_service.secretmanager]
}

resource "google_secret_manager_secret_iam_member" "free-last-message-free-relay_sa-secretmanager-secretVersionAdder" {
  secret_id = google_secret_manager_secret.free-last-message.secret_id
  member    = google_service_account.free-relay_sa.member
  role      = "roles/secretmanager.secretVersionAdder"
}




### CATEGORY: NETWORK ###

resource "google_compute_network" "free-vpc" {
  name                                      = "free-vpc"
  auto_create_subnetworks                   = false
  delete_default_routes_on_create           = false
  deletion_policy                           = "DELETE"
  enable_ula_internal_ipv6                  = false
  network_firewall_policy_enforcement_order = "AFTER_CLASSIC_FIREWALL"
  routing_mode                              = "REGIONAL"
  depends_on                                = [google_project_service.compute]
}

resource "google_compute_subnetwork" "free-subnet" {
  name                             = "free-subnet"
  allow_subnet_cidr_routes_overlap = false
  deletion_policy                  = "DELETE"
  ip_cidr_range                    = "10.20.0.0/24"
  network                          = google_compute_network.free-vpc.id
  private_ip_google_access         = true
  purpose                          = "PRIVATE"
  region                           = "us-central1"
  send_secondary_ip_range_if_empty = false
  stack_type                       = "IPV4_ONLY"
  depends_on                       = [google_project_service.compute]
}

resource "google_compute_firewall" "free-fw-iap" {
  name            = "free-fw-iap"
  deletion_policy = "DELETE"
  direction       = "INGRESS"
  disabled        = false
  enable_logging  = false
  network         = google_compute_network.free-vpc.id
  priority        = 1000
  source_ranges   = ["35.235.240.0/20"]
  target_tags     = ["fw-free-fw-iap"]
  allow {
    ports    = ["22"]
    protocol = "tcp"
  }
  depends_on = [google_project_service.compute]
}

resource "google_compute_router" "free-router" {
  name                          = "free-router"
  deletion_policy               = "DELETE"
  encrypted_interconnect_router = false
  network                       = google_compute_network.free-vpc.id
  region                        = "us-central1"
  depends_on                    = [google_project_service.compute]
}

resource "google_compute_health_check" "free-hc" {
  name                = "free-hc"
  check_interval_sec  = 5
  deletion_policy     = "DELETE"
  healthy_threshold   = 2
  timeout_sec         = 5
  unhealthy_threshold = 2
  tcp_health_check {
    port = 80
  }
  depends_on = [google_project_service.compute]
}




### CATEGORY: STORAGE ###

resource "google_storage_bucket" "deft-landing-343414-free-archive" {
  name                        = "deft-landing-343414-free-archive"
  default_event_based_hold    = false
  deletion_policy             = "DELETE"
  enable_object_retention     = false
  force_destroy               = true
  location                    = "us-central1"
  public_access_prevention    = "enforced"
  requester_pays              = false
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  depends_on                  = [google_project_service.storage]
}

resource "google_storage_bucket" "deft-landing-343414-free-code" {
  name                        = "deft-landing-343414-free-code"
  default_event_based_hold    = false
  deletion_policy             = "DELETE"
  enable_object_retention     = false
  force_destroy               = true
  location                    = "us-central1"
  public_access_prevention    = "enforced"
  requester_pays              = false
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  depends_on                  = [google_project_service.storage]
}

resource "google_storage_bucket" "deft-landing-343414-free-data" {
  name                        = "deft-landing-343414-free-data"
  default_event_based_hold    = false
  deletion_policy             = "DELETE"
  enable_object_retention     = false
  force_destroy               = true
  location                    = "us-central1"
  public_access_prevention    = "enforced"
  requester_pays              = false
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  depends_on                  = [google_project_service.storage]
}

resource "google_storage_bucket_iam_member" "deft-landing-343414-free-archive-free-log-sink-sink-storage-objectCreator" {
  bucket = google_storage_bucket.deft-landing-343414-free-archive.name
  member = google_logging_project_sink.free-log-sink.writer_identity
  role   = "roles/storage.objectCreator"
}

resource "google_storage_bucket_iam_member" "deft-landing-343414-free-archive-pubsub-storage-legacyBucketReader" {
  bucket     = google_storage_bucket.deft-landing-343414-free-archive.name
  member     = "serviceAccount:service-${data.google_project.pubsub-project.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
  role       = "roles/storage.legacyBucketReader"
  depends_on = [google_project_service.pubsub]
}

resource "google_storage_bucket_iam_member" "deft-landing-343414-free-archive-pubsub-storage-objectCreator" {
  bucket     = google_storage_bucket.deft-landing-343414-free-archive.name
  member     = "serviceAccount:service-${data.google_project.pubsub-project.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
  role       = "roles/storage.objectCreator"
  depends_on = [google_project_service.pubsub]
}

resource "google_storage_bucket_iam_member" "deft-landing-343414-free-data-free-entry_sa-storage-objectUser" {
  bucket = google_storage_bucket.deft-landing-343414-free-data.name
  member = google_service_account.free-entry_sa.member
  role   = "roles/storage.objectUser"
}

resource "google_storage_bucket_iam_member" "deft-landing-343414-free-data-free-sink_sa-storage-objectUser" {
  bucket = google_storage_bucket.deft-landing-343414-free-data.name
  member = google_service_account.free-sink_sa.member
  role   = "roles/storage.objectUser"
}

resource "google_storage_bucket_iam_member" "deft-landing-343414-free-data-free-vm_sa-storage-objectUser" {
  bucket = google_storage_bucket.deft-landing-343414-free-data.name
  member = google_service_account.free-vm_sa.member
  role   = "roles/storage.objectUser"
}

data "archive_file" "free-entry-source" {
  output_path = "${path.module}/free-entry-source.zip"
  source_dir  = "${path.module}/.external_modules/struct8-hub/prebuilt-gcp"
  type        = "zip"
}

resource "google_storage_bucket_object" "free-entry-source" {
  source       = data.archive_file.free-entry-source.output_path
  name         = "functions/free-entry-${data.archive_file.free-entry-source.output_md5}.zip"
  bucket       = google_storage_bucket.deft-landing-343414-free-code.name
  content_type = "application/zip"
}

resource "google_storage_bucket_object" "free-object" {
  name       = "free-object"
  bucket     = google_storage_bucket.deft-landing-343414-free-data.name
  content    = "free lab"
  depends_on = [google_project_service.storage]
}

data "archive_file" "free-relay-source" {
  output_path = "${path.module}/free-relay-source.zip"
  source_dir  = "${path.module}/.external_modules/struct8-hub/prebuilt-gcp"
  type        = "zip"
}

resource "google_storage_bucket_object" "free-relay-source" {
  source       = data.archive_file.free-relay-source.output_path
  name         = "functions/free-relay-${data.archive_file.free-relay-source.output_md5}.zip"
  bucket       = google_storage_bucket.deft-landing-343414-free-code.name
  content_type = "application/zip"
}

data "archive_file" "free-sink-source" {
  output_path = "${path.module}/free-sink-source.zip"
  source_dir  = "${path.module}/.external_modules/struct8-hub/prebuilt-gcp"
  type        = "zip"
}

resource "google_storage_bucket_object" "free-sink-source" {
  source       = data.archive_file.free-sink-source.output_path
  name         = "functions/free-sink-${data.archive_file.free-sink-source.output_md5}.zip"
  bucket       = google_storage_bucket.deft-landing-343414-free-code.name
  content_type = "application/zip"
}

resource "google_storage_notification" "free-notify" {
  bucket         = google_storage_bucket.deft-landing-343414-free-data.name
  payload_format = "JSON_API_V1"
  topic          = google_pubsub_topic.free-events.id
  depends_on     = [google_pubsub_topic_iam_member.free-events-gcs-pubsub-publisher, google_project_service.pubsub, google_project_service.storage]
}

resource "google_artifact_registry_repository" "free-repo" {
  repository_id          = "free-repo"
  cleanup_policy_dry_run = true
  deletion_policy        = "DELETE"
  format                 = "DOCKER"
  location               = "us-central1"
  mode                   = "STANDARD_REPOSITORY"
  depends_on             = [google_project_service.artifactregistry]
}

resource "google_artifact_registry_repository_iam_member" "free-repo-free-vm_sa-artifactregistry-reader" {
  location   = google_artifact_registry_repository.free-repo.location
  member     = google_service_account.free-vm_sa.member
  repository = google_artifact_registry_repository.free-repo.repository_id
  role       = "roles/artifactregistry.reader"
}




### CATEGORY: DATABASE ###

resource "google_firestore_database" "free-firestore-2" {
  location_id             = "nam5"
  name                    = "free-firestore-2"
  database_edition        = "STANDARD"
  delete_protection_state = "DELETE_PROTECTION_DISABLED"
  type                    = "FIRESTORE_NATIVE"
  depends_on              = [google_project_service.firestore]
}




### CATEGORY: COMPUTE ###

resource "google_compute_instance" "free-vm" {
  name                      = "free-vm"
  allow_stopping_for_update = false
  can_ip_forward            = false
  deletion_policy           = "DELETE"
  deletion_protection       = false
  desired_status            = "RUNNING"
  enable_display            = false
  machine_type              = "e2-micro"
  resource_policies         = [google_compute_resource_policy.free-policy.self_link]
  tags                      = ["fw-free-fw-iap"]
  zone                      = "us-central1-a"
  boot_disk {
    auto_delete = true
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = 10
      type  = "pd-standard"
    }
  }
  network_interface {
    subnetwork = google_compute_subnetwork.free-subnet.id
  }
  service_account {
    email  = google_service_account.free-vm_sa.email
    scopes = ["cloud-platform"]
  }
  depends_on = [google_storage_bucket_iam_member.deft-landing-343414-free-data-free-vm_sa-storage-objectUser, google_artifact_registry_repository_iam_member.free-repo-free-vm_sa-artifactregistry-reader, google_project_service.compute]
}

resource "google_compute_instance_template" "free-template" {
  can_ip_forward = false
  machine_type   = "e2-micro"
  name_prefix    = "free-template"
  disk {
    auto_delete  = true
    boot         = true
    source_image = "debian-cloud/debian-12"
  }
  lifecycle {
    create_before_destroy = true
  }
  network_interface {
    stack_type = "IPV4_ONLY"
    subnetwork = google_compute_subnetwork.free-subnet.id
  }
  service_account {
    email  = google_service_account.free-template_sa.email
    scopes = ["cloud-platform"]
  }
  depends_on = [google_project_service.compute]
}

resource "google_compute_resource_policy" "free-policy" {
  name   = "free-policy"
  region = "us-central1"
  instance_schedule_policy {
    time_zone = "UTC"
    vm_stop_schedule {
      schedule = "0 22 * * *"
    }
  }
  depends_on = [google_project_service.compute]
}

resource "google_cloud_run_v2_job" "free-job" {
  name                = "free-job"
  deletion_protection = false
  location            = "us-central1"
  template {
    parallelism = 1
    task_count  = 1
    template {
      max_retries     = 0
      service_account = google_service_account.free-job_sa.email
      timeout         = "60s"
      containers {
        image = "us-docker.pkg.dev/cloudrun/container/job:latest"
      }
    }
  }
  depends_on = [google_pubsub_topic_iam_member.free-events-free-job_sa-pubsub-publisher, google_project_service.run]
}

resource "google_cloud_run_v2_service" "free-api-2-esp" {
  name                = "free-api-2-esp"
  deletion_protection = false
  location            = "us-central1"
  template {
    service_account = google_service_account.free-api-2_sa.email
    containers {
      image = "gcr.io/endpoints-release/endpoints-runtime-serverless:2"
      env {
        name  = "ENDPOINTS_SERVICE_NAME"
        value = google_endpoints_service.free-api-2.service_name
      }
      env {
        name  = "ENDPOINTS_SERVICE_VERSION"
        value = google_endpoints_service.free-api-2.config_id
      }
    }
  }
  depends_on = [google_project_service.free-api-2-enable, google_project_iam_member.marisa-demo1-free-api-2_sa-servicemanagement-serviceController, google_project_iam_member.marisa-demo1-free-api-2_sa-cloudtrace-agent]
}

resource "google_cloud_run_v2_service_iam_member" "free-api-2-esp-allusers-run-invoker" {
  name     = google_cloud_run_v2_service.free-api-2-esp.name
  location = google_cloud_run_v2_service.free-api-2-esp.location
  member   = "allUsers"
  role     = "roles/run.invoker"
}

resource "google_cloud_run_v2_service_iam_member" "free-entry-free-api-2_sa-run-invoker" {
  name     = google_cloudfunctions2_function.free-entry.name
  location = google_cloudfunctions2_function.free-entry.location
  member   = google_service_account.free-api-2_sa.member
  role     = "roles/run.invoker"
}

resource "google_cloud_run_v2_service_iam_member" "free-entry-free-workflow_sa-run-invoker" {
  name     = google_cloudfunctions2_function.free-entry.name
  location = google_cloudfunctions2_function.free-entry.location
  member   = google_service_account.free-workflow_sa.member
  role     = "roles/run.invoker"
}

resource "google_cloud_run_v2_service_iam_member" "free-relay-free-entry_sa-run-invoker" {
  name     = google_cloudfunctions2_function.free-relay.name
  location = google_cloudfunctions2_function.free-relay.location
  member   = google_service_account.free-entry_sa.member
  role     = "roles/run.invoker"
}

resource "google_cloud_run_v2_service_iam_member" "free-sink-free-relay_sa-run-invoker" {
  name     = google_cloudfunctions2_function.free-sink.name
  location = google_cloudfunctions2_function.free-sink.location
  member   = google_service_account.free-relay_sa.member
  role     = "roles/run.invoker"
}

resource "google_cloudfunctions2_function" "free-entry" {
  name     = "free-entry"
  location = "us-central1"
  build_config {
    source {
      storage_source {
        bucket = google_storage_bucket.deft-landing-343414-free-code.name
        object = google_storage_bucket_object.free-entry-source.name
      }
    }
    entry_point = "handler"
    runtime     = "nodejs22"
  }
  service_config {
    service_account_email = google_service_account.free-entry_sa.email
    environment_variables = {
    NAME                                  = "free-entry"
    GOOGLE_CLOUDFUNCTIONS2_FUNCTION_URL_0 = google_cloudfunctions2_function.free-relay.url
    GOOGLE_PUBSUB_TOPIC_NAME_0            = "free-events"
    GOOGLE_STORAGE_BUCKET_NAME_0          = "deft-landing-343414-free-data"
    GOOGLE_BIGQUERY_DATASET_NAME_0        = "free_dataset"
    GOOGLE_SERVICE_ACCOUNT_NAME_0         = "free-entry_sa"
  }
  }
  depends_on = [google_pubsub_topic_iam_member.free-events-free-entry_sa-pubsub-publisher, google_cloud_run_v2_service_iam_member.free-relay-free-entry_sa-run-invoker, google_storage_bucket_iam_member.deft-landing-343414-free-data-free-entry_sa-storage-objectUser, google_bigquery_dataset_iam_member.free_dataset-free-entry_sa-bigquery-dataEditor, google_project_iam_member.marisa-demo1-free-entry_sa-bigquery-jobUser, google_project_service.artifactregistry, google_project_service.cloudbuild, google_project_service.cloudfunctions, google_project_service.run]
}

resource "google_cloudfunctions2_function" "free-relay" {
  name     = "free-relay"
  location = "us-central1"
  build_config {
    source {
      storage_source {
        bucket = google_storage_bucket.deft-landing-343414-free-code.name
        object = google_storage_bucket_object.free-relay-source.name
      }
    }
    entry_point = "handler"
    runtime     = "nodejs22"
  }
  service_config {
    service_account_email = google_service_account.free-relay_sa.email
    environment_variables = {
    NAME                                  = "free-relay"
    GOOGLE_CLOUDFUNCTIONS2_FUNCTION_URL_0 = google_cloudfunctions2_function.free-sink.url
    GOOGLE_SECRET_MANAGER_SECRET_NAME_0   = "free-last-message"
    GOOGLE_SERVICE_ACCOUNT_NAME_0         = "free-relay_sa"
  }
  }
  depends_on = [google_secret_manager_secret_iam_member.free-last-message-free-relay_sa-secretmanager-secretVersionAdder, google_cloud_run_v2_service_iam_member.free-sink-free-relay_sa-run-invoker, google_project_service.artifactregistry, google_project_service.cloudbuild, google_project_service.cloudfunctions, google_project_service.run]
}

resource "google_cloudfunctions2_function" "free-sink" {
  name     = "free-sink"
  location = "us-central1"
  build_config {
    source {
      storage_source {
        bucket = google_storage_bucket.deft-landing-343414-free-code.name
        object = google_storage_bucket_object.free-sink-source.name
      }
    }
    entry_point = "handler"
    runtime     = "nodejs22"
  }
  service_config {
    service_account_email = google_service_account.free-sink_sa.email
    environment_variables = {
    NAME                          = "free-sink"
    GOOGLE_STORAGE_BUCKET_NAME_0  = "deft-landing-343414-free-data"
    GOOGLE_PUBSUB_TOPIC_NAME_0    = "free-events"
    GOOGLE_SERVICE_ACCOUNT_NAME_0 = "free-sink_sa"
  }
  }
  depends_on = [google_pubsub_topic_iam_member.free-events-free-sink_sa-pubsub-publisher, google_storage_bucket_iam_member.deft-landing-343414-free-data-free-sink_sa-storage-objectUser, google_project_service.artifactregistry, google_project_service.cloudbuild, google_project_service.cloudfunctions, google_project_service.run]
}




### CATEGORY: ANALYTICS ###

resource "google_bigquery_dataset" "free_dataset" {
  dataset_id                 = "free_dataset"
  delete_contents_on_destroy = true
  deletion_policy            = "DELETE"
  is_case_insensitive        = false
  location                   = "US"
  storage_billing_model      = "LOGICAL"
  depends_on                 = [google_project_service.bigquery]
}

resource "google_bigquery_dataset_iam_member" "free_dataset-free-entry_sa-bigquery-dataEditor" {
  dataset_id = google_bigquery_dataset.free_dataset.dataset_id
  member     = google_service_account.free-entry_sa.member
  role       = "roles/bigquery.dataEditor"
}

resource "google_bigquery_routine" "free_routine" {
  dataset_id      = google_bigquery_dataset.free_dataset.dataset_id
  routine_id      = "free_routine"
  definition_body = "x + 1"
  language        = "SQL"
  return_type     = "{\"typeKind\":\"INT64\"}"
  routine_type    = "SCALAR_FUNCTION"
  arguments {
    name      = "x"
    data_type = "{\"typeKind\":\"INT64\"}"
  }
  depends_on = [google_project_service.bigquery]
}

resource "google_bigquery_table" "free_events" {
  dataset_id          = google_bigquery_dataset.free_dataset.dataset_id
  table_id            = "free_events"
  deletion_protection = false
  expiration_time     = 0
  schema              = "[{\"name\":\"message\",\"type\":\"STRING\",\"mode\":\"NULLABLE\"},{\"name\":\"ts\",\"type\":\"TIMESTAMP\",\"mode\":\"NULLABLE\"}]"
  depends_on          = [google_project_service.bigquery]
}




### CATEGORY: INTEGRATION ###

resource "google_pubsub_subscription" "free-events-archive" {
  name                         = "free-events-archive"
  ack_deadline_seconds         = 10
  deletion_policy              = "DELETE"
  enable_exactly_once_delivery = false
  enable_message_ordering      = false
  message_retention_duration   = "604800s"
  retain_acked_messages        = false
  topic                        = google_pubsub_topic.free-events.name
  cloud_storage_config {
    bucket          = google_storage_bucket.deft-landing-343414-free-archive.name
    filename_prefix = "events/"
    max_duration    = "60s"
  }
  depends_on = [time_sleep.free-events-archive-iam-wait, google_project_service.pubsub]
}

resource "google_pubsub_subscription" "free-events-pull" {
  name                         = "free-events-pull"
  ack_deadline_seconds         = 10
  deletion_policy              = "DELETE"
  enable_exactly_once_delivery = false
  enable_message_ordering      = false
  message_retention_duration   = "604800s"
  retain_acked_messages        = false
  topic                        = google_pubsub_topic.free-events.name
  depends_on                   = [google_project_service.pubsub]
}

resource "google_pubsub_topic" "free-events" {
  name                       = "free-events"
  deletion_policy            = "DELETE"
  message_retention_duration = "604800s"
  depends_on                 = [google_project_service.pubsub]
}

resource "google_pubsub_topic_iam_member" "free-events-free-entry_sa-pubsub-publisher" {
  member = google_service_account.free-entry_sa.member
  role   = "roles/pubsub.publisher"
  topic  = google_pubsub_topic.free-events.name
}

resource "google_pubsub_topic_iam_member" "free-events-free-job_sa-pubsub-publisher" {
  member = google_service_account.free-job_sa.member
  role   = "roles/pubsub.publisher"
  topic  = google_pubsub_topic.free-events.name
}

resource "google_pubsub_topic_iam_member" "free-events-free-sink_sa-pubsub-publisher" {
  member = google_service_account.free-sink_sa.member
  role   = "roles/pubsub.publisher"
  topic  = google_pubsub_topic.free-events.name
}

resource "google_pubsub_topic_iam_member" "free-events-gcs-pubsub-publisher" {
  member = data.google_storage_project_service_account.notification-storage-agent.member
  role   = "roles/pubsub.publisher"
  topic  = google_pubsub_topic.free-events.name
}

resource "google_cloud_scheduler_job" "free-scheduler" {
  name     = "free-scheduler"
  paused   = true
  region   = "us-central1"
  schedule = "0 * * * *"
  http_target {
    http_method = "POST"
    uri         = "https://workflowexecutions.googleapis.com/v1/${google_workflows_workflow.free-workflow.id}/executions"
    oauth_token {
      service_account_email = google_service_account.free-scheduler-sa.email
    }
  }
  depends_on = [google_project_iam_member.marisa-demo1-free-scheduler-sa-workflows-invoker, google_project_service.cloudscheduler]
}

resource "google_cloud_tasks_queue" "free-queue-2" {
  name       = "free-queue-2"
  location   = "us-central1"
  depends_on = [google_project_service.cloudtasks]
}

resource "google_workflows_workflow" "free-workflow" {
  name                = "free-workflow"
  deletion_protection = false
  region              = "us-central1"
  service_account     = google_service_account.free-workflow_sa.email
  source_contents = <<EOF
main:
  params: [input]
  steps:
    - call_entry:
        call: http.post
        args:
          url: $${sys.get_env("FREE_ENTRY_URL")}
          auth:
            type: OIDC
          body:
            message: from-workflow
        result: out
    - finish:
        return: $${out.body}
  EOF
  user_env_vars = {
    FREE_ENTRY_URL = google_cloudfunctions2_function.free-entry.url
  }
  depends_on = [google_project_iam_member.marisa-demo1-free-workflow_sa-logging-logWriter, google_cloud_run_v2_service_iam_member.free-entry-free-workflow_sa-run-invoker, google_project_service.workflows]
}

resource "google_endpoints_service" "free-api-2" {
  service_name    = "free-api.endpoints.deft-landing-343414.cloud.goog"
  deletion_policy = "DELETE"
  openapi_config = <<EOF
swagger: "2.0"
info:
  title: free-api
  version: "1.0.0"
host: free-api.endpoints.deft-landing-343414.cloud.goog
schemes:
  - https
produces:
  - application/json
paths:
  /free-entry:
    post:
      operationId: post_free_entry
      x-google-backend:
        address: ${google_cloudfunctions2_function.free-entry.url}
      responses:
        "200":
          description: OK
  EOF
  depends_on = [google_cloud_run_v2_service_iam_member.free-entry-free-api-2_sa-run-invoker, google_project_service.endpoints, google_project_service.run, google_project_service.servicecontrol, google_project_service.servicemanagement]
}




### CATEGORY: MONITORING ###

resource "google_monitoring_dashboard" "free-dashboard" {
  dashboard_json  = "{\"displayName\":\"free-lab\",\"gridLayout\":{\"widgets\":[{\"title\":\"Cloud Run: requisicoes\",\"xyChart\":{\"dataSets\":[{\"timeSeriesQuery\":{\"timeSeriesFilter\":{\"filter\":\"metric.type=\\\"run.googleapis.com/request_count\\\" resource.type=\\\"cloud_run_revision\\\"\",\"aggregation\":{\"perSeriesAligner\":\"ALIGN_RATE\"}}}}]}}]}}"
  deletion_policy = "DELETE"
  depends_on      = [google_project_service.monitoring]
}

resource "google_monitoring_notification_channel" "free-email" {
  display_name    = "free-email"
  deletion_policy = "DELETE"
  enabled         = true
  force_delete    = false
  type            = "email"
  labels = {
    email_address = "contact@struct8.com"
  }
  depends_on = [google_project_service.monitoring]
}

resource "google_monitoring_uptime_check_config" "free-uptime" {
  display_name       = "free-uptime"
  deletion_policy    = "DELETE"
  log_check_failures = false
  period             = "900s"
  timeout            = "10s"
  http_check {
    path         = "/"
    port         = 443
    use_ssl      = true
    validate_ssl = true
    accepted_response_status_codes {
      status_class = "STATUS_CLASS_4XX"
    }
  }
  monitored_resource {
    type = "uptime_url"
    labels = {
    host       = "free-api-esp-233610591017.us-central1.run.app"
    project_id = "deft-landing-343414"
  }
  }
  depends_on = [google_project_service.monitoring]
}

resource "google_logging_metric" "free-errors" {
  name            = "free-errors"
  deletion_policy = "DELETE"
  disabled        = false
  filter          = "resource.type=\"cloud_run_revision\" AND severity>=ERROR"
  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
  }
  depends_on = [google_project_service.logging]
}

resource "google_logging_project_sink" "free-log-sink" {
  name                   = "free-log-sink"
  deletion_policy        = "DELETE"
  destination            = "storage.googleapis.com/${google_storage_bucket.deft-landing-343414-free-archive.name}"
  disabled               = false
  unique_writer_identity = true
  depends_on             = [google_project_service.logging]
}




### CATEGORY: MISC ###

resource "time_sleep" "free-events-archive-iam-wait" {
  create_duration = "120s"
  depends_on      = [google_storage_bucket_iam_member.deft-landing-343414-free-archive-pubsub-storage-objectCreator, google_storage_bucket_iam_member.deft-landing-343414-free-archive-pubsub-storage-legacyBucketReader]
}


