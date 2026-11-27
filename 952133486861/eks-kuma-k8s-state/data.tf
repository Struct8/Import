data "tls_certificate" "eks_tls_eks-kuma" {
  url = data.aws_eks_cluster.eks-kuma.identity[0].oidc[0].issuer
}
