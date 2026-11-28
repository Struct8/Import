data "aws_eks_cluster" "eks-kuma" {
  name = "eks-kuma"
}

data "aws_lb_target_group" "tg-kuma" {
  name = "tg-kuma"
}
