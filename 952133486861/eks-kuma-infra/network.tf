resource "aws_vpc" "eks-kuma-vpc" {
  cidr_block           = "10.40.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default"
  tags = {
    Name           = "eks-kuma-vpc"
    State          = "eks-kuma-infra"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "eks-data-a" {
  vpc_id                  = aws_vpc.eks-kuma-vpc.id
  availability_zone       = "us-east-1a"
  cidr_block              = "10.40.21.0/24"
  map_public_ip_on_launch = false
  tags = {
    Name           = "eks-data-a"
    State          = "eks-kuma-infra"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "eks-data-b" {
  vpc_id                  = aws_vpc.eks-kuma-vpc.id
  availability_zone       = "us-east-1b"
  cidr_block              = "10.40.22.0/24"
  map_public_ip_on_launch = false
  tags = {
    Name           = "eks-data-b"
    State          = "eks-kuma-infra"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "eks-private-a" {
  vpc_id                  = aws_vpc.eks-kuma-vpc.id
  availability_zone       = "us-east-1a"
  cidr_block              = "10.40.11.0/24"
  map_public_ip_on_launch = false
  tags = {
    "kubernetes.io/cluster/eks-kuma"  = "shared"
    "kubernetes.io/role/internal-elb" = "1"
    Name                              = "eks-private-a"
    State                             = "eks-kuma-infra"
    Struct8Creator                    = "Contato Struct"
  }
}

resource "aws_subnet" "eks-private-b" {
  vpc_id                  = aws_vpc.eks-kuma-vpc.id
  availability_zone       = "us-east-1b"
  cidr_block              = "10.40.12.0/24"
  map_public_ip_on_launch = false
  tags = {
    "kubernetes.io/cluster/eks-kuma"  = "shared"
    "kubernetes.io/role/internal-elb" = "1"
    Name                              = "eks-private-b"
    State                             = "eks-kuma-infra"
    Struct8Creator                    = "Contato Struct"
  }
}

resource "aws_subnet" "eks-public-a" {
  vpc_id                  = aws_vpc.eks-kuma-vpc.id
  availability_zone       = "us-east-1a"
  cidr_block              = "10.40.1.0/24"
  map_public_ip_on_launch = true
  tags = {
    "kubernetes.io/cluster/eks-kuma" = "shared"
    "kubernetes.io/role/elb"         = "1"
    Name                             = "eks-public-a"
    State                            = "eks-kuma-infra"
    Struct8Creator                   = "Contato Struct"
  }
}

resource "aws_subnet" "eks-public-b" {
  vpc_id                  = aws_vpc.eks-kuma-vpc.id
  availability_zone       = "us-east-1b"
  cidr_block              = "10.40.2.0/24"
  map_public_ip_on_launch = true
  tags = {
    "kubernetes.io/cluster/eks-kuma" = "shared"
    "kubernetes.io/role/elb"         = "1"
    Name                             = "eks-public-b"
    State                            = "eks-kuma-infra"
    Struct8Creator                   = "Contato Struct"
  }
}

resource "aws_internet_gateway" "igw-eks-kuma" {
  vpc_id = aws_vpc.eks-kuma-vpc.id
  tags = {
    Name           = "igw-eks-kuma"
    State          = "eks-kuma-infra"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_nat_gateway" "nat-eks-kuma" {
  vpc_id            = aws_vpc.eks-kuma-vpc.id
  availability_mode = "regional"
  connectivity_type = "public"
  tags = {
    Name           = "nat-eks-kuma"
    State          = "eks-kuma-infra"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_internet_gateway.igw-eks-kuma]
}

resource "aws_route" "route_rt-eks-private_to_nat-eks-kuma_ipv4" {
  nat_gateway_id         = aws_nat_gateway.nat-eks-kuma.id
  route_table_id         = aws_route_table.rt-eks-private.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route" "route_rt-eks-public_to_igw-eks-kuma_ipv4" {
  gateway_id             = aws_internet_gateway.igw-eks-kuma.id
  route_table_id         = aws_route_table.rt-eks-public.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table" "rt-eks-private" {
  vpc_id = aws_vpc.eks-kuma-vpc.id
  tags = {
    Name           = "rt-eks-private"
    State          = "eks-kuma-infra"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route_table" "rt-eks-public" {
  vpc_id = aws_vpc.eks-kuma-vpc.id
  tags = {
    Name           = "rt-eks-public"
    State          = "eks-kuma-infra"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route_table_association" "aws_route_table_association_eks_data_a_rt_eks_private" {
  route_table_id = aws_route_table.rt-eks-private.id
  subnet_id      = aws_subnet.eks-data-a.id
}

resource "aws_route_table_association" "aws_route_table_association_eks_data_b_rt_eks_private" {
  route_table_id = aws_route_table.rt-eks-private.id
  subnet_id      = aws_subnet.eks-data-b.id
}

resource "aws_route_table_association" "aws_route_table_association_eks_private_a_rt_eks_private" {
  route_table_id = aws_route_table.rt-eks-private.id
  subnet_id      = aws_subnet.eks-private-a.id
}

resource "aws_route_table_association" "aws_route_table_association_eks_private_b_rt_eks_private" {
  route_table_id = aws_route_table.rt-eks-private.id
  subnet_id      = aws_subnet.eks-private-b.id
}

resource "aws_route_table_association" "aws_route_table_association_eks_public_a_rt_eks_public" {
  route_table_id = aws_route_table.rt-eks-public.id
  subnet_id      = aws_subnet.eks-public-a.id
}

resource "aws_route_table_association" "aws_route_table_association_eks_public_b_rt_eks_public" {
  route_table_id = aws_route_table.rt-eks-public.id
  subnet_id      = aws_subnet.eks-public-b.id
}

resource "aws_security_group" "db_instance_kuma-db_group" {
  name                   = "db_instance_kuma-db_group"
  vpc_id                 = aws_vpc.eks-kuma-vpc.id
  revoke_rules_on_delete = false
  tags = {
    Name           = "db_instance_kuma-db_group"
    State          = "eks-kuma-infra"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group" "lb_kuma-alb_group" {
  name                   = "lb_kuma-alb_group"
  vpc_id                 = aws_vpc.eks-kuma-vpc.id
  revoke_rules_on_delete = false
  tags = {
    Name           = "lb_kuma-alb_group"
    State          = "eks-kuma-infra"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group_rule" "rule_db_instance_kuma_db_group_egress_all_protocols" {
  security_group_id = aws_security_group.db_instance_kuma-db_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "rule_lb_kuma_alb_group_egress_all_protocols" {
  security_group_id = aws_security_group.lb_kuma-alb_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "rule_lb_kuma_alb_group_to_db_instance_kuma_db_group_tcp_8000" {
  security_group_id        = aws_security_group.db_instance_kuma-db_group.id
  source_security_group_id = aws_security_group.lb_kuma-alb_group.id
  description              = "Allow from lb_kuma-alb_group (tcp:8000-8000)"
  from_port                = 8000
  protocol                 = "tcp"
  to_port                  = 8000
  type                     = "ingress"
}

resource "aws_lb" "kuma-alb" {
  name               = "kuma-alb"
  idle_timeout       = 60
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_kuma-alb_group.id]
  subnets            = [aws_subnet.eks-public-a.id, aws_subnet.eks-public-b.id]
  tags = {
    Name           = "kuma-alb"
    State          = "eks-kuma-infra"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_lb_listener" "kuma-http" {
  load_balancer_arn                    = aws_lb.kuma-alb.arn
  port                                 = 80
  protocol                             = "HTTP"
  routing_http_response_server_enabled = true
  default_action {
    order            = 1
    target_group_arn = aws_lb_target_group.tg-kuma.arn
    type             = "forward"
    forward {
      target_group {
        arn = aws_lb_target_group.tg-kuma.arn
      }
    }
  }
  tags = {
    Name           = "kuma-http"
    State          = "eks-kuma-infra"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_lb_target_group" "tg-kuma" {
  name                          = "tg-kuma"
  vpc_id                        = aws_vpc.eks-kuma-vpc.id
  deregistration_delay          = "300"
  ip_address_type               = "ipv4"
  load_balancing_algorithm_type = "round_robin"
  port                          = 8000
  protocol                      = "HTTP"
  target_type                   = "ip"
  health_check {
    enabled  = true
    matcher  = "200-399"
    path     = "/"
    port     = "traffic-port"
    protocol = "HTTP"
  }
  tags = {
    Name           = "tg-kuma"
    State          = "eks-kuma-infra"
    Struct8Creator = "Contato Struct"
  }
}
