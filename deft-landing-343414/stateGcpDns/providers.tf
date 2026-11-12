# --- Main Cloud Provider ---
provider "google" {
  project = "deft-landing-343414"
}

# --- Extra Providers ---
provider "aws" {
  region = "us-east-1"
}
