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
    key     = "deft-landing-343414/stateHubCascade/main.tfstate"
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




### CATEGORY: FOUNDATION ###

resource "google_project_service" "artifactregistry" {
  disable_on_destroy = false
  service            = "artifactregistry.googleapis.com"
}

resource "google_project_service" "cloudbuild" {
  disable_on_destroy = false
  service            = "cloudbuild.googleapis.com"
}

resource "google_project_service" "cloudfunctions" {
  disable_on_destroy = false
  service            = "cloudfunctions.googleapis.com"
}

resource "google_project_service" "endpoints" {
  disable_on_destroy = false
  service            = "endpoints.googleapis.com"
}

resource "google_project_service" "hub-api-enable" {
  disable_on_destroy = false
  service            = google_endpoints_service.hub-api.service_name
}

resource "google_project_service" "iam" {
  disable_on_destroy = false
  service            = "iam.googleapis.com"
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




### CATEGORY: IAM ###

resource "google_project_iam_member" "marisa-demo1-hub-api_sa-servicemanagement-serviceController" {
  member  = google_service_account.hub-api_sa.member
  project = "deft-landing-343414"
  role    = "roles/servicemanagement.serviceController"
}

resource "google_service_account" "hub-api_sa" {
  account_id                   = "hub-api-sa"
  create_ignore_already_exists = false
  deletion_policy              = "DELETE"
  disabled                     = false
  depends_on                   = [google_project_service.iam]
}

resource "google_service_account" "hub-entry_sa" {
  account_id                   = "hub-entry-sa"
  create_ignore_already_exists = false
  deletion_policy              = "DELETE"
  disabled                     = false
  depends_on                   = [google_project_service.iam]
}

resource "google_service_account" "hub-relay_sa" {
  account_id                   = "hub-relay-sa"
  create_ignore_already_exists = false
  deletion_policy              = "DELETE"
  disabled                     = false
  depends_on                   = [google_project_service.iam]
}

resource "google_service_account" "hub-sink_sa" {
  account_id                   = "hub-sink-sa"
  create_ignore_already_exists = false
  deletion_policy              = "DELETE"
  disabled                     = false
  depends_on                   = [google_project_service.iam]
}

resource "google_secret_manager_secret" "hub-last-message" {
  secret_id           = "hub-last-message"
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

resource "google_secret_manager_secret_iam_member" "hub-last-message-hub-relay_sa-secretmanager-secretVersionAdder" {
  secret_id = google_secret_manager_secret.hub-last-message.secret_id
  member    = google_service_account.hub-relay_sa.member
  role      = "roles/secretmanager.secretVersionAdder"
}




### CATEGORY: STORAGE ###

resource "google_storage_bucket" "deft-landing-343414-hub-archive" {
  name                        = "deft-landing-343414-hub-archive"
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

resource "google_storage_bucket" "deft-landing-343414-hub-code" {
  name                        = "deft-landing-343414-hub-code"
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

resource "google_storage_bucket" "deft-landing-343414-hub-data" {
  name                        = "deft-landing-343414-hub-data"
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

resource "google_storage_bucket_iam_member" "deft-landing-343414-hub-archive-pubsub-storage-legacyBucketReader" {
  bucket     = google_storage_bucket.deft-landing-343414-hub-archive.name
  member     = "serviceAccount:service-${data.google_project.pubsub-project.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
  role       = "roles/storage.legacyBucketReader"
  depends_on = [google_project_service.pubsub]
}

resource "google_storage_bucket_iam_member" "deft-landing-343414-hub-archive-pubsub-storage-objectCreator" {
  bucket     = google_storage_bucket.deft-landing-343414-hub-archive.name
  member     = "serviceAccount:service-${data.google_project.pubsub-project.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
  role       = "roles/storage.objectCreator"
  depends_on = [google_project_service.pubsub]
}

resource "google_storage_bucket_iam_member" "deft-landing-343414-hub-data-hub-entry_sa-storage-objectUser" {
  bucket = google_storage_bucket.deft-landing-343414-hub-data.name
  member = google_service_account.hub-entry_sa.member
  role   = "roles/storage.objectUser"
}

resource "google_storage_bucket_iam_member" "deft-landing-343414-hub-data-hub-sink_sa-storage-objectUser" {
  bucket = google_storage_bucket.deft-landing-343414-hub-data.name
  member = google_service_account.hub-sink_sa.member
  role   = "roles/storage.objectUser"
}

data "archive_file" "hub-entry-source" {
  output_path = "${path.module}/hub-entry-source.zip"
  source_dir  = "${path.module}/.external_modules/struct8-hub/prebuilt-gcp"
  type        = "zip"
}

resource "google_storage_bucket_object" "hub-entry-source" {
  source       = data.archive_file.hub-entry-source.output_path
  name         = "functions/hub-entry-${data.archive_file.hub-entry-source.output_md5}.zip"
  bucket       = google_storage_bucket.deft-landing-343414-hub-code.name
  content_type = "application/zip"
}

data "archive_file" "hub-relay-source" {
  output_path = "${path.module}/hub-relay-source.zip"
  source_dir  = "${path.module}/.external_modules/struct8-hub/prebuilt-gcp"
  type        = "zip"
}

resource "google_storage_bucket_object" "hub-relay-source" {
  source       = data.archive_file.hub-relay-source.output_path
  name         = "functions/hub-relay-${data.archive_file.hub-relay-source.output_md5}.zip"
  bucket       = google_storage_bucket.deft-landing-343414-hub-code.name
  content_type = "application/zip"
}

data "archive_file" "hub-sink-source" {
  output_path = "${path.module}/hub-sink-source.zip"
  source_dir  = "${path.module}/.external_modules/struct8-hub/prebuilt-gcp"
  type        = "zip"
}

resource "google_storage_bucket_object" "hub-sink-source" {
  source       = data.archive_file.hub-sink-source.output_path
  name         = "functions/hub-sink-${data.archive_file.hub-sink-source.output_md5}.zip"
  bucket       = google_storage_bucket.deft-landing-343414-hub-code.name
  content_type = "application/zip"
}




### CATEGORY: COMPUTE ###

resource "google_cloud_run_v2_service" "hub-api-esp" {
  name                = "hub-api-esp"
  deletion_protection = false
  location            = "us-central1"
  template {
    service_account = google_service_account.hub-api_sa.email
    containers {
      image = "gcr.io/endpoints-release/endpoints-runtime-serverless:2"
      env {
        name  = "ENDPOINTS_SERVICE_NAME"
        value = google_endpoints_service.hub-api.service_name
      }
      env {
        name  = "ENDPOINTS_SERVICE_VERSION"
        value = google_endpoints_service.hub-api.config_id
      }
    }
  }
  depends_on = [google_project_service.hub-api-enable, google_project_iam_member.marisa-demo1-hub-api_sa-servicemanagement-serviceController]
}

resource "google_cloud_run_v2_service_iam_member" "hub-api-esp-allusers-run-invoker" {
  name     = google_cloud_run_v2_service.hub-api-esp.name
  location = google_cloud_run_v2_service.hub-api-esp.location
  member   = "allUsers"
  role     = "roles/run.invoker"
}

resource "google_cloud_run_v2_service_iam_member" "hub-entry-hub-api_sa-run-invoker" {
  name     = google_cloudfunctions2_function.hub-entry.name
  location = google_cloudfunctions2_function.hub-entry.location
  member   = google_service_account.hub-api_sa.member
  role     = "roles/run.invoker"
}

resource "google_cloud_run_v2_service_iam_member" "hub-relay-hub-entry_sa-run-invoker" {
  name     = google_cloudfunctions2_function.hub-relay.name
  location = google_cloudfunctions2_function.hub-relay.location
  member   = google_service_account.hub-entry_sa.member
  role     = "roles/run.invoker"
}

resource "google_cloud_run_v2_service_iam_member" "hub-sink-hub-relay_sa-run-invoker" {
  name     = google_cloudfunctions2_function.hub-sink.name
  location = google_cloudfunctions2_function.hub-sink.location
  member   = google_service_account.hub-relay_sa.member
  role     = "roles/run.invoker"
}

resource "google_cloudfunctions2_function" "hub-entry" {
  name     = "hub-entry"
  location = "us-central1"
  build_config {
    source {
      storage_source {
        bucket = google_storage_bucket.deft-landing-343414-hub-code.name
        object = google_storage_bucket_object.hub-entry-source.name
      }
    }
    entry_point = "handler"
    runtime     = "nodejs22"
  }
  service_config {
    service_account_email = google_service_account.hub-entry_sa.email
    environment_variables = {
    NAME                                  = "hub-entry"
    GOOGLE_CLOUDFUNCTIONS2_FUNCTION_URL_0 = google_cloudfunctions2_function.hub-relay.url
    GOOGLE_PUBSUB_TOPIC_NAME_0            = "hub-events"
    GOOGLE_STORAGE_BUCKET_NAME_0          = "deft-landing-343414-hub-data"
    GOOGLE_SERVICE_ACCOUNT_NAME_0         = "hub-entry_sa"
  }
  }
  depends_on = [google_cloud_run_v2_service_iam_member.hub-relay-hub-entry_sa-run-invoker, google_storage_bucket_iam_member.deft-landing-343414-hub-data-hub-entry_sa-storage-objectUser, google_pubsub_topic_iam_member.hub-events-hub-entry_sa-pubsub-publisher, google_project_service.artifactregistry, google_project_service.cloudbuild, google_project_service.cloudfunctions, google_project_service.run]
}

resource "google_cloudfunctions2_function" "hub-relay" {
  name     = "hub-relay"
  location = "us-central1"
  build_config {
    source {
      storage_source {
        bucket = google_storage_bucket.deft-landing-343414-hub-code.name
        object = google_storage_bucket_object.hub-relay-source.name
      }
    }
    entry_point = "handler"
    runtime     = "nodejs22"
  }
  service_config {
    service_account_email = google_service_account.hub-relay_sa.email
    environment_variables = {
    NAME                                  = "hub-relay"
    GOOGLE_CLOUDFUNCTIONS2_FUNCTION_URL_0 = google_cloudfunctions2_function.hub-sink.url
    GOOGLE_SECRET_MANAGER_SECRET_NAME_0   = "hub-last-message"
    GOOGLE_SERVICE_ACCOUNT_NAME_0         = "hub-relay_sa"
  }
  }
  depends_on = [google_cloud_run_v2_service_iam_member.hub-sink-hub-relay_sa-run-invoker, google_secret_manager_secret_iam_member.hub-last-message-hub-relay_sa-secretmanager-secretVersionAdder, google_project_service.artifactregistry, google_project_service.cloudbuild, google_project_service.cloudfunctions, google_project_service.run]
}

resource "google_cloudfunctions2_function" "hub-sink" {
  name     = "hub-sink"
  location = "us-central1"
  build_config {
    source {
      storage_source {
        bucket = google_storage_bucket.deft-landing-343414-hub-code.name
        object = google_storage_bucket_object.hub-sink-source.name
      }
    }
    entry_point = "handler"
    runtime     = "nodejs22"
  }
  service_config {
    service_account_email = google_service_account.hub-sink_sa.email
    environment_variables = {
    NAME                          = "hub-sink"
    GOOGLE_STORAGE_BUCKET_NAME_0  = "deft-landing-343414-hub-data"
    GOOGLE_PUBSUB_TOPIC_NAME_0    = "hub-events"
    GOOGLE_SERVICE_ACCOUNT_NAME_0 = "hub-sink_sa"
  }
  }
  depends_on = [google_storage_bucket_iam_member.deft-landing-343414-hub-data-hub-sink_sa-storage-objectUser, google_pubsub_topic_iam_member.hub-events-hub-sink_sa-pubsub-publisher, google_project_service.artifactregistry, google_project_service.cloudbuild, google_project_service.cloudfunctions, google_project_service.run]
}




### CATEGORY: INTEGRATION ###

resource "google_pubsub_subscription" "hub-events-archive" {
  name                         = "hub-events-archive"
  ack_deadline_seconds         = 10
  deletion_policy              = "DELETE"
  enable_exactly_once_delivery = false
  enable_message_ordering      = false
  message_retention_duration   = "604800s"
  retain_acked_messages        = false
  topic                        = google_pubsub_topic.hub-events.name
  cloud_storage_config {
    bucket          = google_storage_bucket.deft-landing-343414-hub-archive.name
    filename_prefix = "events/"
    max_duration    = "60s"
  }
  depends_on = [time_sleep.hub-events-archive-iam-wait, google_project_service.pubsub]
}

resource "google_pubsub_subscription" "hub-events-pull" {
  name                         = "hub-events-pull"
  ack_deadline_seconds         = 10
  deletion_policy              = "DELETE"
  enable_exactly_once_delivery = false
  enable_message_ordering      = false
  message_retention_duration   = "604800s"
  retain_acked_messages        = false
  topic                        = google_pubsub_topic.hub-events.name
  depends_on                   = [google_project_service.pubsub]
}

resource "google_pubsub_topic" "hub-events" {
  name                       = "hub-events"
  deletion_policy            = "DELETE"
  message_retention_duration = "604800s"
  depends_on                 = [google_project_service.pubsub]
}

resource "google_pubsub_topic_iam_member" "hub-events-hub-entry_sa-pubsub-publisher" {
  member = google_service_account.hub-entry_sa.member
  role   = "roles/pubsub.publisher"
  topic  = google_pubsub_topic.hub-events.name
}

resource "google_pubsub_topic_iam_member" "hub-events-hub-sink_sa-pubsub-publisher" {
  member = google_service_account.hub-sink_sa.member
  role   = "roles/pubsub.publisher"
  topic  = google_pubsub_topic.hub-events.name
}

resource "google_endpoints_service" "hub-api" {
  service_name    = "hub-api.endpoints.deft-landing-343414.cloud.goog"
  deletion_policy = "DELETE"
  openapi_config = <<EOF
swagger: "2.0"
info:
  title: hub-api
  version: "1.0.0"
host: hub-api.endpoints.deft-landing-343414.cloud.goog
schemes:
  - https
produces:
  - application/json
paths:
  /hub-entry:
    post:
      operationId: post_hub_entry
      x-google-backend:
        address: ${google_cloudfunctions2_function.hub-entry.url}
      responses:
        "200":
          description: OK
  EOF
  depends_on = [google_cloud_run_v2_service_iam_member.hub-entry-hub-api_sa-run-invoker, google_project_service.endpoints, google_project_service.run, google_project_service.servicecontrol, google_project_service.servicemanagement]
}




### CATEGORY: MISC ###

resource "time_sleep" "hub-events-archive-iam-wait" {
  create_duration = "120s"
  depends_on      = [google_storage_bucket_iam_member.deft-landing-343414-hub-archive-pubsub-storage-objectCreator, google_storage_bucket_iam_member.deft-landing-343414-hub-archive-pubsub-storage-legacyBucketReader]
}


