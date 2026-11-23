# --- Main Cloud Provider ---
provider "cloudflare" {}

# --- Extra Providers ---
provider "aws" {
  alias   = "acct_952133486861"
  profile = "acct_952133486861"
  region  = "us-east-1"
}

# --- Input Variables ---
variable "r2_access_key_id" {
  type        = string
  sensitive   = true
  description = "Access Key ID of the R2 API token the engine mints for this run"
}
variable "r2_secret_access_key" {
  type        = string
  sensitive   = true
  description = "Secret Access Key of the R2 API token the engine mints for this run"
}

locals {
  r2_force_destroy_credential = var.r2_access_key_id
}
