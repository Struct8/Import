resource "helm_release" "aws_lbc_kuma-alb" {
  name       = "aws-lbc-kuma-alb"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  repository = "https://aws.github.io/eks-charts"
  set {
    name  = "clusterName"
    value = aws_eks_cluster.eks-kuma.name
  }
  set {
    name  = "serviceAccount.create"
    value = true
  }
  set {
    name  = "serviceAccount.name"
    value = "aws-lbc-kuma-alb"
  }
  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.role_lbc_kuma-alb.arn
  }
  set {
    name  = "region"
    value = data.aws_region.current.region
  }
  set {
    name  = "vpcId"
    value = aws_vpc.eks-kuma-vpc.id
  }
  depends_on = [aws_iam_role_policy_attachment.role_lbc_kuma-alb_attach, aws_eks_node_group.eks-kuma-nodes]
}
