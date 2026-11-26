resource "google_storage_bucket" "deft-landing-343414-oci-lab" {
  name                        = "deft-landing-343414-oci-lab"
  default_event_based_hold    = false
  deletion_policy             = "DELETE"
  enable_object_retention     = false
  force_destroy               = true
  location                    = "US"
  public_access_prevention    = "enforced"
  requester_pays              = false
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  labels = {
    struct8_state   = "stateocigooglelabgcp"
    struct8_creator = "contato_struct"
  }
  depends_on = [google_project_service.storage]
}

resource "google_storage_bucket" "deft-landing-343414-oci-lab-control" {
  name                        = "deft-landing-343414-oci-lab-control"
  default_event_based_hold    = false
  deletion_policy             = "DELETE"
  enable_object_retention     = false
  force_destroy               = true
  location                    = "US"
  public_access_prevention    = "enforced"
  requester_pays              = false
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  labels = {
    struct8_state   = "stateocigooglelabgcp"
    struct8_creator = "contato_struct"
  }
  depends_on = [google_project_service.storage]
}

resource "google_storage_bucket_iam_member" "deft-landing-343414-oci-lab-oci-gcs-reader-storage-objectUser" {
  bucket = google_storage_bucket.deft-landing-343414-oci-lab.name
  member = google_service_account.oci-gcs-reader.member
  role   = "roles/storage.objectUser"
}
