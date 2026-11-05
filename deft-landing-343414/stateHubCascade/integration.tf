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
