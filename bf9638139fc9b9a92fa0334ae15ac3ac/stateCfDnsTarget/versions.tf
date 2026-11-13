terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket  = "struct8-import"
    key     = "bf9638139fc9b9a92fa0334ae15ac3ac/stateCfDnsTarget/main.tfstate"
    region  = "us-west-2"
    encrypt = true
  }
}
