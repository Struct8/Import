# --- Main Cloud Provider ---
provider "google" {
  project = "deft-landing-343414"
}

# --- Extra Providers ---
provider "aws" {
  alias   = "acct_952133486861"
  profile = "acct_952133486861"
  region  = "us-west-2"
}
