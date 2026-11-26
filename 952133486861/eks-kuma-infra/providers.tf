# --- Main Cloud Provider ---
provider "aws" {
  region = "us-east-1"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# --- Extra Providers ---
provider "helm" {
  kubernetes {
    cluster_ca_certificate = base64decode(aws_eks_cluster.eks-kuma.certificate_authority[0].data)
    host                   = aws_eks_cluster.eks-kuma.endpoint
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.eks-kuma.name]
      command     = "aws"
    }
  }
}
provider "kubernetes" {
  cluster_ca_certificate = base64decode(aws_eks_cluster.eks-kuma.certificate_authority[0].data)
  host                   = aws_eks_cluster.eks-kuma.endpoint
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.eks-kuma.name]
    command     = "aws"
  }
}
provider "kubectl" {
  cluster_ca_certificate = base64decode(aws_eks_cluster.eks-kuma.certificate_authority[0].data)
  host                   = aws_eks_cluster.eks-kuma.endpoint
  load_config_file       = false
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.eks-kuma.name]
    command     = "aws"
  }
}
