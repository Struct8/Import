data "aws_route53_zone" "Cloudman1" {
  name = "cloudman.pro"
}

data "http" "lbc_iam_policy_kuma-alb" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json"
}

data "tls_certificate" "eks_tls_eks-kuma" {
  url = aws_eks_cluster.eks-kuma.identity[0].oidc[0].issuer
}

data "helm_template" "calico_crds_eks-kuma" {
  version    = "v3.33.1"
  name       = "calico-crds"
  chart      = "crd.projectcalico.org.v1"
  namespace  = "tigera-operator"
  repository = "https://docs.tigera.io/calico/charts"
}
