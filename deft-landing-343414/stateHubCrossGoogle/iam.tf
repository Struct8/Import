resource "google_iam_workload_identity_pool" "cross-link" {
  display_name              = "cross-link"
  workload_identity_pool_id = "cross-link"
  description               = "AWS role cross-caller_role of account 952133486861, used by cross-caller. Written by the component cross-link."
  depends_on                = [google_project_service.iam, google_project_service.iamcredentials, google_project_service.sts]
}

resource "google_iam_workload_identity_pool_provider" "cross-link" {
  display_name                       = "AWS 952133486861"
  workload_identity_pool_id          = google_iam_workload_identity_pool.cross-link.workload_identity_pool_id
  workload_identity_pool_provider_id = "aws-workload"
  attribute_condition                = "attribute.aws_role == 'cross-caller_role'"
  attribute_mapping = {
    "google.subject"        = "assertion.arn"
    "attribute.aws_account" = "assertion.account"
    "attribute.aws_role"    = "assertion.arn.extract('assumed-role/{role_name}/')"
  }
  aws {
    account_id = "952133486861"
  }
}

resource "google_project_iam_member" "marisa-demo1-cross-gateway_sa-telemetry-tracesWriter" {
  member  = google_service_account.cross-gateway_sa.member
  project = "deft-landing-343414"
  role    = "roles/telemetry.tracesWriter"
}

resource "google_project_iam_member" "marisa-demo1-cross-listener_sa-telemetry-tracesWriter" {
  member  = google_service_account.cross-listener_sa.member
  project = "deft-landing-343414"
  role    = "roles/telemetry.tracesWriter"
}

resource "google_project_iam_member" "marisa-demo1-cross-worker_sa-telemetry-tracesWriter" {
  member  = google_service_account.cross-worker_sa.member
  project = "deft-landing-343414"
  role    = "roles/telemetry.tracesWriter"
}

resource "google_service_account" "cross-gateway_sa" {
  account_id                   = "cross-gateway-sa"
  create_ignore_already_exists = false
  deletion_policy              = "DELETE"
  disabled                     = false
  depends_on                   = [google_project_service.iam]
}

resource "google_service_account" "cross-link" {
  account_id   = "cross-link"
  display_name = "Cross-cloud cross-link"
  description  = "Acted as by the AWS role cross-caller_role of cross-caller. Written by the component cross-link."
  depends_on   = [google_project_service.iam]
}

resource "google_service_account" "cross-listener_sa" {
  account_id                   = "cross-listener-sa"
  create_ignore_already_exists = false
  deletion_policy              = "DELETE"
  disabled                     = false
  depends_on                   = [google_project_service.iam]
}

resource "google_service_account" "cross-worker_sa" {
  account_id                   = "cross-worker-sa"
  create_ignore_already_exists = false
  deletion_policy              = "DELETE"
  disabled                     = false
  depends_on                   = [google_project_service.iam]
}

resource "google_service_account_iam_member" "cross-link" {
  service_account_id = google_service_account.cross-link.name
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.cross-link.name}/attribute.aws_role/cross-caller_role"
  role               = "roles/iam.workloadIdentityUser"
}

resource "google_secret_manager_secret" "cross-secret" {
  secret_id           = "cross-secret"
  deletion_policy     = "DELETE"
  deletion_protection = false
  replication {
    user_managed {
      replicas {
        location = "us-central1"
      }
    }
  }
  depends_on = [google_project_service.secretmanager]
}

resource "google_secret_manager_secret_iam_member" "cross-secret-cross-link-secretmanager-secretVersionAdder" {
  secret_id = google_secret_manager_secret.cross-secret.secret_id
  member    = google_service_account.cross-link.member
  role      = "roles/secretmanager.secretVersionAdder"
}
