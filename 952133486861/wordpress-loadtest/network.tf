resource "aws_subnet" "pubLoadTest" {
  vpc_id                  = data.aws_vpc.wordpress-professional.id
  availability_zone       = "us-west-2a"
  cidr_block              = "10.0.3.0/24"
  ipv6_cidr_block         = cidrsubnet(data.aws_vpc.wordpress-professional.ipv6_cidr_block, 8, 3)
  map_public_ip_on_launch = true
  tags = {
    Name           = "pubLoadTest"
    State          = "wordpress-loadtest"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route_table_association" "aws_route_table_association_pubLoadTest_rt_public_wp" {
  route_table_id = data.aws_route_table.rt-public-wp.id
  subnet_id      = aws_subnet.pubLoadTest.id
}

resource "aws_security_group" "instance_k6Generator_group" {
  name                   = "instance_k6Generator_group"
  vpc_id                 = data.aws_vpc.wordpress-professional.id
  revoke_rules_on_delete = false
  tags = {
    Name           = "instance_k6Generator_group"
    State          = "wordpress-loadtest"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group_rule" "rule_instance_k6Generator_group_egress_all_protocols" {
  security_group_id = aws_security_group.instance_k6Generator_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "rule_instance_k6Generator_group_ingress_tcp_5665" {
  security_group_id = aws_security_group.instance_k6Generator_group.id
  cidr_blocks       = ["45.166.205.55/32"]
  description       = "k6 web dashboard"
  from_port         = 5665
  protocol          = "tcp"
  to_port           = 5665
  type              = "ingress"
}

resource "aws_security_group_rule" "rule_instance_k6Generator_group_ingress_tcp_80" {
  security_group_id = aws_security_group.instance_k6Generator_group.id
  cidr_blocks       = ["45.166.205.55/32"]
  description       = "k6 panel"
  from_port         = 80
  protocol          = "tcp"
  to_port           = 80
  type              = "ingress"
}

resource "aws_eip" "eip-generator" {
  instance = aws_instance.k6Generator.id
  tags = {
    Name           = "eip-generator"
    State          = "wordpress-loadtest"
    Struct8Creator = "Contato Struct"
  }
}
