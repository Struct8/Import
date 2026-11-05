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
  depends_on = [google_project_service.hub-api-enable, google_project_iam_member.marisa-demo1-hub-api_sa-servicemanagement-serviceController, google_project_iam_member.marisa-demo1-hub-api_sa-cloudtrace-agent]
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
      NAME                         = "hub-sink"
      GOOGLE_STORAGE_BUCKET_NAME_0 = "deft-landing-343414-hub-data"
      GOOGLE_PUBSUB_TOPIC_NAME_0   = "hub-events"
    }
  }
  depends_on = [google_storage_bucket_iam_member.deft-landing-343414-hub-data-hub-sink_sa-storage-objectUser, google_pubsub_topic_iam_member.hub-events-hub-sink_sa-pubsub-publisher, google_project_service.artifactregistry, google_project_service.cloudbuild, google_project_service.cloudfunctions, google_project_service.run]
}
