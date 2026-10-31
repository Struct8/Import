terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }
  }

  backend "s3" {
    bucket  = "struct8-import"
    key     = "deft-landing-343414/stateDataflowDemo1/main.tfstate"
    region  = "us-west-2"
    encrypt = true
  }
}

# --- Main Cloud Provider ---
provider "google" {
  project = "deft-landing-343414"
}

### CATEGORY: FOUNDATION ###

resource "google_project_service" "compute" {
  disable_on_destroy = false
  service            = "compute.googleapis.com"
}

resource "google_project_service" "dataflow" {
  disable_on_destroy = false
  service            = "dataflow.googleapis.com"
}

resource "google_project_service" "iam" {
  disable_on_destroy = false
  service            = "iam.googleapis.com"
}

resource "google_project_service" "storage" {
  disable_on_destroy = false
  service            = "storage.googleapis.com"
}




### CATEGORY: IAM ###

resource "google_project_iam_member" "marisa-demo1-wordcount-teste_sa-dataflow-worker" {
  member  = google_service_account.wordcount-teste_sa.member
  project = "deft-landing-343414"
  role    = "roles/dataflow.worker"
}

resource "google_service_account" "wordcount-teste_sa" {
  account_id                   = "wordcount-teste-sa"
  create_ignore_already_exists = false
  deletion_policy              = "DELETE"
  disabled                     = false
  depends_on                   = [google_project_service.iam]
}




### CATEGORY: STORAGE ###

resource "google_storage_bucket" "struct8-dataflow-teste-7k3q" {
  name                        = "struct8-dataflow-teste-7k3q"
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

resource "google_storage_bucket_iam_member" "struct8-dataflow-teste-7k3q-wordcount-teste_sa-storage-objectAdmin" {
  bucket = google_storage_bucket.struct8-dataflow-teste-7k3q.name
  member = google_service_account.wordcount-teste_sa.member
  role   = "roles/storage.objectAdmin"
}




### CATEGORY: ANALYTICS ###

resource "google_dataflow_job" "wordcount-teste" {
  name                  = "wordcount-teste"
  machine_type          = "n1-standard-1"
  max_workers           = 1
  region                = "us-central1"
  service_account_email = google_service_account.wordcount-teste_sa.email
  temp_gcs_location     = "gs://${google_storage_bucket.struct8-dataflow-teste-7k3q.name}/temp"
  template_gcs_path     = "gs://dataflow-templates/latest/Word_Count"
  parameters = {
    inputFile = "gs://dataflow-samples/shakespeare/kinglear.txt"
    output    = "gs://struct8-dataflow-teste-7k3q/output/wc"
  }
  depends_on = [google_project_iam_member.marisa-demo1-wordcount-teste_sa-dataflow-worker, google_storage_bucket_iam_member.struct8-dataflow-teste-7k3q-wordcount-teste_sa-storage-objectAdmin, google_project_service.compute, google_project_service.dataflow]
}


