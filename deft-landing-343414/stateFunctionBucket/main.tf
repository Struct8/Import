terraform {
  required_providers {
    archive = {
      source = "hashicorp/archive"
    }
    google = {
      source = "hashicorp/google"
    }
  }

  backend "s3" {
    bucket  = "struct8-import"
    key     = "deft-landing-343414/stateFunctionBucket/main.tfstate"
    region  = "us-west-2"
    encrypt = true
  }
}

# --- Main Cloud Provider ---
provider "google" {
  project = "deft-landing-343414"
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

resource "google_project_service" "iam" {
  disable_on_destroy = false
  service            = "iam.googleapis.com"
}

resource "google_project_service" "run" {
  disable_on_destroy = false
  service            = "run.googleapis.com"
}

resource "google_project_service" "storage" {
  disable_on_destroy = false
  service            = "storage.googleapis.com"
}




### CATEGORY: IAM ###

resource "google_service_account" "function_sa" {
  account_id                   = "function-sa"
  create_ignore_already_exists = false
  deletion_policy              = "DELETE"
  disabled                     = false
  depends_on                   = [google_project_service.iam]
}




### CATEGORY: STORAGE ###

resource "google_storage_bucket" "deft-landing-343414-fn-code" {
  name                        = "deft-landing-343414-fn-code"
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

resource "google_storage_bucket" "deft-landing-343414-fn-data" {
  name                        = "deft-landing-343414-fn-data"
  default_event_based_hold    = false
  deletion_policy             = "DELETE"
  enable_object_retention     = false
  force_destroy               = true
  location                    = "US"
  public_access_prevention    = "enforced"
  requester_pays              = false
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  depends_on                  = [google_project_service.storage]
}

resource "google_storage_bucket_iam_member" "deft-landing-343414-fn-data-function_sa-storage-objectCreator" {
  bucket = google_storage_bucket.deft-landing-343414-fn-data.name
  member = google_service_account.function_sa.member
  role   = "roles/storage.objectCreator"
}

data "archive_file" "function-source" {
  output_path = "${path.module}/function-source.zip"
  source_dir  = "${path.module}/.external_modules/structCICDTest/gcp-function-test/function"
  type        = "zip"
}

resource "google_storage_bucket_object" "function-source" {
  source       = data.archive_file.function-source.output_path
  name         = "functions/function-${data.archive_file.function-source.output_md5}.zip"
  bucket       = google_storage_bucket.deft-landing-343414-fn-code.name
  content_type = "application/zip"
}

resource "google_storage_bucket_object" "site" {
  for_each     = fileset("${path.module}/.external_modules/structCICDTest/gcp-function-test/site", "**")
  source       = "${path.module}/.external_modules/structCICDTest/gcp-function-test/site/${each.value}"
  name         = each.value
  bucket       = google_storage_bucket.deft-landing-343414-fn-data.name
  content_type = lookup({ "html" = "text/html; charset=utf-8", "js" = "text/javascript", "css" = "text/css" }, lower(regex("[^.]*$", each.value)), "application/octet-stream")
  depends_on   = [google_project_service.storage]
}




### CATEGORY: COMPUTE ###

resource "google_cloudfunctions2_function" "function" {
  name     = "function"
  location = "us-central1"
  build_config {
    source {
      storage_source {
        bucket = google_storage_bucket.deft-landing-343414-fn-code.name
        object = google_storage_bucket_object.function-source.name
      }
    }
    entry_point = "handler"
    runtime     = "python312"
  }
  service_config {
    service_account_email = google_service_account.function_sa.email
    environment_variables = {
    NAME                          = "function"
    GOOGLE_STORAGE_BUCKET_NAME_0  = "deft-landing-343414-fn-data"
    GOOGLE_SERVICE_ACCOUNT_NAME_0 = "function_sa"
    DATA_BUCKET                   = "deft-landing-343414-fn-data"
  }
  }
  depends_on = [google_storage_bucket_iam_member.deft-landing-343414-fn-data-function_sa-storage-objectCreator, google_project_service.artifactregistry, google_project_service.cloudbuild, google_project_service.cloudfunctions, google_project_service.run]
}


