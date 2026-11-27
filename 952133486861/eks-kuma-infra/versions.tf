terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
    http = {
      source = "hashicorp/http"
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
    key     = "952133486861/eks-kuma-infra/main.tfstate"
    region  = "us-west-2"
    encrypt = true
  }
}
