terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  backend "s3" {
    bucket  = "struct8-import"
    key     = "952133486861/codebuild-lab-connection/main.tfstate"
    region  = "us-west-2"
    encrypt = true
  }
}

# --- Main Cloud Provider ---
provider "aws" {
  region = "us-west-2"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

### CATEGORY: DEVTOOLS ###

resource "aws_codeconnections_connection" "codebuild-lab-github" {
  name          = "codebuild-lab-github"
  provider_type = "GitHub"
  tags = {
    Name           = "codebuild-lab-github"
    State          = "codebuild-lab-connection"
    Struct8Creator = "Contato Struct"
  }
}


