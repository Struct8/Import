resource "google_storage_bucket" "deft-landing-343414-cross-code" {
  name                        = "deft-landing-343414-cross-code"
  default_event_based_hold    = false
  deletion_policy             = "DELETE"
  enable_object_retention     = false
  force_destroy               = true
  location                    = "us-central1"
  public_access_prevention    = "enforced"
  requester_pays              = false
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  labels = {
    struct8_state   = "statehubcrossgoogle"
    struct8_creator = "contato_struct"
  }
  depends_on = [google_project_service.storage]
}

resource "google_storage_bucket" "deft-landing-343414-cross-data" {
  name                        = "deft-landing-343414-cross-data"
  default_event_based_hold    = false
  deletion_policy             = "DELETE"
  enable_object_retention     = false
  force_destroy               = true
  location                    = "us-central1"
  public_access_prevention    = "enforced"
  requester_pays              = false
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  labels = {
    struct8_state   = "statehubcrossgoogle"
    struct8_creator = "contato_struct"
  }
  depends_on = [google_project_service.storage]
}

resource "google_storage_bucket_iam_member" "deft-landing-343414-cross-data-cross-link-storage-objectUser" {
  bucket = google_storage_bucket.deft-landing-343414-cross-data.name
  member = google_service_account.cross-link.member
  role   = "roles/storage.objectUser"
}

resource "google_storage_bucket_iam_member" "deft-landing-343414-cross-data-cross-worker_sa-storage-objectUser" {
  bucket = google_storage_bucket.deft-landing-343414-cross-data.name
  member = google_service_account.cross-worker_sa.member
  role   = "roles/storage.objectUser"
}

data "archive_file" "cross-gateway-source" {
  output_path = "${path.module}/cross-gateway-source.zip"
  source_dir  = "${path.module}/.external_modules/struct8-hub/prebuilt-gcp"
  type        = "zip"
}

resource "google_storage_bucket_object" "cross-gateway-source" {
  source       = data.archive_file.cross-gateway-source.output_path
  name         = "functions/cross-gateway-${data.archive_file.cross-gateway-source.output_md5}.zip"
  bucket       = google_storage_bucket.deft-landing-343414-cross-code.name
  content_type = "application/zip"
}

data "archive_file" "cross-listener-source" {
  output_path = "${path.module}/cross-listener-source.zip"
  source_dir  = "${path.module}/.external_modules/struct8-hub/prebuilt-gcp"
  type        = "zip"
}

resource "google_storage_bucket_object" "cross-listener-source" {
  source       = data.archive_file.cross-listener-source.output_path
  name         = "functions/cross-listener-${data.archive_file.cross-listener-source.output_md5}.zip"
  bucket       = google_storage_bucket.deft-landing-343414-cross-code.name
  content_type = "application/zip"
}

data "archive_file" "cross-worker-source" {
  output_path = "${path.module}/cross-worker-source.zip"
  source_dir  = "${path.module}/.external_modules/struct8-hub/prebuilt-gcp"
  type        = "zip"
}

resource "google_storage_bucket_object" "cross-worker-source" {
  source       = data.archive_file.cross-worker-source.output_path
  name         = "functions/cross-worker-${data.archive_file.cross-worker-source.output_md5}.zip"
  bucket       = google_storage_bucket.deft-landing-343414-cross-code.name
  content_type = "application/zip"
}
