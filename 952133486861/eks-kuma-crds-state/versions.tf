terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    tls = {
      source = "hashicorp/tls"
    }
  }

  backend "s3" {
    bucket  = "struct8-import"
    key     = "952133486861/eks-kuma-crds-state/main.tfstate"
    region  = "us-west-2"
    encrypt = true
  }
}
