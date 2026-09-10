terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  backend "s3" {
    bucket  = "struct8-import"
    key     = "952133486861/alb-web-servers/main.tfstate"
    region  = "us-west-2"
    encrypt = true
  }
}

# --- Main Cloud Provider ---
provider "aws" {
  region = "us-west-2"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

### CATEGORY: IAM ###

resource "aws_iam_instance_profile" "nat-instance_profile" {
  name = "nat-instance_profile"
  role = aws_iam_role.nat-instance_role.name
  tags = {
    Name           = "nat-instance_profile"
    State          = "alb-web-servers"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_instance_profile" "web-server-asg_profile" {
  name = "web-server-asg_profile"
  role = aws_iam_role.web-server-asg_role.name
  tags = {
    Name           = "web-server-asg_profile"
    State          = "alb-web-servers"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "nat-instance_role" {
  name = "nat-instance_role"
  assume_role_policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      }
    }
  ]
})
  force_detach_policies = false
  max_session_duration  = 3600
  path                  = "/"
  tags = {
    Name           = "nat-instance_role"
    State          = "alb-web-servers"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "web-server-asg_role" {
  name = "web-server-asg_role"
  assume_role_policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      }
    }
  ]
})
  force_detach_policies = false
  max_session_duration  = 3600
  path                  = "/"
  tags = {
    Name           = "web-server-asg_role"
    State          = "alb-web-servers"
    Struct8Creator = "Contato Struct"
  }
}




### CATEGORY: NETWORK ###

resource "aws_vpc" "alb-web-servers" {
  cidr_block           = "10.3.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default"
  tags = {
    Name           = "alb-web-servers"
    State          = "alb-web-servers"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "private-subnet-a" {
  vpc_id                  = aws_vpc.alb-web-servers.id
  availability_zone       = "us-west-2a"
  cidr_block              = "10.3.1.0/24"
  map_public_ip_on_launch = false
  tags = {
    Name           = "private-subnet-a"
    State          = "alb-web-servers"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "private-subnet-b" {
  vpc_id                  = aws_vpc.alb-web-servers.id
  availability_zone       = "us-west-2b"
  cidr_block              = "10.3.3.0/24"
  map_public_ip_on_launch = false
  tags = {
    Name           = "private-subnet-b"
    State          = "alb-web-servers"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "private-subnet-c" {
  vpc_id                  = aws_vpc.alb-web-servers.id
  availability_zone       = "us-west-2c"
  cidr_block              = "10.3.5.0/24"
  map_public_ip_on_launch = false
  tags = {
    Name           = "private-subnet-c"
    State          = "alb-web-servers"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "public-subnet-a" {
  vpc_id                  = aws_vpc.alb-web-servers.id
  availability_zone       = "us-west-2a"
  cidr_block              = "10.3.0.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name           = "public-subnet-a"
    State          = "alb-web-servers"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "public-subnet-b" {
  vpc_id                  = aws_vpc.alb-web-servers.id
  availability_zone       = "us-west-2b"
  cidr_block              = "10.3.2.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name           = "public-subnet-b"
    State          = "alb-web-servers"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "public-subnet-c" {
  vpc_id                  = aws_vpc.alb-web-servers.id
  availability_zone       = "us-west-2c"
  cidr_block              = "10.3.4.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name           = "public-subnet-c"
    State          = "alb-web-servers"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_internet_gateway" "internet-gateway" {
  vpc_id = aws_vpc.alb-web-servers.id
  tags = {
    Name           = "internet-gateway"
    State          = "alb-web-servers"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route" "route_private-route-table_to_nat-instance_ipv4" {
  network_interface_id   = aws_instance.nat-instance.primary_network_interface_id
  route_table_id         = aws_route_table.private-route-table.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route" "route_public-route-table_to_internet-gateway_ipv4" {
  gateway_id             = aws_internet_gateway.internet-gateway.id
  route_table_id         = aws_route_table.public-route-table.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table" "private-route-table" {
  vpc_id = aws_vpc.alb-web-servers.id
  tags = {
    Name           = "private-route-table"
    State          = "alb-web-servers"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route_table" "public-route-table" {
  vpc_id = aws_vpc.alb-web-servers.id
  tags = {
    Name           = "public-route-table"
    State          = "alb-web-servers"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route_table_association" "aws_route_table_association_private_subnet_a_private_route_table" {
  route_table_id = aws_route_table.private-route-table.id
  subnet_id      = aws_subnet.private-subnet-a.id
}

resource "aws_route_table_association" "aws_route_table_association_private_subnet_b_private_route_table" {
  route_table_id = aws_route_table.private-route-table.id
  subnet_id      = aws_subnet.private-subnet-b.id
}

resource "aws_route_table_association" "aws_route_table_association_private_subnet_c_private_route_table" {
  route_table_id = aws_route_table.private-route-table.id
  subnet_id      = aws_subnet.private-subnet-c.id
}

resource "aws_route_table_association" "aws_route_table_association_public_subnet_a_public_route_table" {
  route_table_id = aws_route_table.public-route-table.id
  subnet_id      = aws_subnet.public-subnet-a.id
}

resource "aws_route_table_association" "aws_route_table_association_public_subnet_b_public_route_table" {
  route_table_id = aws_route_table.public-route-table.id
  subnet_id      = aws_subnet.public-subnet-b.id
}

resource "aws_route_table_association" "aws_route_table_association_public_subnet_c_public_route_table" {
  route_table_id = aws_route_table.public-route-table.id
  subnet_id      = aws_subnet.public-subnet-c.id
}

resource "aws_security_group" "autoscaling_group_web-server-asg_group" {
  name                   = "autoscaling_group_web-server-asg_group"
  vpc_id                 = aws_vpc.alb-web-servers.id
  revoke_rules_on_delete = false
  tags = {
    Name           = "autoscaling_group_web-server-asg_group"
    State          = "alb-web-servers"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group" "instance_nat-instance_group" {
  name                   = "instance_nat-instance_group"
  vpc_id                 = aws_vpc.alb-web-servers.id
  revoke_rules_on_delete = false
  tags = {
    Name           = "instance_nat-instance_group"
    State          = "alb-web-servers"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group" "lb_application-load-balancer_group" {
  name                   = "lb_application-load-balancer_group"
  vpc_id                 = aws_vpc.alb-web-servers.id
  revoke_rules_on_delete = false
  tags = {
    Name           = "lb_application-load-balancer_group"
    State          = "alb-web-servers"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group_rule" "rule_autoscaling_group_web_server_asg_group_egress_all_protocols" {
  security_group_id = aws_security_group.autoscaling_group_web-server-asg_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "rule_instance_nat_instance_group_egress_all_protocols" {
  security_group_id = aws_security_group.instance_nat-instance_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "rule_instance_nat_instance_group_ingress_all_protocols" {
  security_group_id = aws_security_group.instance_nat-instance_group.id
  cidr_blocks       = ["10.3.0.0/16"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 65535
  type              = "ingress"
}

resource "aws_security_group_rule" "rule_lb_application_load_balancer_group_egress_all_protocols" {
  security_group_id = aws_security_group.lb_application-load-balancer_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "rule_lb_application_load_balancer_group_ingress_all_protocols" {
  security_group_id = aws_security_group.lb_application-load-balancer_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 80
  protocol          = "-1"
  to_port           = 80
  type              = "ingress"
}

resource "aws_security_group_rule" "rule_lb_application_load_balancer_group_to_autoscaling_group_web_server_asg_group_tcp_80" {
  security_group_id        = aws_security_group.autoscaling_group_web-server-asg_group.id
  source_security_group_id = aws_security_group.lb_application-load-balancer_group.id
  description              = "Allow from lb_application-load-balancer_group (tcp:80-80)"
  from_port                = 80
  protocol                 = "tcp"
  to_port                  = 80
  type                     = "ingress"
}

resource "aws_lb" "application-load-balancer" {
  name               = "application-load-balancer"
  idle_timeout       = 60
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_application-load-balancer_group.id]
  subnets            = [aws_subnet.public-subnet-a.id, aws_subnet.public-subnet-b.id, aws_subnet.public-subnet-c.id]
  tags = {
    Name           = "application-load-balancer"
    State          = "alb-web-servers"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_lb_listener" "http-listener" {
  load_balancer_arn                    = aws_lb.application-load-balancer.arn
  port                                 = 80
  protocol                             = "HTTP"
  routing_http_response_server_enabled = true
  default_action {
    order            = 1
    target_group_arn = aws_lb_target_group.web-target-group.arn
    type             = "forward"
    forward {
      target_group {
        arn = aws_lb_target_group.web-target-group.arn
      }
    }
  }
  tags = {
    Name           = "http-listener"
    State          = "alb-web-servers"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_lb_target_group" "web-target-group" {
  name                          = "web-target-group"
  vpc_id                        = aws_vpc.alb-web-servers.id
  deregistration_delay          = "300"
  ip_address_type               = "ipv4"
  load_balancing_algorithm_type = "round_robin"
  port                          = 80
  protocol                      = "HTTP"
  slow_start                    = 0
  target_type                   = "instance"
  health_check {
    matcher  = "200"
    path     = "/"
    protocol = "HTTP"
  }
  tags = {
    Name           = "web-target-group"
    State          = "alb-web-servers"
    Struct8Creator = "Contato Struct"
  }
}




### CATEGORY: COMPUTE ###

data "local_file" "UserData_nat-instance" {
  filename = "${path.module}/.external_modules/struct8-templates/templates/alb-web-servers/v1/user_data/nat.sh"
}

data "aws_ami" "AMI_Data_Source_nat-instance" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-kernel-6.1-arm64"]
  }
}

resource "aws_instance" "nat-instance" {
  subnet_id                   = aws_subnet.public-subnet-a.id
  ami                         = data.aws_ami.AMI_Data_Source_nat-instance.id
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.nat-instance_profile.name
  instance_type               = "t4g.nano"
  source_dest_check           = false
  user_data_base64 = base64encode(<<-EOFUData
#!/bin/bash

${data.local_file.UserData_nat-instance.content}
EOFUData
)
  user_data_replace_on_change = false
  vpc_security_group_ids      = [aws_security_group.instance_nat-instance_group.id]
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
  root_block_device {
    encrypted   = true
    iops        = 3000
    throughput  = 125
    volume_size = 8
    volume_type = "gp3"
  }
  tags = {
    Name           = "nat-instance"
    State          = "alb-web-servers"
    Struct8Creator = "Contato Struct"
  }
}

data "local_file" "UserData_web-server-launch-template" {
  filename = "${path.module}/.external_modules/struct8-templates/templates/alb-web-servers/v1/user_data/web-info-page.sh"
}

data "aws_ami" "AMI_Data_Source_web-server-launch-template" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-kernel-6.1-arm64"]
  }
}

resource "aws_launch_template" "web-server-launch-template" {
  image_id               = data.aws_ami.AMI_Data_Source_web-server-launch-template.id
  name                   = "web-server-launch-template"
  description            = "Web server launch template: Graviton t4g.nano Spot, AL2023 arm64, IMDSv2 required. user_data installs Apache (with swap to avoid OOM) and serves a live IMDSv2 instance-info page at /."
  instance_type          = "t4g.micro"
  update_default_version = true
  user_data = base64encode(<<-EOFUData
#!/bin/bash

# --- BEGIN STRUCT8 VARIABLES ---
cat << 'EOFENV' > /etc/struct8_env
NAME    = "web-server-asg"
REGION  = "${data.aws_region.current.region}"
ACCOUNT = "${data.aws_caller_identity.current.account_id}"
EOFENV
cat /etc/struct8_env >> /etc/environment
sed 's/^/export /' /etc/struct8_env > /etc/profile.d/struct8_vars.sh
chmod +x /etc/profile.d/struct8_vars.sh
chmod 644 /etc/struct8_env
# --- END STRUCT8 VARIABLES ---

${data.local_file.UserData_web-server-launch-template.content}
EOFUData
)
  vpc_security_group_ids = [aws_security_group.autoscaling_group_web-server-asg_group.id]
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      delete_on_termination = true
      encrypted             = true
      iops                  = 3000
      throughput            = 125
      volume_size           = 8
      volume_type           = "gp3"
    }
  }
  iam_instance_profile {
    name = aws_iam_instance_profile.web-server-asg_profile.name
  }
  instance_market_options {
    market_type = "spot"
    spot_options {
      instance_interruption_behavior = "terminate"
      spot_instance_type             = "one-time"
    }
  }
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
  tag_specifications {
    resource_type = "volume"
    tags = {
    Name           = "web-server-asg"
    State          = "alb-web-servers"
    Struct8Creator = "Contato Struct"
  }
  }
  tags = {
    Name           = "web-server-launch-template"
    State          = "alb-web-servers"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_autoscaling_group" "web-server-asg" {
  name                      = "web-server-asg"
  default_instance_warmup   = 0
  desired_capacity          = 3
  health_check_grace_period = 180
  health_check_type         = "ELB"
  max_instance_lifetime     = 0
  max_size                  = 3
  metrics_granularity       = "1Minute"
  min_elb_capacity          = 0
  min_size                  = 3
  target_group_arns         = [aws_lb_target_group.web-target-group.arn]
  termination_policies      = ["Default"]
  vpc_zone_identifier       = [aws_subnet.private-subnet-a.id, aws_subnet.private-subnet-b.id, aws_subnet.private-subnet-c.id]
  wait_for_elb_capacity     = 0
  launch_template {
    version = aws_launch_template.web-server-launch-template.latest_version
    id      = aws_launch_template.web-server-launch-template.id
  }
  tag {
    key                 = "Name"
    propagate_at_launch = true
    value               = "web-server-asg"
  }
  tag {
    key                 = "State"
    propagate_at_launch = true
    value               = "alb-web-servers"
  }
  tag {
    key                 = "Struct8Creator"
    propagate_at_launch = true
    value               = "Contato Struct"
  }
}


