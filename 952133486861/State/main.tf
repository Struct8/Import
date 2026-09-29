terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  backend "s3" {
    bucket  = "struct8-import"
    key     = "952133486861/State/main.tfstate"
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

resource "aws_iam_instance_profile" "lab2-ecs-asg_profile" {
  name = "lab2-ecs-asg_profile"
  role = aws_iam_role.lab2-ecs-asg_role.name
  tags = {
    Name           = "lab2-ecs-asg_profile"
    State          = "State"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_instance_profile" "lab2-k6_profile" {
  name = "lab2-k6_profile"
  role = aws_iam_role.lab2-k6_role.name
  tags = {
    Name           = "lab2-k6_profile"
    State          = "State"
    Struct8Creator = "Contato Struct"
  }
}

data "aws_iam_policy_document" "autoscaling_group_lab2-ecs-asg_st_State_doc" {
  statement {
    sid       = "AllowLab2ecscluster"
    effect    = "Allow"
    actions   = ["ecs:DeregisterContainerInstance", "ecs:DiscoverPollEndpoint", "ecs:Poll", "ecs:RegisterContainerInstance", "ecs:StartTelemetrySession", "ecs:Submit*"]
    resources = [aws_ecs_cluster.lab2-ecs-cluster.arn]
  }
}

resource "aws_iam_policy" "autoscaling_group_lab2-ecs-asg_st_State" {
  name        = "autoscaling_group_lab2-ecs-asg_st_State"
  description = "Access Policy for lab2-ecs-asg"
  policy      = data.aws_iam_policy_document.autoscaling_group_lab2-ecs-asg_st_State_doc.json
}

data "aws_iam_policy_document" "ecs_task_definition_lab2-hub_execution_st_State_doc" {
  statement {
    sid       = "AllowPullFromRepo"
    effect    = "Allow"
    actions   = ["ecr:BatchCheckLayerAvailability", "ecr:BatchGetImage", "ecr:GetDownloadUrlForLayer"]
    resources = [aws_ecr_repository.lab2-hub-ecr.arn]
  }
  statement {
    sid       = "AllowEcrAuth"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ecs_task_definition_lab2-hub_execution_st_State" {
  name        = "ecs_task_definition_lab2-hub_execution_st_State"
  description = "Access Policy for lab2-hub (Role: execution)"
  policy      = data.aws_iam_policy_document.ecs_task_definition_lab2-hub_execution_st_State_doc.json
}

resource "aws_iam_role" "execution_role_ecs_lab2-hub" {
  name = "execution_role_ecs_lab2-hub"
  assume_role_policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      }
    }
  ]
})
  tags = {
    Name           = "execution_role_ecs_lab2-hub"
    State          = "State"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "lab2-ecs-asg_role" {
  name = "lab2-ecs-asg_role"
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
    Name           = "lab2-ecs-asg_role"
    State          = "State"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "lab2-k6_role" {
  name = "lab2-k6_role"
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
    Name           = "lab2-k6_role"
    State          = "State"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "task_role_ecs_lab2-hub" {
  name = "task_role_ecs_lab2-hub"
  assume_role_policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      }
    }
  ]
})
  tags = {
    Name           = "task_role_ecs_lab2-hub"
    State          = "State"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role_policy_attachment" "autoscaling_group_lab2-ecs-asg_st_State_attach" {
  policy_arn = aws_iam_policy.autoscaling_group_lab2-ecs-asg_st_State.arn
  role       = aws_iam_role.lab2-ecs-asg_role.name
}

resource "aws_iam_role_policy_attachment" "ecs_task_definition_lab2-hub_execution_st_State_attach" {
  policy_arn = aws_iam_policy.ecs_task_definition_lab2-hub_execution_st_State.arn
  role       = aws_iam_role.execution_role_ecs_lab2-hub.name
}

resource "aws_iam_role_policy_attachment" "service_role_AmazonEC2ContainerServiceforEC2Role_to_lab2-ecs-asg_attach" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
  role       = aws_iam_role.lab2-ecs-asg_role.name
}




### CATEGORY: NETWORK ###

resource "aws_vpc" "VPC2" {
  cidr_block       = "10.6.0.0/16"
  instance_tenancy = "default"
  tags = {
    Name           = "VPC2"
    State          = "State"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "lab2-private-a" {
  vpc_id                  = aws_vpc.VPC2.id
  availability_zone       = "us-west-2a"
  cidr_block              = "10.6.1.0/24"
  map_public_ip_on_launch = false
  tags = {
    Name           = "lab2-private-a"
    State          = "State"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "lab2-private-b" {
  vpc_id                  = aws_vpc.VPC2.id
  availability_zone       = "us-west-2b"
  cidr_block              = "10.6.3.0/24"
  map_public_ip_on_launch = false
  tags = {
    Name           = "lab2-private-b"
    State          = "State"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "lab2-public-a" {
  vpc_id                  = aws_vpc.VPC2.id
  availability_zone       = "us-west-2a"
  cidr_block              = "10.6.0.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name           = "lab2-public-a"
    State          = "State"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "lab2-public-b" {
  vpc_id                  = aws_vpc.VPC2.id
  availability_zone       = "us-west-2b"
  cidr_block              = "10.6.2.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name           = "lab2-public-b"
    State          = "State"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_internet_gateway" "lab2-igw" {
  vpc_id = aws_vpc.VPC2.id
  tags = {
    Name           = "lab2-igw"
    State          = "State"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_nat_gateway" "lab2-natgw" {
  vpc_id            = aws_vpc.VPC2.id
  availability_mode = "regional"
  connectivity_type = "public"
  tags = {
    Name           = "lab2-natgw"
    State          = "State"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route" "route_lab2-rtb-private_to_lab2-natgw_ipv4" {
  nat_gateway_id         = aws_nat_gateway.lab2-natgw.id
  route_table_id         = aws_route_table.lab2-rtb-private.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route" "route_lab2-rtb-public_to_lab2-igw_ipv4" {
  gateway_id             = aws_internet_gateway.lab2-igw.id
  route_table_id         = aws_route_table.lab2-rtb-public.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table" "lab2-rtb-private" {
  vpc_id = aws_vpc.VPC2.id
  tags = {
    Name           = "lab2-rtb-private"
    State          = "State"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route_table" "lab2-rtb-public" {
  vpc_id = aws_vpc.VPC2.id
  tags = {
    Name           = "lab2-rtb-public"
    State          = "State"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route_table_association" "aws_route_table_association_lab2_private_a_lab2_rtb_private" {
  route_table_id = aws_route_table.lab2-rtb-private.id
  subnet_id      = aws_subnet.lab2-private-a.id
}

resource "aws_route_table_association" "aws_route_table_association_lab2_private_b_lab2_rtb_private" {
  route_table_id = aws_route_table.lab2-rtb-private.id
  subnet_id      = aws_subnet.lab2-private-b.id
}

resource "aws_route_table_association" "aws_route_table_association_lab2_public_a_lab2_rtb_public" {
  route_table_id = aws_route_table.lab2-rtb-public.id
  subnet_id      = aws_subnet.lab2-public-a.id
}

resource "aws_route_table_association" "aws_route_table_association_lab2_public_b_lab2_rtb_public" {
  route_table_id = aws_route_table.lab2-rtb-public.id
  subnet_id      = aws_subnet.lab2-public-b.id
}

resource "aws_security_group" "autoscaling_group_lab2-ecs-asg_group" {
  name   = "autoscaling_group_lab2-ecs-asg_group"
  vpc_id = aws_vpc.VPC2.id
}

resource "aws_security_group" "instance_lab2-k6_group" {
  name                   = "instance_lab2-k6_group"
  vpc_id                 = aws_vpc.VPC2.id
  revoke_rules_on_delete = false
  tags = {
    Name           = "instance_lab2-k6_group"
    State          = "State"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group" "lb_lab2-alb_group" {
  name                   = "lb_lab2-alb_group"
  vpc_id                 = aws_vpc.VPC2.id
  revoke_rules_on_delete = false
  tags = {
    Name           = "lb_lab2-alb_group"
    State          = "State"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group_rule" "rule_autoscaling_group_lab2_ecs_asg_group_egress_all_protocols" {
  security_group_id = aws_security_group.autoscaling_group_lab2-ecs-asg_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "rule_autoscaling_group_lab2_ecs_asg_group_ingress_tcp_80" {
  security_group_id = aws_security_group.autoscaling_group_lab2-ecs-asg_group.id
  cidr_blocks       = ["10.6.0.0/16"]
  description       = "HTTP interno da VPC (teste via NAT)"
  from_port         = 80
  protocol          = "tcp"
  to_port           = 80
  type              = "ingress"
}

resource "aws_security_group_rule" "rule_instance_lab2_k6_group_egress_all_protocols" {
  security_group_id = aws_security_group.instance_lab2-k6_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "rule_instance_lab2_k6_group_to_lb_lab2_alb_group_tcp_80" {
  security_group_id        = aws_security_group.lb_lab2-alb_group.id
  source_security_group_id = aws_security_group.instance_lab2-k6_group.id
  description              = "k6 acessa o ALB na porta 80"
  from_port                = 80
  protocol                 = "tcp"
  to_port                  = 80
  type                     = "ingress"
}

resource "aws_security_group_rule" "rule_lb_lab2_alb_group_egress_all_protocols" {
  security_group_id = aws_security_group.lb_lab2-alb_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "rule_lb_lab2_alb_group_to_autoscaling_group_lab2_ecs_asg_group_tcp_32768_65535" {
  security_group_id        = aws_security_group.autoscaling_group_lab2-ecs-asg_group.id
  source_security_group_id = aws_security_group.lb_lab2-alb_group.id
  description              = "ALB para tasks ECS (bridge dynamic ports)"
  from_port                = 32768
  protocol                 = "tcp"
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_lb" "lab2-alb" {
  name               = "lab2-alb"
  enable_http2       = true
  idle_timeout       = 60
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_lab2-alb_group.id]
  subnets            = [aws_subnet.lab2-public-a.id, aws_subnet.lab2-public-b.id]
  tags = {
    Name           = "lab2-alb"
    State          = "State"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_lb_listener" "lab2-listener" {
  load_balancer_arn                    = aws_lb.lab2-alb.arn
  port                                 = 80
  protocol                             = "HTTP"
  routing_http_response_server_enabled = true
  default_action {
    order            = 1
    target_group_arn = aws_lb_target_group.lab2-tg-hub.arn
    type             = "forward"
    forward {
      target_group {
        arn = aws_lb_target_group.lab2-tg-hub.arn
      }
    }
  }
  tags = {
    Name           = "lab2-listener"
    State          = "State"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_lb_target_group" "lab2-tg-hub" {
  name                          = "lab2-tg-hub"
  vpc_id                        = aws_vpc.VPC2.id
  deregistration_delay          = "300"
  ip_address_type               = "ipv4"
  load_balancing_algorithm_type = "round_robin"
  port                          = 8080
  protocol                      = "HTTP"
  slow_start                    = 0
  target_type                   = "instance"
  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200-399"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 3
  }
  tags = {
    Name           = "lab2-tg-hub"
    State          = "State"
    Struct8Creator = "Contato Struct"
  }
}




### CATEGORY: COMPUTE ###

data "aws_ami" "AMI_Data_Source_lab2-k6" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-kernel-6.1-arm64"]
  }
}

resource "aws_instance" "lab2-k6" {
  # ajuste manual · user_data — aws_instance nao permite user_data custom com env vars; k6 instala e roda carga usando o DNS do ALB. Vars shell/JS escapadas com $$ para nao virarem interpolacao Terraform.
  subnet_id                   = aws_subnet.lab2-public-a.id
  ami                         = data.aws_ami.AMI_Data_Source_lab2-k6.id
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.lab2-k6_profile.name
  instance_type               = "t4g.small"
  user_data = base64encode(<<-EOT
#!/bin/bash
cat << 'EOFENV' > /etc/struct8_env
AWS_LB_DNSNAME_0="${aws_lb.lab2-alb.dns_name}"
EOFENV
curl -L https://github.com/grafana/k6/releases/download/v0.52.0/k6-v0.52.0-linux-arm64.tar.gz -o /tmp/k6.tgz
tar xzf /tmp/k6.tgz -C /tmp
cp /tmp/k6*/k6 /usr/local/bin/k6
source /etc/struct8_env
cat >/root/load.js <<'EOFJS'
import http from 'k6/http';
import { sleep } from 'k6';
export const options = { vus: 30, duration: '30m' };
const T = __ENV.TARGET_URL;
export default function () {
  http.post(`$${T}/loadtest?ms=250`);
  sleep(0.1);
}
EOFJS
TARGET_URL="http://$${AWS_LB_DNSNAME_0}" nohup k6 run /root/load.js > /var/log/k6.log 2>&1 &
EOT
)
  user_data_base64 = base64encode(<<-EOFUData
#!/bin/bash

# --- BEGIN STRUCT8 VARIABLES ---
cat << 'EOFENV' > /etc/struct8_env
NAME="lab2-k6"
REGION="${data.aws_region.current.region}"
ACCOUNT="${data.aws_caller_identity.current.account_id}"
AWS_LB_DNSNAME_0="${aws_lb.lab2-alb.dns_name}"
EOFENV
cat /etc/struct8_env >> /etc/environment
sed 's/^/export /' /etc/struct8_env > /etc/profile.d/struct8_vars.sh
chmod +x /etc/profile.d/struct8_vars.sh
chmod 644 /etc/struct8_env
# --- END STRUCT8 VARIABLES ---


EOFUData
)
  vpc_security_group_ids = [aws_security_group.instance_lab2-k6_group.id]
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
    Name           = "lab2-k6"
    State          = "State"
    Struct8Creator = "Contato Struct"
  }
}

data "aws_ami" "AMI_Data_Source_lab2-ecs-lt" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-ecs-hvm-2023.*-kernel-6.1-arm64"]
  }
}

resource "aws_launch_template" "lab2-ecs-lt" {
  image_id               = data.aws_ami.AMI_Data_Source_lab2-ecs-lt.id
  name                   = "lab2-ecs-lt"
  instance_type          = "t4g.nano"
  update_default_version = true
  user_data = base64encode(<<-EOFUData
#!/bin/bash

# --- BEGIN STRUCT8 VARIABLES ---
cat << 'EOFENV' > /etc/struct8_env
NAME="lab2-ecs-asg"
REGION="${data.aws_region.current.region}"
ACCOUNT="${data.aws_caller_identity.current.account_id}"
EOFENV
cat /etc/struct8_env >> /etc/environment
sed 's/^/export /' /etc/struct8_env > /etc/profile.d/struct8_vars.sh
chmod +x /etc/profile.d/struct8_vars.sh
chmod 644 /etc/struct8_env
# --- END STRUCT8 VARIABLES ---

echo "ECS_CLUSTER=lab2-ecs-cluster" >> /etc/ecs/ecs.config
EOFUData
)
  vpc_security_group_ids = [aws_security_group.autoscaling_group_lab2-ecs-asg_group.id]
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      delete_on_termination = true
      encrypted             = true
      iops                  = 3000
      throughput            = 125
      volume_size           = 30
      volume_type           = "gp3"
    }
  }
  iam_instance_profile {
    name = aws_iam_instance_profile.lab2-ecs-asg_profile.name
  }
  metadata_options {
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 1
    http_tokens                 = "required"
  }
  tag_specifications {
    resource_type = "volume"
    tags = {
    Name           = "lab2-ecs-asg"
    State          = "State"
    Struct8Creator = "Contato Struct"
  }
  }
  tags = {
    Name           = "lab2-ecs-lt"
    State          = "State"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_autoscaling_group" "lab2-ecs-asg" {
  name                    = "lab2-ecs-asg"
  default_instance_warmup = 0
  desired_capacity        = 1
  health_check_type       = "EC2"
  max_instance_lifetime   = 0
  max_size                = 3
  metrics_granularity     = "1Minute"
  min_elb_capacity        = 0
  min_size                = 1
  termination_policies    = ["Default"]
  vpc_zone_identifier     = [aws_subnet.lab2-private-a.id]
  wait_for_elb_capacity   = 0
  launch_template {
    version = aws_launch_template.lab2-ecs-lt.latest_version
    id      = aws_launch_template.lab2-ecs-lt.id
  }
  tag {
    key                 = "Name"
    propagate_at_launch = true
    value               = "lab2-ecs-asg"
  }
  tag {
    key                 = "State"
    propagate_at_launch = true
    value               = "State"
  }
  tag {
    key                 = "Struct8Creator"
    propagate_at_launch = true
    value               = "Contato Struct"
  }
}

resource "aws_appautoscaling_policy" "lab2-hub-cpu" {
  name               = "lab2-hub-cpu"
  resource_id        = aws_appautoscaling_target.lab2-hub-scale.resource_id
  policy_type        = "TargetTrackingScaling"
  scalable_dimension = aws_appautoscaling_target.lab2-hub-scale.scalable_dimension
  service_namespace  = aws_appautoscaling_target.lab2-hub-scale.service_namespace
  target_tracking_scaling_policy_configuration {
    disable_scale_in   = false
    scale_in_cooldown  = 120
    scale_out_cooldown = 60
    target_value       = 50
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}

resource "aws_appautoscaling_target" "lab2-hub-scale" {
  resource_id        = "service/${aws_ecs_cluster.lab2-ecs-cluster.name}/${aws_ecs_service.lab2-hub_service.name}"
  max_capacity       = 4
  min_capacity       = 1
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
  tags = {
    Name           = "lab2-hub-scale"
    State          = "State"
    Struct8Creator = "Contato Struct"
  }
}




### CATEGORY: CONTAINERS ###

resource "aws_ecr_repository" "lab2-hub-ecr" {
  name                 = "lab2-hub-ecr"
  force_delete         = true
  image_tag_mutability = "MUTABLE"
  tags = {
    Name           = "lab2-hub-ecr"
    State          = "State"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_ecs_capacity_provider" "lab2-ec2-cp" {
  name = "lab2-ec2-cp"
  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.lab2-ecs-asg.arn
    managed_draining               = "ENABLED"
    managed_termination_protection = "DISABLED"
    managed_scaling {
      instance_warmup_period    = 300
      maximum_scaling_step_size = 10000
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 100
    }
  }
  tags = {
    Name           = "lab2-ec2-cp"
    State          = "State"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_ecs_cluster" "lab2-ecs-cluster" {
  name = "lab2-ecs-cluster"
  tags = {
    Name           = "lab2-ecs-cluster"
    State          = "State"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_ecs_cluster_capacity_providers" "assoc_cp_to_lab2-ecs-cluster" {
  cluster_name       = aws_ecs_cluster.lab2-ecs-cluster.name
  capacity_providers = [aws_ecs_capacity_provider.lab2-ec2-cp.name]
}

resource "aws_ecs_service" "lab2-hub_service" {
  name                    = "lab2-hub_service"
  cluster                 = aws_ecs_cluster.lab2-ecs-cluster.id
  desired_count           = 1
  enable_ecs_managed_tags = true
  force_delete            = true
  scheduling_strategy     = "REPLICA"
  task_definition         = "${aws_ecs_task_definition.lab2-hub.family}:${aws_ecs_task_definition.lab2-hub.revision}"
  capacity_provider_strategy {
    base              = 0
    capacity_provider = aws_ecs_capacity_provider.lab2-ec2-cp.name
    weight            = 1
  }
  lifecycle {
    ignore_changes = [desired_count]
  }
  load_balancer {
    container_name   = "hub"
    container_port   = 8080
    target_group_arn = aws_lb_target_group.lab2-tg-hub.arn
  }
  tags = {
    Name           = "lab2-hub_service"
    State          = "State"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [terraform_data.seed_lab2-hub-ecr]
}

locals {
  container_def_lab2-hub_hub = {
    name      = "hub"
    image     = "${aws_ecr_repository.lab2-hub-ecr.repository_url}:latest"
    essential = true
    cpu       = 128
    memory    = 200
    portMappings = [
      {
        protocol      = "tcp"
        containerPort = 8080
      }
    ]
    environment = [
      {
        name  = "NAME"
        value = "lab2-hub"
      },
      {
        name  = "REGION"
        value = data.aws_region.current.region
      },
      {
        name  = "ACCOUNT"
        value = data.aws_caller_identity.current.account_id
      },
      {
        name  = "AWS_ECS_CAPACITY_PROVIDER_NAME_0"
        value = "lab2-ec2-cp"
      }
    ]
    mountPoints            = []
    systemControls         = []
    volumesFrom            = []
    privileged             = false
    readonlyRootFilesystem = false
  }
}

resource "aws_ecs_task_definition" "lab2-hub" {
  container_definitions    = jsonencode([local.container_def_lab2-hub_hub])
  cpu                      = "128"
  execution_role_arn       = aws_iam_role.execution_role_ecs_lab2-hub.arn
  family                   = "lab2-nginx"
  memory                   = "350"
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]
  task_role_arn            = aws_iam_role.task_role_ecs_lab2-hub.arn
  tags = {
    Name           = "lab2-hub"
    State          = "State"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_iam_role_policy_attachment.ecs_task_definition_lab2-hub_execution_st_State_attach]
}




### CATEGORY: MISC ###

resource "null_resource" "cleanup_lab2-ecs-cluster" {
  triggers = {
    cluster_name = aws_ecs_cluster.lab2-ecs-cluster.name
  }
  depends_on = [aws_ecs_cluster.lab2-ecs-cluster, aws_autoscaling_group.lab2-ecs-asg, aws_ecs_capacity_provider.lab2-ec2-cp]
  provisioner "local-exec" {
    command = <<EOF

        CLUSTER="${self.triggers.cluster_name}"
        REGION="us-west-2"

        echo "ECS cleanup: cluster $CLUSTER in $REGION"

        # WHICH AUTO SCALING GROUPS. Two answers, because either source can be the
        # one that is missing.
        #
        # The names the diagram declares come first, written here as literals at
        # compile time. A destroy provisioner may only read `self`, so a reference
        # is not available -- and a re-run is exactly when that matters: a destroy
        # that failed half way leaves the group in the state with the ECS cluster
        # already gone, and a cluster is what the second source needs. Measured on
        # 2026-09-14, the third destroy of loadtest-ecs-ec2: `list-clusters` came
        # back empty while hub-ecs-asg still held two instances.
        #
        # The second source covers the group the diagram cannot name as a literal
        # -- a name built by the provider, or one the account answers.
        ASGS="lab2-ecs-asg"
        CI_ARNS=$(aws ecs list-container-instances --cluster "$CLUSTER" --region "$REGION" --query "containerInstanceArns[]" --output text 2>/dev/null)
        if [ -n "$CI_ARNS" ] && [ "$CI_ARNS" != "None" ]; then
            EC2_IDS=$(echo "$CI_ARNS" | tr '\t' '\n' | xargs -r -n 100 aws ecs describe-container-instances --cluster "$CLUSTER" --region "$REGION" --query "containerInstances[].ec2InstanceId" --output text --container-instances 2>/dev/null)
            if [ -n "$EC2_IDS" ] && [ "$EC2_IDS" != "None" ]; then
                DESCOBERTOS=$(echo "$EC2_IDS" | tr '\t' '\n' | xargs -r -n 50 aws autoscaling describe-auto-scaling-instances --region "$REGION" --query "AutoScalingInstances[].AutoScalingGroupName" --output text --instance-ids 2>/dev/null)
                ASGS=$(printf '%s\n%s\n' "$ASGS" "$DESCOBERTOS" | tr '\t' '\n' | sed '/^$/d' | sort -u)
            fi
        fi
        echo "ECS cleanup: auto scaling groups behind this cluster: $ASGS"

        # 1. SERVICES DOWN. Terraform deletes them too, and correctly; this is
        # the safeguard for the run where its own delete is what is stuck.
        SERVICES=$(aws ecs list-services --cluster "$CLUSTER" --region "$REGION" --query "serviceArns[]" --output text 2>/dev/null)
        if [ -n "$SERVICES" ] && [ "$SERVICES" != "None" ]; then
            for SERVICE in $SERVICES; do
                echo "ECS cleanup: scaling down $SERVICE"
                aws ecs update-service --cluster "$CLUSTER" --region "$REGION" --service "$SERVICE" --desired-count 0 >/dev/null 2>&1
            done
            for SERVICE in $SERVICES; do
                echo "ECS cleanup: deleting $SERVICE"
                aws ecs delete-service --cluster "$CLUSTER" --region "$REGION" --service "$SERVICE" --force >/dev/null 2>&1
            done
        fi

        # 2. TASKS STOPPED, so managed draining has nothing left to wait for.
        TASKS=$(aws ecs list-tasks --cluster "$CLUSTER" --region "$REGION" --query "taskArns[]" --output text 2>/dev/null)
        if [ -n "$TASKS" ] && [ "$TASKS" != "None" ]; then
            for TASK in $TASKS; do
                echo "ECS cleanup: stopping task $TASK"
                aws ecs stop-task --cluster "$CLUSTER" --region "$REGION" --task "$TASK" >/dev/null 2>&1
            done
        fi

        # 3. THE GROUPS TO ZERO, while the capacity provider still exists. This
        # is the step the old script never had, and the only one that makes an
        # EC2 instance leave.
        for ASG in $ASGS; do
            IDS=$(aws autoscaling describe-auto-scaling-groups --region "$REGION" --auto-scaling-group-names "$ASG" --query "AutoScalingGroups[0].Instances[].InstanceId" --output text 2>/dev/null)
            if [ -n "$IDS" ] && [ "$IDS" != "None" ]; then
                echo "$IDS" | tr '\t' '\n' | xargs -r -n 50 aws autoscaling set-instance-protection --region "$REGION" --auto-scaling-group-name "$ASG" --no-protected-from-scale-in --instance-ids >/dev/null 2>&1
            fi
            echo "ECS cleanup: taking $ASG to zero"
            aws autoscaling update-auto-scaling-group --region "$REGION" --auto-scaling-group-name "$ASG" --min-size 0 --max-size 0 --desired-capacity 0 >/dev/null 2>&1
        done

        # 4. WAIT ON THE ASG'S OWN INSTANCE LIST. Five minutes, bounded, and
        # Terraform's own 10m wait still follows -- this is not the last word.
        # From the third round on, release whatever is parked in
        # Terminating:Wait -- the tasks are gone by now, so the hook is holding
        # an instance for a drain that has nothing to drain.
        if [ -n "$ASGS" ]; then
            DEADLINE=$(( $(date +%s) + 300 ))
            ROUND=0
            while [ "$(date +%s)" -lt "$DEADLINE" ]; do
                ROUND=$(( ROUND + 1 ))
                LEFT=0
                for ASG in $ASGS; do
                    COUNT=$(aws autoscaling describe-auto-scaling-groups --region "$REGION" --auto-scaling-group-names "$ASG" --query "length(AutoScalingGroups[0].Instances)" --output text 2>/dev/null)
                    case "$COUNT" in ''|*[!0-9]*) COUNT=0 ;; esac
                    LEFT=$(( LEFT + COUNT ))

                    if [ "$COUNT" -gt 0 ] && [ "$ROUND" -ge 3 ]; then
                        WAITING=$(aws autoscaling describe-auto-scaling-groups --region "$REGION" --auto-scaling-group-names "$ASG" --query "AutoScalingGroups[0].Instances[?LifecycleState=='Terminating:Wait'].InstanceId" --output text 2>/dev/null)
                        if [ -n "$WAITING" ] && [ "$WAITING" != "None" ]; then
                            HOOKS=$(aws autoscaling describe-lifecycle-hooks --region "$REGION" --auto-scaling-group-name "$ASG" --query "LifecycleHooks[?LifecycleTransition=='autoscaling:EC2_INSTANCE_TERMINATING'].LifecycleHookName" --output text 2>/dev/null)
                            for HOOK in $HOOKS; do
                                for ID in $WAITING; do
                                    echo "ECS cleanup: releasing $ID from hook $HOOK on $ASG"
                                    aws autoscaling complete-lifecycle-action --region "$REGION" --auto-scaling-group-name "$ASG" --lifecycle-hook-name "$HOOK" --instance-id "$ID" --lifecycle-action-result CONTINUE >/dev/null 2>&1
                                done
                            done
                        fi
                    fi
                done

                if [ "$LEFT" -eq 0 ]; then
                    echo "ECS cleanup: groups are empty"
                    break
                fi
                echo "ECS cleanup: $LEFT instance(s) still in the group(s)"
                sleep 10
            done
        fi

        # 5. DEREGISTER WHAT IS LEFT. Last, and as a tidy-up only: this is what
        # the old script led with, and it empties the ECS list without moving a
        # single machine.
        CI_LEFT=$(aws ecs list-container-instances --cluster "$CLUSTER" --region "$REGION" --query "containerInstanceArns[]" --output text 2>/dev/null)
        if [ -n "$CI_LEFT" ] && [ "$CI_LEFT" != "None" ]; then
            for INSTANCE_ARN in $CI_LEFT; do
                echo "ECS cleanup: deregistering $INSTANCE_ARN"
                aws ecs deregister-container-instance --cluster "$CLUSTER" --region "$REGION" --container-instance "$INSTANCE_ARN" --force >/dev/null 2>&1
            done
        fi

        exit 0
        
  EOF
    interpreter = ["/bin/bash", "-c"]
    when        = "destroy"
  }
}

resource "terraform_data" "seed_lab2-hub-ecr" {
  triggers_replace = ["${path.module}/.external_modules/struct8-templates/templates/ec2-hub-docker/v1/image", "latest"]
  lifecycle {
    replace_triggered_by = [aws_ecr_repository.lab2-hub-ecr]
  }
  depends_on = [aws_ecr_repository.lab2-hub-ecr]
  provisioner "local-exec" {
    command = <<EOF
set -e
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin ${split("/", aws_ecr_repository.lab2-hub-ecr.repository_url)[0]}
docker build -t ${aws_ecr_repository.lab2-hub-ecr.repository_url}:latest ${path.module}/.external_modules/struct8-templates/templates/ec2-hub-docker/v1/image
docker push ${aws_ecr_repository.lab2-hub-ecr.repository_url}:latest
  EOF
    interpreter = ["/bin/bash", "-c"]
  }
}


