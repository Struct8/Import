resource "aws_security_group" "kuma_uptime_kuma_pod_sg" {
  name        = "eks-kuma-kuma-uptime-kuma-pod-sg"
  vpc_id      = data.aws_eks_cluster.eks-kuma.vpc_config[0].vpc_id
  description = "Pods of workload uptime-kuma in namespace kuma (SecurityGroupPolicy)"
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    description = "Saida liberada (pod precisa de DNS/API/AWS)"
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "rule_cluster_to_kuma_uptime_kuma_pod_sg_tcp_3001" {
  security_group_id        = aws_security_group.kuma_uptime_kuma_pod_sg.id
  source_security_group_id = data.aws_eks_cluster.eks-kuma.vpc_config[0].cluster_security_group_id
  description              = "Inbound to uptime-kuma on declared container port (from inside the cluster)"
  from_port                = 3001
  protocol                 = "tcp"
  to_port                  = 3001
  type                     = "ingress"
}

resource "aws_security_group_rule" "rule_kuma_uptime_kuma_pod_sg_to_cluster_apiserver" {
  security_group_id        = data.aws_eks_cluster.eks-kuma.vpc_config[0].cluster_security_group_id
  source_security_group_id = aws_security_group.kuma_uptime_kuma_pod_sg.id
  description              = "Kubernetes API from uptime-kuma pods (required by security groups for pods)"
  from_port                = 443
  protocol                 = "tcp"
  to_port                  = 443
  type                     = "ingress"
}

resource "aws_security_group_rule" "rule_kuma_uptime_kuma_pod_sg_to_cluster_dns_tcp" {
  security_group_id        = data.aws_eks_cluster.eks-kuma.vpc_config[0].cluster_security_group_id
  source_security_group_id = aws_security_group.kuma_uptime_kuma_pod_sg.id
  description              = "DNS from uptime-kuma pods to CoreDNS (required by security groups for pods)"
  from_port                = 53
  protocol                 = "tcp"
  to_port                  = 53
  type                     = "ingress"
}

resource "aws_security_group_rule" "rule_kuma_uptime_kuma_pod_sg_to_cluster_dns_udp" {
  security_group_id        = data.aws_eks_cluster.eks-kuma.vpc_config[0].cluster_security_group_id
  source_security_group_id = aws_security_group.kuma_uptime_kuma_pod_sg.id
  description              = "DNS from uptime-kuma pods to CoreDNS (required by security groups for pods)"
  from_port                = 53
  protocol                 = "udp"
  to_port                  = 53
  type                     = "ingress"
}

resource "aws_security_group_rule" "rule_kuma_uptime_kuma_pod_sg_to_db_instance_kuma_db_group_tcp_3306" {
  security_group_id        = data.aws_security_group.db_instance_kuma-db_group.id
  source_security_group_id = aws_security_group.kuma_uptime_kuma_pod_sg.id
  description              = "Allow from kuma_uptime_kuma_pod_sg (tcp:3306-3306)"
  from_port                = 3306
  protocol                 = "tcp"
  to_port                  = 3306
  type                     = "ingress"
}
