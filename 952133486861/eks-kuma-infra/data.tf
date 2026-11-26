data "http" "lbc_iam_policy_kuma-alb" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json"
}

data "tls_certificate" "eks_tls_eks-kuma" {
  url = aws_eks_cluster.eks-kuma.identity[0].oidc[0].issuer
}
