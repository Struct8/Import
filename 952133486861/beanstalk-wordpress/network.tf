resource "aws_vpc" "vpc-beanstalk-wordpress" {
  cidr_block           = "10.41.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default"
  tags = {
    Name           = "vpc-beanstalk-wordpress"
    State          = "beanstalk-wordpress"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "wp-app-a" {
  vpc_id                  = aws_vpc.vpc-beanstalk-wordpress.id
  availability_zone       = "us-west-2a"
  cidr_block              = "10.41.10.0/24"
  map_public_ip_on_launch = false
  tags = {
    Name           = "wp-app-a"
    State          = "beanstalk-wordpress"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "wp-app-b" {
  vpc_id                  = aws_vpc.vpc-beanstalk-wordpress.id
  availability_zone       = "us-west-2b"
  cidr_block              = "10.41.11.0/24"
  map_public_ip_on_launch = false
  tags = {
    Name           = "wp-app-b"
    State          = "beanstalk-wordpress"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "wp-data-a" {
  vpc_id                  = aws_vpc.vpc-beanstalk-wordpress.id
  availability_zone       = "us-west-2a"
  cidr_block              = "10.41.20.0/24"
  map_public_ip_on_launch = false
  tags = {
    Name           = "wp-data-a"
    State          = "beanstalk-wordpress"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "wp-data-b" {
  vpc_id                  = aws_vpc.vpc-beanstalk-wordpress.id
  availability_zone       = "us-west-2b"
  cidr_block              = "10.41.21.0/24"
  map_public_ip_on_launch = false
  tags = {
    Name           = "wp-data-b"
    State          = "beanstalk-wordpress"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "wp-public-a" {
  vpc_id                  = aws_vpc.vpc-beanstalk-wordpress.id
  availability_zone       = "us-west-2a"
  cidr_block              = "10.41.0.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name           = "wp-public-a"
    State          = "beanstalk-wordpress"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "wp-public-b" {
  vpc_id                  = aws_vpc.vpc-beanstalk-wordpress.id
  availability_zone       = "us-west-2b"
  cidr_block              = "10.41.1.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name           = "wp-public-b"
    State          = "beanstalk-wordpress"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_internet_gateway" "igw-beanstalk-wordpress" {
  vpc_id = aws_vpc.vpc-beanstalk-wordpress.id
  tags = {
    Name           = "igw-beanstalk-wordpress"
    State          = "beanstalk-wordpress"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_nat_gateway" "nat-beanstalk-wordpress" {
  vpc_id            = aws_vpc.vpc-beanstalk-wordpress.id
  availability_mode = "regional"
  connectivity_type = "public"
  tags = {
    Name           = "nat-beanstalk-wordpress"
    State          = "beanstalk-wordpress"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_internet_gateway.igw-beanstalk-wordpress]
}

resource "aws_route" "route_rt-private-wp_to_nat-beanstalk-wordpress_ipv4" {
  nat_gateway_id         = aws_nat_gateway.nat-beanstalk-wordpress.id
  route_table_id         = aws_route_table.rt-private-wp.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route" "route_rt-public-wp1_to_igw-beanstalk-wordpress_ipv4" {
  gateway_id             = aws_internet_gateway.igw-beanstalk-wordpress.id
  route_table_id         = aws_route_table.rt-public-wp1.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table" "rt-private-wp" {
  vpc_id = aws_vpc.vpc-beanstalk-wordpress.id
  tags = {
    Name           = "rt-private-wp"
    State          = "beanstalk-wordpress"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route_table" "rt-public-wp1" {
  vpc_id = aws_vpc.vpc-beanstalk-wordpress.id
  tags = {
    Name           = "rt-public-wp1"
    State          = "beanstalk-wordpress"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route_table_association" "aws_route_table_association_wp_app_a_rt_private_wp" {
  route_table_id = aws_route_table.rt-private-wp.id
  subnet_id      = aws_subnet.wp-app-a.id
}

resource "aws_route_table_association" "aws_route_table_association_wp_app_b_rt_private_wp" {
  route_table_id = aws_route_table.rt-private-wp.id
  subnet_id      = aws_subnet.wp-app-b.id
}

resource "aws_route_table_association" "aws_route_table_association_wp_public_a_rt_public_wp1" {
  route_table_id = aws_route_table.rt-public-wp1.id
  subnet_id      = aws_subnet.wp-public-a.id
}

resource "aws_route_table_association" "aws_route_table_association_wp_public_b_rt_public_wp1" {
  route_table_id = aws_route_table.rt-public-wp1.id
  subnet_id      = aws_subnet.wp-public-b.id
}

resource "aws_security_group" "db_instance_wp-eb-db_group" {
  name                   = "db_instance_wp-eb-db_group"
  vpc_id                 = aws_vpc.vpc-beanstalk-wordpress.id
  revoke_rules_on_delete = false
  tags = {
    Name           = "db_instance_wp-eb-db_group"
    State          = "beanstalk-wordpress"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group" "efs_file_system_wp-eb-files_group" {
  name                   = "efs_file_system_wp-eb-files_group"
  vpc_id                 = aws_vpc.vpc-beanstalk-wordpress.id
  revoke_rules_on_delete = false
  tags = {
    Name           = "efs_file_system_wp-eb-files_group"
    State          = "beanstalk-wordpress"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group" "elastic_beanstalk_environment_beanstalk-uptime-kuma_group" {
  name                   = "elastic_beanstalk_environment_beanstalk-uptime-kuma_group"
  vpc_id                 = aws_vpc.vpc-beanstalk-wordpress.id
  revoke_rules_on_delete = false
  tags = {
    Name           = "elastic_beanstalk_environment_beanstalk-uptime-kuma_group"
    State          = "beanstalk-wordpress"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group" "elastic_beanstalk_environment_beanstalk-wordpress-web_group" {
  name                   = "elastic_beanstalk_environment_beanstalk-wordpress-web_group"
  vpc_id                 = aws_vpc.vpc-beanstalk-wordpress.id
  revoke_rules_on_delete = false
  tags = {
    Name           = "elastic_beanstalk_environment_beanstalk-wordpress-web_group"
    State          = "beanstalk-wordpress"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group" "lb_wp-shared-alb_group" {
  name                   = "lb_wp-shared-alb_group"
  vpc_id                 = aws_vpc.vpc-beanstalk-wordpress.id
  description            = "Shared ALB of the WordPress sites"
  revoke_rules_on_delete = false
}

resource "aws_security_group_rule" "rule_db_instance_wp_eb_db_group_egress_all_protocols" {
  security_group_id = aws_security_group.db_instance_wp-eb-db_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "rule_efs_file_system_wp_eb_files_group_egress_all_protocols" {
  security_group_id = aws_security_group.efs_file_system_wp-eb-files_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "rule_elastic_beanstalk_environment_beanstalk_uptime_kuma_group_egress_all_protocols" {
  security_group_id = aws_security_group.elastic_beanstalk_environment_beanstalk-uptime-kuma_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "rule_elastic_beanstalk_environment_beanstalk_uptime_kuma_group_to_db_instance_wp_eb_db_group_tcp_3306" {
  security_group_id        = aws_security_group.db_instance_wp-eb-db_group.id
  source_security_group_id = aws_security_group.elastic_beanstalk_environment_beanstalk-uptime-kuma_group.id
  description              = "Allow from elastic_beanstalk_environment_beanstalk-uptime-kuma_group (tcp:3306-3306)"
  from_port                = 3306
  protocol                 = "tcp"
  to_port                  = 3306
  type                     = "ingress"
}

resource "aws_security_group_rule" "rule_elastic_beanstalk_environment_beanstalk_uptime_kuma_group_to_efs_file_system_wp_eb_files_group_tcp_2049" {
  security_group_id        = aws_security_group.efs_file_system_wp-eb-files_group.id
  source_security_group_id = aws_security_group.elastic_beanstalk_environment_beanstalk-uptime-kuma_group.id
  description              = "Allow from elastic_beanstalk_environment_beanstalk-uptime-kuma_group (tcp:2049-2049)"
  from_port                = 2049
  protocol                 = "tcp"
  to_port                  = 2049
  type                     = "ingress"
}

resource "aws_security_group_rule" "rule_elastic_beanstalk_environment_beanstalk_wordpress_web_group_egress_all_protocols" {
  security_group_id = aws_security_group.elastic_beanstalk_environment_beanstalk-wordpress-web_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "rule_elastic_beanstalk_environment_beanstalk_wordpress_web_group_to_db_instance_wp_eb_db_group_tcp_3306" {
  security_group_id        = aws_security_group.db_instance_wp-eb-db_group.id
  source_security_group_id = aws_security_group.elastic_beanstalk_environment_beanstalk-wordpress-web_group.id
  description              = "Allow from elastic_beanstalk_environment_beanstalk-wordpress-web_group (tcp:3306-3306)"
  from_port                = 3306
  protocol                 = "tcp"
  to_port                  = 3306
  type                     = "ingress"
}

resource "aws_security_group_rule" "rule_elastic_beanstalk_environment_beanstalk_wordpress_web_group_to_efs_file_system_wp_eb_files_group_tcp_2049" {
  security_group_id        = aws_security_group.efs_file_system_wp-eb-files_group.id
  source_security_group_id = aws_security_group.elastic_beanstalk_environment_beanstalk-wordpress-web_group.id
  description              = "Allow from elastic_beanstalk_environment_beanstalk-wordpress-web_group (tcp:2049-2049)"
  from_port                = 2049
  protocol                 = "tcp"
  to_port                  = 2049
  type                     = "ingress"
}

resource "aws_security_group_rule" "rule_lb_wp_shared_alb_group_egress_all_protocols" {
  security_group_id = aws_security_group.lb_wp-shared-alb_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "rule_lb_wp_shared_alb_group_ingress_tcp_80" {
  security_group_id = aws_security_group.lb_wp-shared-alb_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "HTTP from the internet"
  from_port         = 80
  protocol          = "tcp"
  to_port           = 80
  type              = "ingress"
}

resource "aws_lb" "wp-shared-alb" {
  name               = "wp-shared-alb"
  idle_timeout       = 60
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_wp-shared-alb_group.id]
  subnets            = [aws_subnet.wp-public-a.id, aws_subnet.wp-public-b.id]
  tags = {
    Name           = "wp-shared-alb"
    State          = "beanstalk-wordpress"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_lb_listener" "wp-shared-http" {
  load_balancer_arn                    = aws_lb.wp-shared-alb.arn
  port                                 = 80
  protocol                             = "HTTP"
  routing_http_response_server_enabled = true
  default_action {
    order = 1
    type  = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "No site answers at this address."
      status_code  = "404"
    }
  }
  tags = {
    Name           = "wp-shared-http"
    State          = "beanstalk-wordpress"
    Struct8Creator = "Contato Struct"
  }
}
