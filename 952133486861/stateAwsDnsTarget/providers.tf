# --- Main Cloud Provider ---
provider "aws" {
  region = "us-west-2"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# --- Extra Providers ---
provider "google" {
  alias       = "acct_deft_landing_343414"
  credentials = var.struct8_credentials_google_deft_landing_343414
  project     = "deft-landing-343414"
}

variable "struct8_credentials_google_deft_landing_343414" {
  type    = string
  default = null
}
