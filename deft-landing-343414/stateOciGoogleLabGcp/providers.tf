# --- Main Cloud Provider ---
provider "google" {
  project = "deft-landing-343414"
}

# --- Extra Providers ---
provider "oci" {
  region = "sa-saopaulo-1"
}
