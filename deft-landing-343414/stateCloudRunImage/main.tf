terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }
  }

  backend "s3" {
    bucket  = "struct8-import"
    key     = "deft-landing-343414/stateCloudRunImage/main.tfstate"
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

resource "google_project_service" "iam" {
  disable_on_destroy = false
  service            = "iam.googleapis.com"
}

resource "google_project_service" "run" {
  disable_on_destroy = false
  service            = "run.googleapis.com"
}




### CATEGORY: IAM ###

resource "google_service_account" "run-image-sa" {
  account_id                   = "run-image-sa"
  create_ignore_already_exists = false
  deletion_policy              = "DELETE"
  disabled                     = false
  depends_on                   = [google_project_service.iam]
}




### CATEGORY: STORAGE ###

resource "google_artifact_registry_repository" "run-images" {
  repository_id          = "run-images"
  cleanup_policy_dry_run = true
  deletion_policy        = "DELETE"
  format                 = "DOCKER"
  location               = "us-central1"
  mode                   = "STANDARD_REPOSITORY"
  depends_on             = [google_project_service.artifactregistry]
}

resource "google_artifact_registry_repository_iam_member" "run-images-run-image-sa-artifactregistry-reader" {
  location   = google_artifact_registry_repository.run-images.location
  member     = google_service_account.run-image-sa.member
  repository = google_artifact_registry_repository.run-images.repository_id
  role       = "roles/artifactregistry.reader"
}




### CATEGORY: COMPUTE ###

resource "google_cloud_run_v2_service" "hello-image" {
  name                 = "hello-image"
  default_uri_disabled = false
  deletion_protection  = false
  ingress              = "INGRESS_TRAFFIC_ALL"
  invoker_iam_disabled = false
  location             = "us-central1"
  template {
    execution_environment            = "EXECUTION_ENVIRONMENT_GEN2"
    gpu_zonal_redundancy_disabled    = false
    health_check_disabled            = false
    max_instance_request_concurrency = 80
    service_account                  = google_service_account.run-image-sa.email
    session_affinity                 = false
    timeout                          = "300s"
    containers {
      resources {
        cpu_idle = true
        limits = {
    cpu    = "1"
    memory = "512Mi"
  }
      }
      image = "${google_artifact_registry_repository.run-images.registry_uri}/${google_artifact_registry_repository.run-images.repository_id}:${terraform_data.seed_run-images.output}"
      ports {
        container_port = 8080
      }
    }
    scaling {
      max_instance_count = 100
      min_instance_count = 0
    }
  }
  depends_on = [terraform_data.seed_run-images, google_artifact_registry_repository_iam_member.run-images-run-image-sa-artifactregistry-reader, google_project_service.run]
}

resource "google_cloud_run_v2_service_iam_member" "hello-image-public" {
  name       = google_cloud_run_v2_service.hello-image.name
  location   = google_cloud_run_v2_service.hello-image.location
  member     = "allUsers"
  role       = "roles/run.invoker"
  depends_on = [google_project_service.run]
}




### CATEGORY: MISC ###

resource "terraform_data" "seed_run-images" {
  input            = substr(sha1(jsonencode({ for f in fileset(join("/", [path.module, ".external_modules/struct8-templates/templates/cloud-run-hello/v1/image"]), "**") : f => filesha1(join("/", [path.module, ".external_modules/struct8-templates/templates/cloud-run-hello/v1/image", f])) })), 0, 12)
  triggers_replace = ["${path.module}/.external_modules/struct8-templates/templates/cloud-run-hello/v1/image", substr(sha1(jsonencode({ for f in fileset(join("/", [path.module, ".external_modules/struct8-templates/templates/cloud-run-hello/v1/image"]), "**") : f => filesha1(join("/", [path.module, ".external_modules/struct8-templates/templates/cloud-run-hello/v1/image", f])) })), 0, 12)]
  lifecycle {
    replace_triggered_by = [google_artifact_registry_repository.run-images]
  }
  depends_on = [google_artifact_registry_repository.run-images]
  provisioner "local-exec" {
    command = <<EOF
set -e
command -v docker > /dev/null 2>&1 || { echo "Docker is not installed on the machine that runs the apply, and the image of run-images is built there." >&2; exit 1; }
command -v gcloud > /dev/null 2>&1 || { echo "gcloud is not installed on the machine that runs the apply, and it signs Docker in to run-images." >&2; exit 1; }
if [ -n "$GOOGLE_APPLICATION_CREDENTIALS" ]; then
  CLOUDSDK_CONFIG="$(mktemp -d)"
  export CLOUDSDK_CONFIG
  trap 'rm -rf "$CLOUDSDK_CONFIG"' EXIT
  gcloud auth login --cred-file="$GOOGLE_APPLICATION_CREDENTIALS" --quiet
fi
gcloud auth print-access-token | docker login --username oauth2accesstoken --password-stdin https://${split("/", google_artifact_registry_repository.run-images.registry_uri)[0]}
docker build --provenance=false --platform linux/amd64 -t ${google_artifact_registry_repository.run-images.registry_uri}/${google_artifact_registry_repository.run-images.repository_id}:${self.input} ${path.module}/.external_modules/struct8-templates/templates/cloud-run-hello/v1/image
docker push ${google_artifact_registry_repository.run-images.registry_uri}/${google_artifact_registry_repository.run-images.repository_id}:${self.input}
  EOF
    interpreter = ["/bin/bash", "-c"]
  }
}


