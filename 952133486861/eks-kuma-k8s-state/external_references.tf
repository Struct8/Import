data "aws_eks_cluster" "eks-kuma" {
  name = "eks-kuma"
}

data "aws_lb_target_group" "tg-kuma" {
  name = "tg-kuma"
}

data "aws_security_group" "db_instance_kuma-db_group" {
  name = "db_instance_kuma-db_group"
}
