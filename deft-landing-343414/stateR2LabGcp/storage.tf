resource "google_storage_bucket" "deft-landing-343414-r2-lab-code" {
  name                        = "deft-landing-343414-r2-lab-code"
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
    struct8_state   = "stater2labgcp"
    struct8_creator = "contato_struct"
  }
  depends_on = [google_project_service.storage]
}

data "archive_file" "r2-lab-gcp-fn-source" {
  output_path = "${path.module}/r2-lab-gcp-fn-source.zip"
  source_dir  = "${path.module}/.external_modules/Import/lab/r2-gateway-gcp/function"
  type        = "zip"
}

resource "google_storage_bucket_object" "r2-lab-gcp-fn-source" {
  source       = data.archive_file.r2-lab-gcp-fn-source.output_path
  name         = "functions/r2-lab-gcp-fn-${data.archive_file.r2-lab-gcp-fn-source.output_md5}.zip"
  bucket       = google_storage_bucket.deft-landing-343414-r2-lab-code.name
  content_type = "application/zip"
}

data "archive_file" "r2-lab-gcp-intruder-source" {
  output_path = "${path.module}/r2-lab-gcp-intruder-source.zip"
  source_dir  = "${path.module}/.external_modules/Import/lab/r2-gateway-gcp/function"
  type        = "zip"
}

resource "google_storage_bucket_object" "r2-lab-gcp-intruder-source" {
  source       = data.archive_file.r2-lab-gcp-intruder-source.output_path
  name         = "functions/r2-lab-gcp-intruder-${data.archive_file.r2-lab-gcp-intruder-source.output_md5}.zip"
  bucket       = google_storage_bucket.deft-landing-343414-r2-lab-code.name
  content_type = "application/zip"
}
