resource "google_cloud_run_v2_service_iam_member" "cross-gateway-cross-link-run-invoker" {
  name     = google_cloudfunctions2_function.cross-gateway.name
  location = google_cloudfunctions2_function.cross-gateway.location
  member   = google_service_account.cross-link.member
  role     = "roles/run.invoker"
}

resource "google_cloud_run_v2_service_iam_member" "cross-listener-cross-listener_sa-run-invoker" {
  name     = google_cloudfunctions2_function.cross-listener.name
  location = google_cloudfunctions2_function.cross-listener.location
  member   = google_service_account.cross-listener_sa.member
  role     = "roles/run.invoker"
}

resource "google_cloud_run_v2_service_iam_member" "cross-worker-cross-gateway_sa-run-invoker" {
  name     = google_cloudfunctions2_function.cross-worker.name
  location = google_cloudfunctions2_function.cross-worker.location
  member   = google_service_account.cross-gateway_sa.member
  role     = "roles/run.invoker"
}

resource "google_cloudfunctions2_function" "cross-gateway" {
  name     = "cross-gateway"
  location = "us-central1"
  build_config {
    source {
      storage_source {
        bucket = google_storage_bucket.deft-landing-343414-cross-code.name
        object = google_storage_bucket_object.cross-gateway-source.name
      }
    }
    entry_point = "handler"
    runtime     = "nodejs22"
  }
  service_config {
    service_account_email = google_service_account.cross-gateway_sa.email
    environment_variables = {
      HUB_TRACE                             = "on"
      NAME                                  = "cross-gateway"
      GOOGLE_CLOUDFUNCTIONS2_FUNCTION_URL_0 = google_cloudfunctions2_function.cross-worker.url
      GOOGLE_PUBSUB_TOPIC_NAME_0            = "cross-events"
    }
  }
  depends_on = [google_project_iam_member.marisa-demo1-cross-gateway_sa-telemetry-tracesWriter, google_cloud_run_v2_service_iam_member.cross-worker-cross-gateway_sa-run-invoker, google_pubsub_topic_iam_member.cross-events-cross-gateway_sa-pubsub-publisher, google_project_service.artifactregistry, google_project_service.cloudbuild, google_project_service.cloudfunctions, google_project_service.run, google_project_service.telemetry]
}

resource "google_cloudfunctions2_function" "cross-listener" {
  name     = "cross-listener"
  location = "us-central1"
  build_config {
    source {
      storage_source {
        bucket = google_storage_bucket.deft-landing-343414-cross-code.name
        object = google_storage_bucket_object.cross-listener-source.name
      }
    }
    entry_point = "handler"
    runtime     = "nodejs22"
  }
  event_trigger {
    event_type            = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic          = google_pubsub_topic.cross-events.id
    retry_policy          = "RETRY_POLICY_DO_NOT_RETRY"
    service_account_email = google_service_account.cross-listener_sa.email
    trigger_region        = "us-central1"
  }
  service_config {
    service_account_email = google_service_account.cross-listener_sa.email
    environment_variables = {
      HUB_TRACE = "on"
      NAME      = "cross-listener"
    }
  }
  depends_on = [google_project_iam_member.marisa-demo1-cross-listener_sa-telemetry-tracesWriter, google_project_service.artifactregistry, google_project_service.cloudbuild, google_project_service.cloudfunctions, google_project_service.eventarc, google_project_service.pubsub, google_project_service.run, google_project_service.telemetry]
}

resource "google_cloudfunctions2_function" "cross-worker" {
  name     = "cross-worker"
  location = "us-central1"
  build_config {
    source {
      storage_source {
        bucket = google_storage_bucket.deft-landing-343414-cross-code.name
        object = google_storage_bucket_object.cross-worker-source.name
      }
    }
    entry_point = "handler"
    runtime     = "nodejs22"
  }
  service_config {
    service_account_email = google_service_account.cross-worker_sa.email
    environment_variables = {
      HUB_TRACE                    = "on"
      NAME                         = "cross-worker"
      GOOGLE_STORAGE_BUCKET_NAME_0 = "deft-landing-343414-cross-data"
    }
  }
  depends_on = [google_project_iam_member.marisa-demo1-cross-worker_sa-telemetry-tracesWriter, google_storage_bucket_iam_member.deft-landing-343414-cross-data-cross-worker_sa-storage-objectUser, google_project_service.artifactregistry, google_project_service.cloudbuild, google_project_service.cloudfunctions, google_project_service.run, google_project_service.telemetry]
}
