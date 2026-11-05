resource "google_pubsub_topic" "cross-events" {
  name                       = "cross-events"
  deletion_policy            = "DELETE"
  message_retention_duration = "604800s"
  depends_on                 = [google_project_service.pubsub]
}

resource "google_pubsub_topic_iam_member" "cross-events-cross-gateway_sa-pubsub-publisher" {
  member = google_service_account.cross-gateway_sa.member
  role   = "roles/pubsub.publisher"
  topic  = google_pubsub_topic.cross-events.name
}

resource "google_pubsub_topic_iam_member" "cross-events-cross-link-pubsub-publisher" {
  member = google_service_account.cross-link.member
  role   = "roles/pubsub.publisher"
  topic  = google_pubsub_topic.cross-events.name
}
