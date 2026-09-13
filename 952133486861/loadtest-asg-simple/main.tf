terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  backend "s3" {
    bucket  = "struct8-import"
    key     = "952133486861/loadtest-asg-simple/main.tfstate"
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

resource "aws_iam_instance_profile" "hub-asg_profile" {
  name = "hub-asg_profile"
  role = aws_iam_role.hub-asg_role.name
  tags = {
    Name           = "hub-asg_profile"
    State          = "loadtest-asg-simple"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_instance_profile" "k6-load-generator_profile" {
  name = "k6-load-generator_profile"
  role = aws_iam_role.k6-load-generator_role.name
  tags = {
    Name           = "k6-load-generator_profile"
    State          = "loadtest-asg-simple"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_instance_profile" "nat-a_profile" {
  name = "nat-a_profile"
  role = aws_iam_role.nat-a_role.name
  tags = {
    Name           = "nat-a_profile"
    State          = "loadtest-asg-simple"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "hub-asg_role" {
  name = "hub-asg_role"
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
    Name           = "hub-asg_role"
    State          = "loadtest-asg-simple"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "k6-load-generator_role" {
  name = "k6-load-generator_role"
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
    Name           = "k6-load-generator_role"
    State          = "loadtest-asg-simple"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "nat-a_role" {
  name = "nat-a_role"
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
    Name           = "nat-a_role"
    State          = "loadtest-asg-simple"
    Struct8Creator = "Contato Struct"
  }
}




### CATEGORY: NETWORK ###

resource "aws_vpc" "loadtest-asg-simple" {
  cidr_block           = "10.60.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default"
  tags = {
    Name           = "loadtest-asg-simple"
    State          = "loadtest-asg-simple"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "private-a" {
  vpc_id                  = aws_vpc.loadtest-asg-simple.id
  availability_zone       = "us-west-2a"
  cidr_block              = "10.60.11.0/24"
  map_public_ip_on_launch = false
  tags = {
    Name           = "private-a"
    State          = "loadtest-asg-simple"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "private-b" {
  vpc_id                  = aws_vpc.loadtest-asg-simple.id
  availability_zone       = "us-west-2b"
  cidr_block              = "10.60.0.0/24"
  map_public_ip_on_launch = false
  tags = {
    Name           = "private-b"
    State          = "loadtest-asg-simple"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "public-a" {
  vpc_id                  = aws_vpc.loadtest-asg-simple.id
  availability_zone       = "us-west-2a"
  cidr_block              = "10.60.1.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name           = "public-a"
    State          = "loadtest-asg-simple"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "public-b" {
  vpc_id                  = aws_vpc.loadtest-asg-simple.id
  availability_zone       = "us-west-2b"
  cidr_block              = "10.60.2.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name           = "public-b"
    State          = "loadtest-asg-simple"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "public-k6" {
  vpc_id                  = aws_vpc.loadtest-asg-simple.id
  availability_zone       = "us-west-2a"
  cidr_block              = "10.60.3.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name           = "public-k6"
    State          = "loadtest-asg-simple"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_internet_gateway" "igw-k6" {
  vpc_id = aws_vpc.loadtest-asg-simple.id
  tags = {
    Name           = "igw-k6"
    State          = "loadtest-asg-simple"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route" "route_rt-private1_to_nat-a_ipv4" {
  network_interface_id   = aws_instance.nat-a.primary_network_interface_id
  route_table_id         = aws_route_table.rt-private1.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route" "route_rt-public1_to_igw-k6_ipv4" {
  gateway_id             = aws_internet_gateway.igw-k6.id
  route_table_id         = aws_route_table.rt-public1.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table" "rt-private1" {
  vpc_id = aws_vpc.loadtest-asg-simple.id
  tags = {
    Name           = "rt-private1"
    State          = "loadtest-asg-simple"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route_table" "rt-public1" {
  vpc_id = aws_vpc.loadtest-asg-simple.id
  tags = {
    Name           = "rt-public1"
    State          = "loadtest-asg-simple"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route_table_association" "aws_route_table_association_private_a_rt_private1" {
  route_table_id = aws_route_table.rt-private1.id
  subnet_id      = aws_subnet.private-a.id
}

resource "aws_route_table_association" "aws_route_table_association_private_b_rt_private1" {
  route_table_id = aws_route_table.rt-private1.id
  subnet_id      = aws_subnet.private-b.id
}

resource "aws_route_table_association" "aws_route_table_association_public_a_rt_public1" {
  route_table_id = aws_route_table.rt-public1.id
  subnet_id      = aws_subnet.public-a.id
}

resource "aws_route_table_association" "aws_route_table_association_public_b_rt_public1" {
  route_table_id = aws_route_table.rt-public1.id
  subnet_id      = aws_subnet.public-b.id
}

resource "aws_route_table_association" "aws_route_table_association_public_k6_rt_public1" {
  route_table_id = aws_route_table.rt-public1.id
  subnet_id      = aws_subnet.public-k6.id
}

resource "aws_security_group" "autoscaling_group_hub-asg_group" {
  name                   = "autoscaling_group_hub-asg_group"
  vpc_id                 = aws_vpc.loadtest-asg-simple.id
  revoke_rules_on_delete = false
  tags = {
    Name           = "autoscaling_group_hub-asg_group"
    State          = "loadtest-asg-simple"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group" "instance_k6-load-generator_group" {
  name                   = "instance_k6-load-generator_group"
  vpc_id                 = aws_vpc.loadtest-asg-simple.id
  revoke_rules_on_delete = false
  tags = {
    Name           = "instance_k6-load-generator_group"
    State          = "loadtest-asg-simple"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group" "instance_nat-a_group" {
  name                   = "instance_nat-a_group"
  vpc_id                 = aws_vpc.loadtest-asg-simple.id
  revoke_rules_on_delete = false
  tags = {
    Name           = "instance_nat-a_group"
    State          = "loadtest-asg-simple"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group" "lb_alb-hub_group" {
  name                   = "lb_alb-hub_group"
  vpc_id                 = aws_vpc.loadtest-asg-simple.id
  revoke_rules_on_delete = false
}

resource "aws_security_group_rule" "rule_autoscaling_group_hub_asg_group_egress_all_protocols" {
  security_group_id = aws_security_group.autoscaling_group_hub-asg_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "rule_autoscaling_group_hub_asg_group_ingress_tcp_8080" {
  security_group_id = aws_security_group.autoscaling_group_hub-asg_group.id
  cidr_blocks       = ["10.60.0.0/16"]
  description       = "Hub HTTP from k6 generator (direct, ALB disabled during minimal test)"
  from_port         = 8080
  protocol          = "tcp"
  to_port           = 8080
  type              = "ingress"
}

resource "aws_security_group_rule" "rule_instance_k6_load_generator_group_egress_all_protocols" {
  security_group_id = aws_security_group.instance_k6-load-generator_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "rule_instance_k6_load_generator_group_ingress_tcp_5665" {
  security_group_id = aws_security_group.instance_k6-load-generator_group.id
  cidr_blocks       = ["10.60.0.0/16"]
  description       = "k6 web dashboard, forwarded from the NAT instance"
  from_port         = 5665
  protocol          = "tcp"
  to_port           = 5665
  type              = "ingress"
}

resource "aws_security_group_rule" "rule_instance_k6_load_generator_group_to_lb_alb_hub_group_tcp_80" {
  security_group_id        = aws_security_group.lb_alb-hub_group.id
  source_security_group_id = aws_security_group.instance_k6-load-generator_group.id
  description              = "HTTP load test traffic from k6 to the ALB"
  from_port                = 80
  protocol                 = "tcp"
  to_port                  = 80
  type                     = "ingress"
}

resource "aws_security_group_rule" "rule_instance_nat_a_group_egress_all_protocols" {
  security_group_id = aws_security_group.instance_nat-a_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "rule_instance_nat_a_group_ingress_all_protocols" {
  security_group_id = aws_security_group.instance_nat-a_group.id
  cidr_blocks       = ["10.60.0.0/16"]
  description       = "NAT: all traffic from the VPC to be routed out"
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "ingress"
}

resource "aws_security_group_rule" "rule_instance_nat_a_group_ingress_tcp_5665" {
  security_group_id = aws_security_group.instance_nat-a_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "k6 web dashboard from the internet"
  from_port         = 5665
  protocol          = "tcp"
  to_port           = 5665
  type              = "ingress"
}

resource "aws_security_group_rule" "rule_lb_alb_hub_group_egress_all_protocols" {
  security_group_id = aws_security_group.lb_alb-hub_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "rule_lb_alb_hub_group_ingress_tcp_5665" {
  security_group_id = aws_security_group.lb_alb-hub_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "k6 dashboard via ALB (public, ephemeral test env)"
  from_port         = 5665
  protocol          = "tcp"
  to_port           = 5665
  type              = "ingress"
}

resource "aws_security_group_rule" "rule_lb_alb_hub_group_ingress_tcp_80" {
  security_group_id = aws_security_group.lb_alb-hub_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "k6 load traffic to Hub via ALB (public: k6 reaches the ALB by its public IP)"
  from_port         = 80
  protocol          = "tcp"
  to_port           = 80
  type              = "ingress"
}

resource "aws_security_group_rule" "rule_lb_alb_hub_group_to_autoscaling_group_hub_asg_group_tcp_8080" {
  security_group_id        = aws_security_group.autoscaling_group_hub-asg_group.id
  source_security_group_id = aws_security_group.lb_alb-hub_group.id
  description              = "Hub HTTP from the ALB target group"
  from_port                = 8080
  protocol                 = "tcp"
  to_port                  = 8080
  type                     = "ingress"
}

resource "aws_security_group_rule" "rule_lb_alb_hub_group_to_instance_k6_load_generator_group_tcp_5665" {
  security_group_id        = aws_security_group.instance_k6-load-generator_group.id
  source_security_group_id = aws_security_group.lb_alb-hub_group.id
  description              = "k6 web dashboard from the ALB"
  from_port                = 5665
  protocol                 = "tcp"
  to_port                  = 5665
  type                     = "ingress"
}

resource "aws_lb" "alb-hub" {
  name               = "alb-hub"
  idle_timeout       = 60
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_alb-hub_group.id]
  subnets            = [aws_subnet.public-a.id, aws_subnet.public-b.id]
  tags = {
    Name           = "alb-hub"
    State          = "loadtest-asg-simple"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_lb_listener" "listener-dashboard" {
  load_balancer_arn                    = aws_lb.alb-hub.arn
  port                                 = 5665
  protocol                             = "HTTP"
  routing_http_response_server_enabled = true
  default_action {
    order            = 1
    target_group_arn = aws_lb_target_group.tg-k6-dashboard.arn
    type             = "forward"
    forward {
      target_group {
        arn = aws_lb_target_group.tg-k6-dashboard.arn
      }
    }
  }
  tags = {
    Name           = "listener-dashboard"
    State          = "loadtest-asg-simple"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_lb_listener" "listener-http" {
  load_balancer_arn                    = aws_lb.alb-hub.arn
  port                                 = 80
  protocol                             = "HTTP"
  routing_http_response_server_enabled = true
  default_action {
    order            = 1
    target_group_arn = aws_lb_target_group.tg-hub.arn
    type             = "forward"
    forward {
      target_group {
        arn = aws_lb_target_group.tg-hub.arn
      }
    }
  }
  tags = {
    Name           = "listener-http"
    State          = "loadtest-asg-simple"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_lb_target_group" "tg-hub" {
  name                          = "tg-hub"
  vpc_id                        = aws_vpc.loadtest-asg-simple.id
  deregistration_delay          = "300"
  ip_address_type               = "ipv4"
  load_balancing_algorithm_type = "round_robin"
  port                          = 8080
  protocol                      = "HTTP"
  slow_start                    = 0
  target_type                   = "instance"
  health_check {
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 3
  }
  tags = {
    Name           = "tg-hub"
    State          = "loadtest-asg-simple"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_lb_target_group" "tg-k6-dashboard" {
  name                          = "tg-k6-dashboard"
  vpc_id                        = aws_vpc.loadtest-asg-simple.id
  deregistration_delay          = "300"
  ip_address_type               = "ipv4"
  load_balancing_algorithm_type = "round_robin"
  port                          = 5665
  protocol                      = "HTTP"
  slow_start                    = 0
  target_type                   = "instance"
  tags = {
    Name           = "tg-k6-dashboard"
    State          = "loadtest-asg-simple"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_lb_target_group_attachment" "attach_k6-load-generator_to_tg-k6-dashboard" {
  target_id        = aws_instance.k6-load-generator.id
  port             = 5665
  target_group_arn = aws_lb_target_group.tg-k6-dashboard.arn
}




### CATEGORY: COMPUTE ###

data "local_file" "UserData_k6-load-generator" {
  filename = "${path.module}/.external_modules/struct8-templates/templates/vpc-k6-load-generator/v1/user_data/k6-bootstrap.sh"
}

data "aws_ami" "AMI_Data_Source_k6-load-generator" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-kernel-6.1-arm64"]
  }
}

resource "aws_instance" "k6-load-generator" {
  subnet_id                   = aws_subnet.public-k6.id
  ami                         = data.aws_ami.AMI_Data_Source_k6-load-generator.id
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.k6-load-generator_profile.name
  instance_type               = "t4g.nano"
  user_data_base64 = base64encode(<<-EOFUData
#!/bin/bash

# --- BEGIN STRUCT8 VARIABLES ---
cat << 'EOFENV' > /etc/struct8_env
AUTOSTART="on"
STARTUP_DELAY="360"
DURATION="5m"
VUS="20"
METHOD="GET"
BOOT_GEN="3"
NAME="k6-load-generator"
REGION="${data.aws_region.current.region}"
ACCOUNT="${data.aws_caller_identity.current.account_id}"
AWS_LB_DNSNAME_0="${aws_lb.alb-hub.dns_name}"
EOFENV
cat /etc/struct8_env >> /etc/environment
sed 's/^/export /' /etc/struct8_env > /etc/profile.d/struct8_vars.sh
chmod +x /etc/profile.d/struct8_vars.sh
chmod 644 /etc/struct8_env
# --- END STRUCT8 VARIABLES ---

${data.local_file.UserData_k6-load-generator.content}
EOFUData
)
  user_data_replace_on_change = true
  vpc_security_group_ids      = [aws_security_group.instance_k6-load-generator_group.id]
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
  tags = {
    Name           = "k6-load-generator"
    State          = "loadtest-asg-simple"
    Struct8Creator = "Contato Struct"
  }
}

data "local_file" "UserData_nat-a" {
  filename = "${path.module}/.external_modules/struct8-templates/templates/ec2-nat-private/v1/user_data/Nat.sh"
}

data "aws_ami" "AMI_Data_Source_nat-a" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-kernel-6.1-x86_64"]
  }
}

resource "aws_instance" "nat-a" {
  subnet_id                   = aws_subnet.public-a.id
  ami                         = data.aws_ami.AMI_Data_Source_nat-a.id
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.nat-a_profile.name
  instance_type               = "t3.nano"
  source_dest_check           = false
  user_data_base64 = base64encode(<<-EOFUData
#!/bin/bash

# --- BEGIN STRUCT8 VARIABLES ---
cat << 'EOFENV' > /etc/struct8_env
NAME="nat-a"
REGION="${data.aws_region.current.region}"
ACCOUNT="${data.aws_caller_identity.current.account_id}"
EOFENV
cat /etc/struct8_env >> /etc/environment
sed 's/^/export /' /etc/struct8_env > /etc/profile.d/struct8_vars.sh
chmod +x /etc/profile.d/struct8_vars.sh
chmod 644 /etc/struct8_env
# --- END STRUCT8 VARIABLES ---

${data.local_file.UserData_nat-a.content}
EOFUData
)
  user_data_replace_on_change = false
  vpc_security_group_ids      = [aws_security_group.instance_nat-a_group.id]
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
    Name           = "nat-a"
    State          = "loadtest-asg-simple"
    Struct8Creator = "Contato Struct"
  }
}

data "local_file" "UserData_hub-lt" {
  filename = "${path.module}/.external_modules/struct8-templates/templates/ec2-hub-docker/v1/user_data/hub-docker.sh"
}

data "aws_ami" "AMI_Data_Source_hub-lt" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-kernel-6.1-arm64"]
  }
}

resource "aws_launch_template" "hub-lt" {
  image_id               = data.aws_ami.AMI_Data_Source_hub-lt.id
  name                   = "hub-lt"
  description            = "ASG launch template. user_data hub-docker.sh installs Docker, clones struct8-hub, builds the arm64 image and runs the Hub with the load-test endpoint enabled. arm64 AMI for t4g. The boot build takes about 5 min, which is why the ASG grace period is high."
  instance_type          = "t4g.nano"
  update_default_version = true
  user_data = base64encode(<<-EOFUData
#!/bin/bash

# --- BEGIN STRUCT8 VARIABLES ---
cat << 'EOFENV' > /etc/struct8_env
HUB_LOADTEST="on"
HUB_PORT="8080"
BOOT_GEN="3"
NAME="hub-asg"
REGION="${data.aws_region.current.region}"
ACCOUNT="${data.aws_caller_identity.current.account_id}"
EOFENV
cat /etc/struct8_env >> /etc/environment
sed 's/^/export /' /etc/struct8_env > /etc/profile.d/struct8_vars.sh
chmod +x /etc/profile.d/struct8_vars.sh
chmod 644 /etc/struct8_env
# --- END STRUCT8 VARIABLES ---

${data.local_file.UserData_hub-lt.content}
EOFUData
)
  vpc_security_group_ids = [aws_security_group.autoscaling_group_hub-asg_group.id]
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
    name = aws_iam_instance_profile.hub-asg_profile.name
  }
  metadata_options {
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 1
    http_tokens                 = "required"
  }
  tag_specifications {
    resource_type = "volume"
    tags = {
    Name           = "hub-asg"
    State          = "loadtest-asg-simple"
    Struct8Creator = "Contato Struct"
  }
  }
  tags = {
    Name           = "hub-lt"
    State          = "loadtest-asg-simple"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_autoscaling_group" "hub-asg" {
  name                      = "hub-asg"
  default_instance_warmup   = 420
  desired_capacity          = 1
  enabled_metrics           = ["GroupDesiredCapacity", "GroupInServiceInstances", "GroupMaxSize", "GroupMinSize", "GroupPendingInstances", "GroupStandbyInstances", "GroupTerminatingInstances", "GroupTotalInstances"]
  health_check_grace_period = 600
  health_check_type         = "ELB"
  max_instance_lifetime     = 0
  max_size                  = 1
  metrics_granularity       = "1Minute"
  min_elb_capacity          = 0
  min_size                  = 1
  target_group_arns         = [aws_lb_target_group.tg-hub.arn]
  termination_policies      = ["Default"]
  vpc_zone_identifier       = [aws_subnet.private-a.id, aws_subnet.private-b.id]
  wait_for_elb_capacity     = 0
  launch_template {
    version = aws_launch_template.hub-lt.latest_version
    id      = aws_launch_template.hub-lt.id
  }
  tag {
    key                 = "Name"
    propagate_at_launch = true
    value               = "hub-asg"
  }
  tag {
    key                 = "State"
    propagate_at_launch = true
    value               = "loadtest-asg-simple"
  }
  tag {
    key                 = "Struct8Creator"
    propagate_at_launch = true
    value               = "Contato Struct"
  }
}

resource "aws_autoscaling_policy" "cpu-scale" {
  autoscaling_group_name    = aws_autoscaling_group.hub-asg.name
  name                      = "cpu-scale"
  enabled                   = true
  estimated_instance_warmup = 300
  policy_type               = "TargetTrackingScaling"
  target_tracking_configuration {
    disable_scale_in = false
    target_value     = 50
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
  }
}


