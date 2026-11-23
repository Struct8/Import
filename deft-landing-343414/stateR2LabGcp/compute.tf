resource "google_cloudfunctions2_function" "r2-lab-gcp-fn" {
  name     = "r2-lab-gcp-fn"
  location = "us-central1"
  build_config {
    source {
      storage_source {
        bucket = google_storage_bucket.deft-landing-343414-r2-lab-code.name
        object = google_storage_bucket_object.r2-lab-gcp-fn-source.name
      }
    }
    entry_point = "handler"
    runtime     = "python312"
  }
  labels = {
    struct8_state   = "stater2labgcp"
    struct8_creator = "contato_struct"
  }
  service_config {
    available_memory      = "256M"
    service_account_email = google_service_account.r2-lab-gcp-fn_sa.email
    timeout_seconds       = 180
    environment_variables = {
      NAME                        = "r2-lab-gcp-fn"
      R2_ENDPOINT                 = "https://bf9638139fc9b9a92fa0334ae15ac3ac.r2.cloudflarestorage.com"
      CROSS_CLOUD_GATEWAY_URL     = "https://r2labg-gateway.rbpmconsulting.workers.dev"
      OIDC_AUDIENCE               = "https://r2labg-gateway.rbpmconsulting.workers.dev"
      CLOUDFLARE_R2_BUCKET_NAME_0 = "r2-lab-phase4"
      LAB_TIMEOUT_SECONDS         = "170"
    }
  }
  depends_on = [google_project_service.artifactregistry, google_project_service.cloudbuild, google_project_service.cloudfunctions, google_project_service.run]
}

resource "google_cloudfunctions2_function" "r2-lab-gcp-intruder" {
  name     = "r2-lab-gcp-intruder"
  location = "us-central1"
  build_config {
    source {
      storage_source {
        bucket = google_storage_bucket.deft-landing-343414-r2-lab-code.name
        object = google_storage_bucket_object.r2-lab-gcp-intruder-source.name
      }
    }
    entry_point = "handler"
    runtime     = "python312"
  }
  labels = {
    struct8_state   = "stater2labgcp"
    struct8_creator = "contato_struct"
  }
  service_config {
    available_memory      = "256M"
    service_account_email = google_service_account.r2-lab-gcp-intruder_sa.email
    timeout_seconds       = 60
    environment_variables = {
      NAME = "r2-lab-gcp-intruder"
    }
  }
  depends_on = [google_project_service.artifactregistry, google_project_service.cloudbuild, google_project_service.cloudfunctions, google_project_service.run]
}
