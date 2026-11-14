# --- Main Cloud Provider ---
provider "aws" {
  region = "us-west-2"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# --- Extra Providers ---
provider "google" {
  project = "deft-landing-343414"
}
