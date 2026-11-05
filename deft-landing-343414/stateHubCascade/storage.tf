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
