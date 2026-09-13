terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  backend "s3" {
    bucket  = "struct8-import"
    key     = "952133486861/loadtest-ecs-fargate/main.tfstate"
    region  = "us-west-2"
    encrypt = true
  }
}

# --- Main Cloud Provider ---
provider "aws" {
  region = "us-east-1"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

### CATEGORY: IAM ###

resource "aws_iam_instance_profile" "nat-a1_profile" {
  name = "nat-a1_profile"
  role = aws_iam_role.nat-a1_role.name
  tags = {
    Name           = "nat-a1_profile"
    State          = "loadtest-ecs-fargate"
    Struct8Creator = "Contato Struct"
  }
}

data "aws_iam_policy_document" "ecs_task_definition_hub_execution_st_loadtest-ecs-fargate_doc" {
  statement {
    sid       = "AllowWriteLogs"
    effect    = "Allow"
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.logs-target.arn}:*"]
  }
  statement {
    sid       = "AllowPullFromRepo"
    effect    = "Allow"
    actions   = ["ecr:BatchCheckLayerAvailability", "ecr:BatchGetImage", "ecr:GetDownloadUrlForLayer"]
    resources = [aws_ecr_repository.struct8-hub.arn]
  }
  statement {
    sid       = "AllowEcrAuth"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ecs_task_definition_hub_execution_st_loadtest-ecs-fargate" {
  name        = "ecs_task_definition_hub_execution_st_loadtest-ecs-fargate"
  description = "Access Policy for hub (Role: execution)"
  policy      = data.aws_iam_policy_document.ecs_task_definition_hub_execution_st_loadtest-ecs-fargate_doc.json
}

data "aws_iam_policy_document" "ecs_task_definition_k6_execution_st_loadtest-ecs-fargate_doc" {
  statement {
    sid       = "AllowWriteLogs"
    effect    = "Allow"
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.logs-tester.arn}:*"]
  }
}

resource "aws_iam_policy" "ecs_task_definition_k6_execution_st_loadtest-ecs-fargate" {
  name        = "ecs_task_definition_k6_execution_st_loadtest-ecs-fargate"
  description = "Access Policy for k6 (Role: execution)"
  policy      = data.aws_iam_policy_document.ecs_task_definition_k6_execution_st_loadtest-ecs-fargate_doc.json
}

resource "aws_iam_role" "execution_role_ecs_hub" {
  name = "execution_role_ecs_hub"
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
  force_detach_policies = false
  max_session_duration  = 3600
  path                  = "/"
  tags = {
    Name           = "execution_role_ecs_hub"
    State          = "loadtest-ecs-fargate"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "execution_role_ecs_k6" {
  name = "execution_role_ecs_k6"
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
  force_detach_policies = false
  max_session_duration  = 3600
  path                  = "/"
  tags = {
    Name           = "execution_role_ecs_k6"
    State          = "loadtest-ecs-fargate"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "nat-a1_role" {
  name = "nat-a1_role"
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
    Name           = "nat-a1_role"
    State          = "loadtest-ecs-fargate"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "task_role_ecs_hub" {
  name = "task_role_ecs_hub"
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
  force_detach_policies = false
  max_session_duration  = 3600
  path                  = "/"
  tags = {
    Name           = "task_role_ecs_hub"
    State          = "loadtest-ecs-fargate"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "task_role_ecs_k6" {
  name = "task_role_ecs_k6"
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
  force_detach_policies = false
  max_session_duration  = 3600
  path                  = "/"
  tags = {
    Name           = "task_role_ecs_k6"
    State          = "loadtest-ecs-fargate"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_definition_hub_execution_st_loadtest-ecs-fargate_attach" {
  policy_arn = aws_iam_policy.ecs_task_definition_hub_execution_st_loadtest-ecs-fargate.arn
  role       = aws_iam_role.execution_role_ecs_hub.name
}

resource "aws_iam_role_policy_attachment" "ecs_task_definition_k6_execution_st_loadtest-ecs-fargate_attach" {
  policy_arn = aws_iam_policy.ecs_task_definition_k6_execution_st_loadtest-ecs-fargate.arn
  role       = aws_iam_role.execution_role_ecs_k6.name
}




### CATEGORY: NETWORK ###

resource "aws_vpc" "ltfargate-vpc" {
  cidr_block           = "10.70.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default"
  tags = {
    Name           = "ltfargate-vpc"
    State          = "loadtest-ecs-fargate"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "private-hub-a" {
  vpc_id                  = aws_vpc.ltfargate-vpc.id
  availability_zone       = "us-east-1a"
  cidr_block              = "10.70.20.0/24"
  map_public_ip_on_launch = false
  tags = {
    Name           = "private-hub-a"
    State          = "loadtest-ecs-fargate"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "private-hub-b" {
  vpc_id                  = aws_vpc.ltfargate-vpc.id
  availability_zone       = "us-east-1b"
  cidr_block              = "10.70.21.0/24"
  map_public_ip_on_launch = false
  tags = {
    Name           = "private-hub-b"
    State          = "loadtest-ecs-fargate"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "public-alb-a" {
  vpc_id                  = aws_vpc.ltfargate-vpc.id
  availability_zone       = "us-east-1a"
  cidr_block              = "10.70.11.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name           = "public-alb-a"
    State          = "loadtest-ecs-fargate"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "public-alb-b" {
  vpc_id                  = aws_vpc.ltfargate-vpc.id
  availability_zone       = "us-east-1b"
  cidr_block              = "10.70.12.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name           = "public-alb-b"
    State          = "loadtest-ecs-fargate"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "public-k1" {
  vpc_id                  = aws_vpc.ltfargate-vpc.id
  availability_zone       = "us-east-1a"
  cidr_block              = "10.70.10.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name           = "public-k1"
    State          = "loadtest-ecs-fargate"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_internet_gateway" "ltfargate-igw" {
  vpc_id = aws_vpc.ltfargate-vpc.id
  tags = {
    Name           = "ltfargate-igw"
    State          = "loadtest-ecs-fargate"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route" "route_rt-private2_to_nat-a1_ipv4" {
  network_interface_id   = aws_instance.nat-a1.primary_network_interface_id
  route_table_id         = aws_route_table.rt-private2.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route" "route_rt-public2_to_ltfargate-igw_ipv4" {
  gateway_id             = aws_internet_gateway.ltfargate-igw.id
  route_table_id         = aws_route_table.rt-public2.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table" "rt-private2" {
  vpc_id = aws_vpc.ltfargate-vpc.id
  tags = {
    Name           = "rt-private2"
    State          = "loadtest-ecs-fargate"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route_table" "rt-public2" {
  vpc_id = aws_vpc.ltfargate-vpc.id
  tags = {
    Name           = "rt-public2"
    State          = "loadtest-ecs-fargate"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route_table_association" "aws_route_table_association_private_hub_a_rt_private2" {
  route_table_id = aws_route_table.rt-private2.id
  subnet_id      = aws_subnet.private-hub-a.id
}

resource "aws_route_table_association" "aws_route_table_association_private_hub_b_rt_private2" {
  route_table_id = aws_route_table.rt-private2.id
  subnet_id      = aws_subnet.private-hub-b.id
}

resource "aws_route_table_association" "aws_route_table_association_public_alb_a_rt_public2" {
  route_table_id = aws_route_table.rt-public2.id
  subnet_id      = aws_subnet.public-alb-a.id
}

resource "aws_route_table_association" "aws_route_table_association_public_alb_b_rt_public2" {
  route_table_id = aws_route_table.rt-public2.id
  subnet_id      = aws_subnet.public-alb-b.id
}

resource "aws_route_table_association" "aws_route_table_association_public_k1_rt_public2" {
  route_table_id = aws_route_table.rt-public2.id
  subnet_id      = aws_subnet.public-k1.id
}

resource "aws_security_group" "ecs_task_definition_hub_group" {
  name                   = "ecs_task_definition_hub_group"
  vpc_id                 = aws_vpc.ltfargate-vpc.id
  revoke_rules_on_delete = false
  tags = {
    Name           = "ecs_task_definition_hub_group"
    State          = "loadtest-ecs-fargate"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group" "ecs_task_definition_k6_group" {
  name                   = "ecs_task_definition_k6_group"
  vpc_id                 = aws_vpc.ltfargate-vpc.id
  revoke_rules_on_delete = false
  tags = {
    Name           = "ecs_task_definition_k6_group"
    State          = "loadtest-ecs-fargate"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group" "instance_nat-a1_group" {
  name                   = "instance_nat-a1_group"
  vpc_id                 = aws_vpc.ltfargate-vpc.id
  description            = "NAT instance SG. Must accept ALL traffic from the VPC CIDR (ingress -1 from 10.70.0.0/16) so it can forward/MASQUERADE the private Hub tasks egress to the internet (ECR image pull). Egress open."
  revoke_rules_on_delete = false
}

resource "aws_security_group" "lb_alb-hub1_group" {
  name                   = "lb_alb-hub1_group"
  vpc_id                 = aws_vpc.ltfargate-vpc.id
  description            = "ALB SG. Accepts HTTP :80 from anywhere: the k6 Fargate task is in a public subnet and reaches the ALB by its public IP, so traffic arrives from the public range, not the VPC CIDR. Egress open to reach the Hub tasks on :8080."
  revoke_rules_on_delete = false
}

resource "aws_security_group_rule" "rule_ecs_task_definition_hub_group_egress_all_protocols" {
  security_group_id = aws_security_group.ecs_task_definition_hub_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "rule_ecs_task_definition_k6_group_egress_all_protocols" {
  security_group_id = aws_security_group.ecs_task_definition_k6_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "rule_ecs_task_definition_k6_group_to_lb_alb_hub1_group_tcp_80" {
  security_group_id        = aws_security_group.lb_alb-hub1_group.id
  source_security_group_id = aws_security_group.ecs_task_definition_k6_group.id
  description              = "Allow from ecs_task_definition_k6_group (tcp:80-80)"
  from_port                = 80
  protocol                 = "tcp"
  to_port                  = 80
  type                     = "ingress"
}

resource "aws_security_group_rule" "rule_instance_nat_a1_group_egress_all_protocols" {
  security_group_id = aws_security_group.instance_nat-a1_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "rule_instance_nat_a1_group_ingress_all_protocols" {
  security_group_id = aws_security_group.instance_nat-a1_group.id
  cidr_blocks       = ["10.70.0.0/16"]
  description       = "NAT: all traffic from the VPC to be routed out"
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "ingress"
}

resource "aws_security_group_rule" "rule_lb_alb_hub1_group_egress_all_protocols" {
  security_group_id = aws_security_group.lb_alb-hub1_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "rule_lb_alb_hub1_group_ingress_tcp_80" {
  security_group_id = aws_security_group.lb_alb-hub1_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "HTTP from k6 (arrives by public IP)"
  from_port         = 80
  protocol          = "tcp"
  to_port           = 80
  type              = "ingress"
}

resource "aws_security_group_rule" "rule_lb_alb_hub1_group_to_ecs_task_definition_hub_group_tcp_8080" {
  security_group_id        = aws_security_group.ecs_task_definition_hub_group.id
  source_security_group_id = aws_security_group.lb_alb-hub1_group.id
  description              = "Allow from lb_alb-hub1_group (tcp:8080-8080)"
  from_port                = 8080
  protocol                 = "tcp"
  to_port                  = 8080
  type                     = "ingress"
}

resource "aws_lb" "alb-hub1" {
  name                             = "alb-hub1"
  enable_cross_zone_load_balancing = true
  idle_timeout                     = 60
  load_balancer_type               = "application"
  security_groups                  = [aws_security_group.lb_alb-hub1_group.id]
  subnets                          = [aws_subnet.public-alb-a.id, aws_subnet.public-alb-b.id]
  tags = {
    Name           = "alb-hub1"
    State          = "loadtest-ecs-fargate"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_lb_listener" "listener-http1" {
  load_balancer_arn                    = aws_lb.alb-hub1.arn
  port                                 = 80
  protocol                             = "HTTP"
  routing_http_response_server_enabled = true
  default_action {
    order            = 1
    target_group_arn = aws_lb_target_group.tg-hub1.arn
    type             = "forward"
    forward {
      target_group {
        arn = aws_lb_target_group.tg-hub1.arn
      }
    }
  }
  tags = {
    Name           = "listener-http1"
    State          = "loadtest-ecs-fargate"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_lb_target_group" "tg-hub1" {
  name                          = "tg-hub1"
  vpc_id                        = aws_vpc.ltfargate-vpc.id
  deregistration_delay          = "30"
  ip_address_type               = "ipv4"
  load_balancing_algorithm_type = "round_robin"
  port                          = 8080
  protocol                      = "HTTP"
  slow_start                    = 0
  target_type                   = "ip"
  health_check {
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200-399"
    path                = "/"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 3
  }
  tags = {
    Name           = "tg-hub1"
    State          = "loadtest-ecs-fargate"
    Struct8Creator = "Contato Struct"
  }
}




### CATEGORY: COMPUTE ###

data "local_file" "UserData_nat-a1" {
  filename = "${path.module}/.external_modules/struct8-templates/templates/ec2-nat-private/v1/user_data/Nat.sh"
}

data "aws_ami" "AMI_Data_Source_nat-a1" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-kernel-6.1-x86_64"]
  }
}

resource "aws_instance" "nat-a1" {
  subnet_id                   = aws_subnet.public-alb-b.id
  ami                         = data.aws_ami.AMI_Data_Source_nat-a1.id
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.nat-a1_profile.name
  instance_type               = "t3.nano"
  source_dest_check           = false
  user_data_base64 = base64encode(<<-EOFUData
#!/bin/bash

${data.local_file.UserData_nat-a1.content}
EOFUData
)
  user_data_replace_on_change = false
  vpc_security_group_ids      = [aws_security_group.instance_nat-a1_group.id]
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
    Name           = "nat-a1"
    State          = "loadtest-ecs-fargate"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_appautoscaling_policy" "hub-scale-cpu" {
  name               = "hub-scale-cpu"
  resource_id        = aws_appautoscaling_target.hub-scale-target.resource_id
  policy_type        = "TargetTrackingScaling"
  scalable_dimension = aws_appautoscaling_target.hub-scale-target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.hub-scale-target.service_namespace
  target_tracking_scaling_policy_configuration {
    scale_in_cooldown  = 120
    scale_out_cooldown = 60
    target_value       = 40
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}

resource "aws_appautoscaling_target" "hub-scale-target" {
  resource_id        = "service/${aws_ecs_cluster.ltfargate-target.name}/${aws_ecs_service.hub_1.name}"
  max_capacity       = 4
  min_capacity       = 1
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
  tags = {
    Name           = "hub-scale-target"
    State          = "loadtest-ecs-fargate"
    Struct8Creator = "Contato Struct"
  }
}




### CATEGORY: CONTAINERS ###

resource "aws_ecr_repository" "struct8-hub" {
  name                 = "struct8-hub"
  force_delete         = true
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
  tags = {
    Name           = "struct8-hub"
    State          = "loadtest-ecs-fargate"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_ecs_cluster" "ltfargate-target" {
  name = "ltfargate-target"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
  tags = {
    Name           = "ltfargate-target"
    State          = "loadtest-ecs-fargate"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_ecs_cluster" "ltfargate-tester" {
  name = "ltfargate-tester"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
  tags = {
    Name           = "ltfargate-tester"
    State          = "loadtest-ecs-fargate"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_ecs_service" "hub_1" {
  name                              = "hub"
  cluster                           = aws_ecs_cluster.ltfargate-target.id
  desired_count                     = 1
  enable_ecs_managed_tags           = true
  enable_execute_command            = true
  force_delete                      = true
  health_check_grace_period_seconds = 120
  launch_type                       = "FARGATE"
  scheduling_strategy               = "REPLICA"
  task_definition                   = "${aws_ecs_task_definition.hub.family}:${aws_ecs_task_definition.hub.revision}"
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }
  lifecycle {
    ignore_changes = [desired_count]
  }
  load_balancer {
    container_name   = "hub"
    container_port   = 8080
    target_group_arn = aws_lb_target_group.tg-hub1.arn
  }
  network_configuration {
    assign_public_ip = false
    security_groups  = [aws_security_group.ecs_task_definition_hub_group.id]
    subnets          = [aws_subnet.private-hub-a.id, aws_subnet.private-hub-b.id]
  }
  tags = {
    Name           = "hub_1"
    State          = "loadtest-ecs-fargate"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [terraform_data.seed_struct8-hub]
}

resource "aws_ecs_service" "k6_1" {
  name                               = "k6"
  cluster                            = aws_ecs_cluster.ltfargate-tester.id
  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 0
  desired_count                      = 1
  enable_ecs_managed_tags            = true
  enable_execute_command             = true
  force_delete                       = true
  launch_type                        = "FARGATE"
  scheduling_strategy                = "REPLICA"
  task_definition                    = "${aws_ecs_task_definition.k6.family}:${aws_ecs_task_definition.k6.revision}"
  network_configuration {
    assign_public_ip = true
    security_groups  = [aws_security_group.ecs_task_definition_k6_group.id]
    subnets          = [aws_subnet.public-k1.id]
  }
  tags = {
    Name           = "k6_1"
    State          = "loadtest-ecs-fargate"
    Struct8Creator = "Contato Struct"
  }
}

locals {
  container_def_hub_hub_2 = {
    name      = "hub"
    image     = "${aws_ecr_repository.struct8-hub.repository_url}:latest"
    essential = true
    cpu       = 256
    memory    = 512
    portMappings = [
      {
        protocol      = "tcp"
        containerPort = 8080
        hostPort      = 8080
      }
    ]
    environment = [
      {
        name  = "HUB_LOADTEST"
        value = "on"
      },
      {
        name  = "PORT"
        value = "8080"
      },
      {
        name  = "NAME"
        value = "hub"
      },
      {
        name  = "REGION"
        value = data.aws_region.current.region
      },
      {
        name  = "ACCOUNT"
        value = data.aws_caller_identity.current.account_id
      }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.logs-target.name
        awslogs-region        = "us-east-1"
        awslogs-stream-prefix = "hub"
      }
    }
    mountPoints    = []
    systemControls = []
    volumesFrom    = []
  }
}

resource "aws_ecs_task_definition" "hub" {
  container_definitions    = jsonencode([local.container_def_hub_hub_2])
  cpu                      = "256"
  execution_role_arn       = aws_iam_role.execution_role_ecs_hub.arn
  family                   = "hub"
  memory                   = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  task_role_arn            = aws_iam_role.task_role_ecs_hub.arn
  runtime_platform {
    cpu_architecture        = "X86_64"
    operating_system_family = "LINUX"
  }
  tags = {
    Name           = "hub"
    State          = "loadtest-ecs-fargate"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_iam_role_policy_attachment.ecs_task_definition_hub_execution_st_loadtest-ecs-fargate_attach]
}

locals {
  container_def_k6_k6_2 = {
    name      = "k6"
    image     = "grafana/k6:latest"
    essential = true
    cpu       = 256
    memory    = 512
    environment = [
      {
        name  = "STARTUP_DELAY"
        value = "60"
      },
      {
        name  = "DURATION"
        value = "20m"
      },
      {
        name  = "VUS"
        value = "30"
      },
      {
        name  = "METHOD"
        value = "POST"
      },
      {
        name  = "MS"
        value = "250"
      },
      {
        name  = "TARGET_URL"
        value = "http://${aws_lb.alb-hub1.dns_name}"
      },
      {
        name  = "NAME"
        value = "k6"
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
        name  = "AWS_LB_DNSNAME_0"
        value = aws_lb.alb-hub1.dns_name
      }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.logs-tester.name
        awslogs-region        = "us-east-1"
        awslogs-stream-prefix = "k6"
      }
    }
    mountPoints    = []
    systemControls = []
    volumesFrom    = []
    command = [
      <<EOF
echo "[k6] waiting $${STARTUP_DELAY}s for target warm-up"; sleep $${STARTUP_DELAY}; printf 'import http from "k6/http";\nimport { check } from "k6";\nconst URL = __ENV.TARGET_URL;\nconst METHOD = (__ENV.METHOD || "POST").toUpperCase();\nexport const options = { vus: Number(__ENV.VUS || 20), duration: __ENV.DURATION || "5m" };\nexport default function () {\n  const target = METHOD === "POST" ? URL + "/loadtest?ms=" + (__ENV.MS || "200") : URL;\n  const res = METHOD === "POST" ? http.post(target, null) : http.get(target);\n  check(res, { "ok": (r) => r.status >= 200 && r.status < 400 });\n}\n' > /tmp/load.js; k6 run /tmp/load.js
      EOF
    ]
    entryPoint = ["/bin/sh", "-c"]
  }
}

resource "aws_ecs_task_definition" "k6" {
  container_definitions    = jsonencode([local.container_def_k6_k6_2])
  cpu                      = "256"
  execution_role_arn       = aws_iam_role.execution_role_ecs_k6.arn
  family                   = "k6"
  memory                   = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  task_role_arn            = aws_iam_role.task_role_ecs_k6.arn
  runtime_platform {
    cpu_architecture        = "X86_64"
    operating_system_family = "LINUX"
  }
  tags = {
    Name           = "k6"
    State          = "loadtest-ecs-fargate"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_iam_role_policy_attachment.ecs_task_definition_k6_execution_st_loadtest-ecs-fargate_attach]
}




### CATEGORY: MONITORING ###

resource "aws_cloudwatch_log_group" "logs-target" {
  name              = "/ecs/ltfargate-hub"
  log_group_class   = "STANDARD"
  retention_in_days = 7
  skip_destroy      = false
  tags = {
    Name           = "logs-target"
    State          = "loadtest-ecs-fargate"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_cloudwatch_log_group" "logs-tester" {
  name              = "/ecs/ltfargate-k6"
  log_group_class   = "STANDARD"
  retention_in_days = 7
  skip_destroy      = false
  tags = {
    Name           = "logs-tester"
    State          = "loadtest-ecs-fargate"
    Struct8Creator = "Contato Struct"
  }
}




### CATEGORY: MISC ###

resource "terraform_data" "seed_struct8-hub" {
  triggers_replace = ["${path.module}/.external_modules/struct8-hub/image", "latest"]
  lifecycle {
    replace_triggered_by = [aws_ecr_repository.struct8-hub]
  }
  depends_on = [aws_ecr_repository.struct8-hub]
  provisioner "local-exec" {
    command = <<EOF
set -e
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ${split("/", aws_ecr_repository.struct8-hub.repository_url)[0]}
docker build -t ${aws_ecr_repository.struct8-hub.repository_url}:latest ${path.module}/.external_modules/struct8-hub/image
docker push ${aws_ecr_repository.struct8-hub.repository_url}:latest
  EOF
    interpreter = ["/bin/bash", "-c"]
  }
}


