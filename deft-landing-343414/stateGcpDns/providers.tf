# --- Main Cloud Provider ---
provider "google" {
  project = "deft-landing-343414"
}

# --- Extra Providers ---
provider "aws" {
  profile = "acct_952133486861"
  region  = "us-east-1"
}
