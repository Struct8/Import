terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  backend "s3" {
    bucket  = "struct8-import"
    key     = "952133486861/ecs-asg-state/main.tfstate"
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

resource "aws_iam_instance_profile" "ecs-asg-k6_profile" {
  name = "ecs-asg-k6_profile"
  role = aws_iam_role.ecs-asg-k6_role.name
  tags = {
    Name           = "ecs-asg-k6_profile"
    State          = "ecs-asg-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_instance_profile" "ecs-asg-nat-instance_profile" {
  name = "ecs-asg-nat-instance_profile"
  role = aws_iam_role.ecs-asg-nat-instance_role.name
  tags = {
    Name           = "ecs-asg-nat-instance_profile"
    State          = "ecs-asg-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_instance_profile" "ecs-asg-nodes_profile" {
  name = "ecs-asg-nodes_profile"
  role = aws_iam_role.ecs-asg-nodes_role.name
  tags = {
    Name           = "ecs-asg-nodes_profile"
    State          = "ecs-asg-state"
    Struct8Creator = "Contato Struct"
  }
}

data "aws_iam_policy_document" "autoscaling_group_ecs-asg-nodes_st_ecs-asg-state_doc" {
  statement {
    sid       = "AllowEcsasgcluster"
    effect    = "Allow"
    actions   = ["ecs:DeregisterContainerInstance", "ecs:DiscoverPollEndpoint", "ecs:Poll", "ecs:RegisterContainerInstance", "ecs:StartTelemetrySession", "ecs:Submit*"]
    resources = [aws_ecs_cluster.ecs-asg-cluster.arn]
  }
}

resource "aws_iam_policy" "autoscaling_group_ecs-asg-nodes_st_ecs-asg-state" {
  name        = "autoscaling_group_ecs-asg-nodes_st_ecs-asg-state"
  description = "Access Policy for ecs-asg-nodes"
  policy      = data.aws_iam_policy_document.autoscaling_group_ecs-asg-nodes_st_ecs-asg-state_doc.json
}

data "aws_iam_policy_document" "ecs_task_definition_ecs-asg-hub_execution_st_ecs-asg-state_doc" {
  statement {
    sid       = "AllowPullFromRepo"
    effect    = "Allow"
    actions   = ["ecr:BatchCheckLayerAvailability", "ecr:BatchGetImage", "ecr:GetDownloadUrlForLayer"]
    resources = [aws_ecr_repository.ecs-asg-hub-ecr.arn]
  }
  statement {
    sid       = "AllowEcrAuth"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ecs_task_definition_ecs-asg-hub_execution_st_ecs-asg-state" {
  name        = "ecs_task_definition_ecs-asg-hub_execution_st_ecs-asg-state"
  description = "Access Policy for ecs-asg-hub (Role: execution)"
  policy      = data.aws_iam_policy_document.ecs_task_definition_ecs-asg-hub_execution_st_ecs-asg-state_doc.json
}

data "aws_iam_policy_document" "Debug1_debug_permissions" {
  statement {
    sid       = "SendToTaggedInstancesOnly"
    effect    = "Allow"
    actions   = ["ssm:SendCommand"]
    resources = ["arn:aws:ec2:*:*:instance/*"]
    condition {
      test     = "StringEquals"
      values   = ["GZLb18DbqWCTitZ4B6eSJ"]
      variable = "aws:ResourceTag/Struct8Debug"
    }
  }
  statement {
    sid       = "PinnedDocumentOnly"
    effect    = "Allow"
    actions   = ["ssm:SendCommand"]
    resources = ["arn:aws:ssm:*::document/AWS-RunShellScript"]
  }
  statement {
    sid       = "ReadOwnResults"
    effect    = "Allow"
    actions   = ["ssm:GetCommandInvocation", "ssm:DescribeInstanceInformation"]
    resources = ["*"]
  }
  statement {
    sid       = "CancelOnTaggedInstancesOnly"
    effect    = "Allow"
    actions   = ["ssm:CancelCommand"]
    resources = ["arn:aws:ec2:*:*:instance/*"]
    condition {
      test     = "StringEquals"
      values   = ["GZLb18DbqWCTitZ4B6eSJ"]
      variable = "aws:ResourceTag/Struct8Debug"
    }
  }
  statement {
    sid       = "RunShellScriptDocument"
    effect    = "Allow"
    actions   = ["ssm:SendCommand"]
    resources = ["arn:aws:ssm:*::document/AWS-RunShellScript"]
  }
}

data "aws_iam_policy_document" "Debug1_debug_trust" {
  statement {
    effect = "Allow"
    principals {
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/CrossAccountStruct8"]
      type        = "AWS"
    }
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "ecs-asg-k6-debug_debug_permissions" {
  statement {
    sid       = "SendToTaggedInstancesOnly"
    effect    = "Allow"
    actions   = ["ssm:SendCommand"]
    resources = ["arn:aws:ec2:*:*:instance/*"]
    condition {
      test     = "StringEquals"
      values   = ["f782657a-f005-4abb-aaea-eb2e8af8af58"]
      variable = "aws:ResourceTag/Struct8Debug"
    }
  }
  statement {
    sid       = "PinnedDocumentOnly"
    effect    = "Allow"
    actions   = ["ssm:SendCommand"]
    resources = ["arn:aws:ssm:*:${data.aws_caller_identity.current.account_id}:document/Struct8Probe-f782657a-f005-4abb-aaea-eb2e8af8af58"]
  }
  statement {
    sid       = "ReadOwnResults"
    effect    = "Allow"
    actions   = ["ssm:GetCommandInvocation", "ssm:DescribeInstanceInformation"]
    resources = ["*"]
  }
  statement {
    sid       = "CancelOnTaggedInstancesOnly"
    effect    = "Allow"
    actions   = ["ssm:CancelCommand"]
    resources = ["arn:aws:ec2:*:*:instance/*"]
    condition {
      test     = "StringEquals"
      values   = ["f782657a-f005-4abb-aaea-eb2e8af8af58"]
      variable = "aws:ResourceTag/Struct8Debug"
    }
  }
}

data "aws_iam_policy_document" "ecs-asg-k6-debug_debug_trust" {
  statement {
    effect = "Allow"
    principals {
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/CrossAccountStruct8"]
      type        = "AWS"
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "Struct8Debug-Debug1" {
  name                 = "Struct8Debug-GZLb18DbqWCTitZ4B6eSJ"
  assume_role_policy   = data.aws_iam_policy_document.Debug1_debug_trust.json
  max_session_duration = 3600
}

resource "aws_iam_role" "Struct8Debug-ecs-asg-k6-debug" {
  name                 = "Struct8Debug-f782657a-f005-4abb-aaea-eb2e8af8af58"
  assume_role_policy   = data.aws_iam_policy_document.ecs-asg-k6-debug_debug_trust.json
  max_session_duration = 3600
}

resource "aws_iam_role" "ecs-asg-k6_role" {
  name = "ecs-asg-k6_role"
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
    Name           = "ecs-asg-k6_role"
    State          = "ecs-asg-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "ecs-asg-nat-instance_role" {
  name = "ecs-asg-nat-instance_role"
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
    Name           = "ecs-asg-nat-instance_role"
    State          = "ecs-asg-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "ecs-asg-nodes_role" {
  name = "ecs-asg-nodes_role"
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
    Name           = "ecs-asg-nodes_role"
    State          = "ecs-asg-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "execution_role_ecs_ecs-asg-hub" {
  name = "execution_role_ecs_ecs-asg-hub"
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
    Name           = "execution_role_ecs_ecs-asg-hub"
    State          = "ecs-asg-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "task_role_ecs_ecs-asg-hub" {
  name = "task_role_ecs_ecs-asg-hub"
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
    Name           = "task_role_ecs_ecs-asg-hub"
    State          = "ecs-asg-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role_policy" "Struct8Debug-Debug1_policy" {
  name   = "Struct8Debug-GZLb18DbqWCTitZ4B6eSJ-policy"
  policy = data.aws_iam_policy_document.Debug1_debug_permissions.json
  role   = aws_iam_role.Struct8Debug-Debug1.id
}

resource "aws_iam_role_policy" "Struct8Debug-ecs-asg-k6-debug_policy" {
  name   = "Struct8Debug-f782657a-f005-4abb-aaea-eb2e8af8af58-policy"
  policy = data.aws_iam_policy_document.ecs-asg-k6-debug_debug_permissions.json
  role   = aws_iam_role.Struct8Debug-ecs-asg-k6-debug.id
}

resource "aws_iam_role_policy_attachment" "AmazonSSMManagedInstanceCore_to_ecs-asg-k6_attach" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.ecs-asg-k6_role.name
}

resource "aws_iam_role_policy_attachment" "AmazonSSMManagedInstanceCore_to_ecs-asg-nat-instance_attach" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.ecs-asg-nat-instance_role.name
}

resource "aws_iam_role_policy_attachment" "autoscaling_group_ecs-asg-nodes_st_ecs-asg-state_attach" {
  policy_arn = aws_iam_policy.autoscaling_group_ecs-asg-nodes_st_ecs-asg-state.arn
  role       = aws_iam_role.ecs-asg-nodes_role.name
}

resource "aws_iam_role_policy_attachment" "ecs_task_definition_ecs-asg-hub_execution_st_ecs-asg-state_attach" {
  policy_arn = aws_iam_policy.ecs_task_definition_ecs-asg-hub_execution_st_ecs-asg-state.arn
  role       = aws_iam_role.execution_role_ecs_ecs-asg-hub.name
}

resource "aws_iam_role_policy_attachment" "service_role_AmazonEC2ContainerServiceforEC2Role_to_ecs-asg-nodes_attach" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
  role       = aws_iam_role.ecs-asg-nodes_role.name
}




### CATEGORY: NETWORK ###

resource "aws_vpc" "ecs-asg-vpc" {
  cidr_block       = "10.6.0.0/16"
  instance_tenancy = "default"
  tags = {
    Name           = "ecs-asg-vpc"
    State          = "ecs-asg-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "ecs-asg-private-a" {
  vpc_id                  = aws_vpc.ecs-asg-vpc.id
  availability_zone       = "us-west-2a"
  cidr_block              = "10.6.1.0/24"
  map_public_ip_on_launch = false
  tags = {
    Name           = "ecs-asg-private-a"
    State          = "ecs-asg-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "ecs-asg-private-b" {
  vpc_id                  = aws_vpc.ecs-asg-vpc.id
  availability_zone       = "us-west-2b"
  cidr_block              = "10.6.3.0/24"
  map_public_ip_on_launch = false
  tags = {
    Name           = "ecs-asg-private-b"
    State          = "ecs-asg-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "ecs-asg-public-a" {
  vpc_id                  = aws_vpc.ecs-asg-vpc.id
  availability_zone       = "us-west-2a"
  cidr_block              = "10.6.0.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name           = "ecs-asg-public-a"
    State          = "ecs-asg-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "ecs-asg-public-b" {
  vpc_id                  = aws_vpc.ecs-asg-vpc.id
  availability_zone       = "us-west-2b"
  cidr_block              = "10.6.2.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name           = "ecs-asg-public-b"
    State          = "ecs-asg-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_internet_gateway" "ecs-asg-igw" {
  vpc_id = aws_vpc.ecs-asg-vpc.id
  tags = {
    Name           = "ecs-asg-igw"
    State          = "ecs-asg-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route" "route_ecs-asg-rtb-private_to_ecs-asg-nat-instance_ipv4" {
  network_interface_id   = aws_instance.ecs-asg-nat-instance.primary_network_interface_id
  route_table_id         = aws_route_table.ecs-asg-rtb-private.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route" "route_ecs-asg-rtb-public_to_ecs-asg-igw_ipv4" {
  gateway_id             = aws_internet_gateway.ecs-asg-igw.id
  route_table_id         = aws_route_table.ecs-asg-rtb-public.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table" "ecs-asg-rtb-private" {
  vpc_id = aws_vpc.ecs-asg-vpc.id
  tags = {
    Name           = "ecs-asg-rtb-private"
    State          = "ecs-asg-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route_table" "ecs-asg-rtb-public" {
  vpc_id = aws_vpc.ecs-asg-vpc.id
  tags = {
    Name           = "ecs-asg-rtb-public"
    State          = "ecs-asg-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route_table_association" "aws_route_table_association_ecs_asg_private_a_ecs_asg_rtb_private" {
  route_table_id = aws_route_table.ecs-asg-rtb-private.id
  subnet_id      = aws_subnet.ecs-asg-private-a.id
}

resource "aws_route_table_association" "aws_route_table_association_ecs_asg_private_b_ecs_asg_rtb_private" {
  route_table_id = aws_route_table.ecs-asg-rtb-private.id
  subnet_id      = aws_subnet.ecs-asg-private-b.id
}

resource "aws_route_table_association" "aws_route_table_association_ecs_asg_public_a_ecs_asg_rtb_public" {
  route_table_id = aws_route_table.ecs-asg-rtb-public.id
  subnet_id      = aws_subnet.ecs-asg-public-a.id
}

resource "aws_route_table_association" "aws_route_table_association_ecs_asg_public_b_ecs_asg_rtb_public" {
  route_table_id = aws_route_table.ecs-asg-rtb-public.id
  subnet_id      = aws_subnet.ecs-asg-public-b.id
}

resource "aws_security_group" "autoscaling_group_ecs-asg-nodes_group" {
  name                   = "autoscaling_group_ecs-asg-nodes_group"
  vpc_id                 = aws_vpc.ecs-asg-vpc.id
  revoke_rules_on_delete = false
  tags = {
    Name           = "autoscaling_group_ecs-asg-nodes_group"
    State          = "ecs-asg-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group" "instance_ecs-asg-k6_group" {
  name                   = "instance_ecs-asg-k6_group"
  vpc_id                 = aws_vpc.ecs-asg-vpc.id
  revoke_rules_on_delete = false
  tags = {
    Name           = "instance_ecs-asg-k6_group"
    State          = "ecs-asg-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group" "instance_ecs-asg-nat-instance_group" {
  name                   = "instance_ecs-asg-nat-instance_group"
  vpc_id                 = aws_vpc.ecs-asg-vpc.id
  description            = "NAT instance: allow all traffic from inside the VPC, egress anywhere"
  revoke_rules_on_delete = false
  tags = {
    Name           = "instance_ecs-asg-nat-instance_group"
    State          = "ecs-asg-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group" "lb_ecs-asg-alb_group" {
  name                   = "lb_ecs-asg-alb_group"
  vpc_id                 = aws_vpc.ecs-asg-vpc.id
  revoke_rules_on_delete = false
  tags = {
    Name           = "lb_ecs-asg-alb_group"
    State          = "ecs-asg-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group_rule" "rule_autoscaling_group_ecs_asg_nodes_group_egress_all_protocols" {
  security_group_id = aws_security_group.autoscaling_group_ecs-asg-nodes_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "rule_autoscaling_group_ecs_asg_nodes_group_ingress_tcp_80" {
  security_group_id = aws_security_group.autoscaling_group_ecs-asg-nodes_group.id
  cidr_blocks       = ["10.6.0.0/16"]
  description       = "HTTP interno da VPC (teste via NAT)"
  from_port         = 80
  protocol          = "tcp"
  to_port           = 80
  type              = "ingress"
}

resource "aws_security_group_rule" "rule_instance_ecs_asg_k6_group_egress_all_protocols" {
  security_group_id = aws_security_group.instance_ecs-asg-k6_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "rule_instance_ecs_asg_k6_group_ingress_tcp_5665" {
  security_group_id = aws_security_group.instance_ecs-asg-k6_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "k6 live dashboard (teaching lab)"
  from_port         = 5665
  protocol          = "tcp"
  to_port           = 5665
  type              = "ingress"
}

resource "aws_security_group_rule" "rule_instance_ecs_asg_k6_group_ingress_tcp_80" {
  security_group_id = aws_security_group.instance_ecs-asg-k6_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "k6 control panel (teaching lab)"
  from_port         = 80
  protocol          = "tcp"
  to_port           = 80
  type              = "ingress"
}

resource "aws_security_group_rule" "rule_instance_ecs_asg_nat_instance_group_egress_all_protocols" {
  security_group_id = aws_security_group.instance_ecs-asg-nat-instance_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "rule_instance_ecs_asg_nat_instance_group_ingress_all_protocols" {
  security_group_id = aws_security_group.instance_ecs-asg-nat-instance_group.id
  cidr_blocks       = ["10.6.0.0/16"]
  description       = "All traffic from within VPC2 (private subnets route through here)"
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "ingress"
}

resource "aws_security_group_rule" "rule_lb_ecs_asg_alb_group_egress_all_protocols" {
  security_group_id = aws_security_group.lb_ecs-asg-alb_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "rule_lb_ecs_asg_alb_group_ingress_tcp_80" {
  security_group_id = aws_security_group.lb_ecs-asg-alb_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "HTTP from VPC (k6 load generator via public path)"
  from_port         = 80
  protocol          = "tcp"
  to_port           = 80
  type              = "ingress"
}

resource "aws_security_group_rule" "rule_lb_ecs_asg_alb_group_to_autoscaling_group_ecs_asg_nodes_group_tcp_32768_65535" {
  security_group_id        = aws_security_group.autoscaling_group_ecs-asg-nodes_group.id
  source_security_group_id = aws_security_group.lb_ecs-asg-alb_group.id
  description              = "ALB para tasks ECS (bridge dynamic ports)"
  from_port                = 32768
  protocol                 = "tcp"
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_lb" "ecs-asg-alb" {
  name               = "ecs-asg-alb"
  enable_http2       = true
  idle_timeout       = 60
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_ecs-asg-alb_group.id]
  subnets            = [aws_subnet.ecs-asg-public-a.id, aws_subnet.ecs-asg-public-b.id]
  tags = {
    Name           = "ecs-asg-alb"
    State          = "ecs-asg-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_lb_listener" "ecs-asg-listener" {
  load_balancer_arn                    = aws_lb.ecs-asg-alb.arn
  port                                 = 80
  protocol                             = "HTTP"
  routing_http_response_server_enabled = true
  default_action {
    order            = 1
    target_group_arn = aws_lb_target_group.ecs-asg-tg-hub.arn
    type             = "forward"
    forward {
      target_group {
        arn = aws_lb_target_group.ecs-asg-tg-hub.arn
      }
    }
  }
  tags = {
    Name           = "ecs-asg-listener"
    State          = "ecs-asg-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_lb_target_group" "ecs-asg-tg-hub" {
  name                          = "ecs-asg-tg-hub"
  vpc_id                        = aws_vpc.ecs-asg-vpc.id
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
    Name           = "ecs-asg-tg-hub"
    State          = "ecs-asg-state"
    Struct8Creator = "Contato Struct"
  }
}




### CATEGORY: COMPUTE ###

data "local_file" "UserData_ecs-asg-k6" {
  filename = "${path.module}/.external_modules/struct8-templates/templates/vpc-k6-load-generator/v2/user_data/k6-bootstrap.sh"
}

data "aws_ami" "AMI_Data_Source_ecs-asg-k6" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-kernel-6.1-arm64"]
  }
}

resource "aws_instance" "ecs-asg-k6" {
  subnet_id                   = aws_subnet.ecs-asg-public-a.id
  ami                         = data.aws_ami.AMI_Data_Source_ecs-asg-k6.id
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.ecs-asg-k6_profile.name
  instance_type               = "t4g.nano"
  user_data_base64 = base64encode(<<-EOFUData
#!/bin/bash

# --- BEGIN STRUCT8 VARIABLES ---
cat << 'EOFENV' > /etc/struct8_env
K6_PANEL="on"
K6_PANEL_REF="main"
TARGET_URL="http://${aws_lb.ecs-asg-alb.dns_name}/loadtest?ms=80"
NAME="ecs-asg-k6"
REGION="${data.aws_region.current.region}"
ACCOUNT="${data.aws_caller_identity.current.account_id}"
EOFENV
cat /etc/struct8_env >> /etc/environment
sed 's/^/export /' /etc/struct8_env > /etc/profile.d/struct8_vars.sh
chmod +x /etc/profile.d/struct8_vars.sh
chmod 644 /etc/struct8_env
# --- END STRUCT8 VARIABLES ---

${data.local_file.UserData_ecs-asg-k6.content}
EOFUData
)
  vpc_security_group_ids = [aws_security_group.instance_ecs-asg-k6_group.id]
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
    Struct8Debug   = "f782657a-f005-4abb-aaea-eb2e8af8af58"
    Name           = "ecs-asg-k6"
    State          = "ecs-asg-state"
    Struct8Creator = "Contato Struct"
  }
}

data "local_file" "UserData_ecs-asg-nat-instance" {
  filename = "${path.module}/.external_modules/struct8-templates/templates/ec2-nat-private/v1/user_data/Nat.sh"
}

data "aws_ami" "AMI_Data_Source_ecs-asg-nat-instance" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-kernel-6.1-x86_64"]
  }
}

resource "aws_instance" "ecs-asg-nat-instance" {
  subnet_id                   = aws_subnet.ecs-asg-public-b.id
  ami                         = data.aws_ami.AMI_Data_Source_ecs-asg-nat-instance.id
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.ecs-asg-nat-instance_profile.name
  instance_type               = "t3.micro"
  source_dest_check           = false
  user_data_base64 = base64encode(<<-EOFUData
#!/bin/bash

${data.local_file.UserData_ecs-asg-nat-instance.content}
EOFUData
)
  user_data_replace_on_change = true
  vpc_security_group_ids      = [aws_security_group.instance_ecs-asg-nat-instance_group.id]
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
    Struct8Debug   = "GZLb18DbqWCTitZ4B6eSJ"
    Name           = "ecs-asg-nat-instance"
    State          = "ecs-asg-state"
    Struct8Creator = "Contato Struct"
  }
}

data "aws_ami" "AMI_Data_Source_ecs-asg-lt" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-ecs-hvm-2023.*-kernel-6.1-x86_64"]
  }
}

resource "aws_launch_template" "ecs-asg-lt" {
  image_id               = data.aws_ami.AMI_Data_Source_ecs-asg-lt.id
  name                   = "ecs-asg-lt"
  description            = "ECS container instances for the ASG (t3.nano, x86_64 -- matches the x86_64 Hub image). user_data joins the ecs-asg-cluster. In private subnets, so they reach ECR/ECS via the NAT."
  instance_type          = "t3.nano"
  update_default_version = true
  user_data = base64encode(<<-EOFUData
#!/bin/bash

# --- BEGIN STRUCT8 VARIABLES ---
cat << 'EOFENV' > /etc/struct8_env
NAME="ecs-asg-nodes"
REGION="${data.aws_region.current.region}"
ACCOUNT="${data.aws_caller_identity.current.account_id}"
EOFENV
cat /etc/struct8_env >> /etc/environment
sed 's/^/export /' /etc/struct8_env > /etc/profile.d/struct8_vars.sh
chmod +x /etc/profile.d/struct8_vars.sh
chmod 644 /etc/struct8_env
# --- END STRUCT8 VARIABLES ---

echo "ECS_CLUSTER=ecs-asg-cluster" >> /etc/ecs/ecs.config
EOFUData
)
  vpc_security_group_ids = [aws_security_group.autoscaling_group_ecs-asg-nodes_group.id]
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
    name = aws_iam_instance_profile.ecs-asg-nodes_profile.name
  }
  metadata_options {
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 1
    http_tokens                 = "required"
  }
  tag_specifications {
    resource_type = "volume"
    tags = {
    Name           = "ecs-asg-nodes"
    State          = "ecs-asg-state"
    Struct8Creator = "Contato Struct"
  }
  }
  tags = {
    Name           = "ecs-asg-lt"
    State          = "ecs-asg-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_autoscaling_group" "ecs-asg-nodes" {
  name                    = "ecs-asg-nodes"
  default_cooldown        = 30
  default_instance_warmup = 0
  desired_capacity        = 1
  enabled_metrics         = ["GroupDesiredCapacity", "GroupInServiceInstances", "GroupMaxSize", "GroupMinSize", "GroupPendingInstances", "GroupStandbyInstances", "GroupTerminatingInstances", "GroupTotalInstances"]
  health_check_type       = "EC2"
  max_instance_lifetime   = 0
  max_size                = 3
  metrics_granularity     = "1Minute"
  min_elb_capacity        = 0
  min_size                = 1
  termination_policies    = ["Default"]
  vpc_zone_identifier     = [aws_subnet.ecs-asg-private-a.id, aws_subnet.ecs-asg-private-b.id]
  wait_for_elb_capacity   = 0
  instance_refresh {
    strategy = "Rolling"
    triggers = ["launch_template"]
    preferences {
      instance_warmup        = 60
      min_healthy_percentage = 0
    }
  }
  launch_template {
    version = aws_launch_template.ecs-asg-lt.latest_version
    id      = aws_launch_template.ecs-asg-lt.id
  }
  tag {
    key                 = "Name"
    propagate_at_launch = true
    value               = "ecs-asg-nodes"
  }
  tag {
    key                 = "State"
    propagate_at_launch = true
    value               = "ecs-asg-state"
  }
  tag {
    key                 = "Struct8Creator"
    propagate_at_launch = true
    value               = "Contato Struct"
  }
}

resource "aws_appautoscaling_policy" "ecs-asg-hub-cpu" {
  name               = "ecs-asg-hub-cpu"
  resource_id        = aws_appautoscaling_target.ecs-asg-hub-scale.resource_id
  policy_type        = "TargetTrackingScaling"
  scalable_dimension = aws_appautoscaling_target.ecs-asg-hub-scale.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs-asg-hub-scale.service_namespace
  target_tracking_scaling_policy_configuration {
    disable_scale_in   = false
    scale_in_cooldown  = 60
    scale_out_cooldown = 30
    target_value       = 50
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}

resource "aws_appautoscaling_target" "ecs-asg-hub-scale" {
  resource_id        = "service/${aws_ecs_cluster.ecs-asg-cluster.name}/${aws_ecs_service.ecs-asg-hub_service.name}"
  max_capacity       = 12
  min_capacity       = 1
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
  tags = {
    Name           = "ecs-asg-hub-scale"
    State          = "ecs-asg-state"
    Struct8Creator = "Contato Struct"
  }
}




### CATEGORY: CONTAINERS ###

resource "aws_ecr_repository" "ecs-asg-hub-ecr" {
  name                 = "ecs-asg-hub-ecr"
  force_delete         = true
  image_tag_mutability = "MUTABLE"
  tags = {
    Name           = "ecs-asg-hub-ecr"
    State          = "ecs-asg-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_ecs_capacity_provider" "asg-ec2-cp" {
  name = "asg-ec2-cp"
  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.ecs-asg-nodes.arn
    managed_draining               = "ENABLED"
    managed_termination_protection = "DISABLED"
    managed_scaling {
      instance_warmup_period    = 60
      maximum_scaling_step_size = 10000
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 100
    }
  }
  tags = {
    Name           = "asg-ec2-cp"
    State          = "ecs-asg-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_ecs_cluster" "ecs-asg-cluster" {
  name = "ecs-asg-cluster"
  tags = {
    Name           = "ecs-asg-cluster"
    State          = "ecs-asg-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_ecs_cluster_capacity_providers" "assoc_cp_to_ecs-asg-cluster" {
  cluster_name       = aws_ecs_cluster.ecs-asg-cluster.name
  capacity_providers = [aws_ecs_capacity_provider.asg-ec2-cp.name]
}

resource "aws_ecs_service" "ecs-asg-hub_service" {
  name                    = "ecs-asg-hub_service"
  cluster                 = aws_ecs_cluster.ecs-asg-cluster.id
  desired_count           = 1
  enable_ecs_managed_tags = true
  force_delete            = true
  scheduling_strategy     = "REPLICA"
  task_definition         = "${aws_ecs_task_definition.ecs-asg-hub.family}:${aws_ecs_task_definition.ecs-asg-hub.revision}"
  capacity_provider_strategy {
    base              = 0
    capacity_provider = aws_ecs_capacity_provider.asg-ec2-cp.name
    weight            = 1
  }
  lifecycle {
    ignore_changes = [desired_count]
  }
  load_balancer {
    container_name   = "hub"
    container_port   = 8080
    target_group_arn = aws_lb_target_group.ecs-asg-tg-hub.arn
  }
  ordered_placement_strategy {
    field = "memory"
    type  = "binpack"
  }
  tags = {
    Name           = "ecs-asg-hub_service"
    State          = "ecs-asg-state"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [terraform_data.seed_ecs-asg-hub-ecr]
}

locals {
  container_def_ecs-asg-hub_hub = {
    name      = "hub"
    image     = "${aws_ecr_repository.ecs-asg-hub-ecr.repository_url}:latest"
    essential = true
    cpu       = 128
    memory    = 85
    portMappings = [
      {
        protocol      = "tcp"
        containerPort = 8080
      }
    ]
    environment = [
      {
        name  = "HUB_LOADTEST"
        value = "on"
      },
      {
        name  = "HUB_WORKERS"
        value = "1"
      },
      {
        name  = "NAME"
        value = "ecs-asg-hub"
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
        value = "asg-ec2-cp"
      }
    ]
    mountPoints            = []
    systemControls         = []
    volumesFrom            = []
    privileged             = false
    readonlyRootFilesystem = false
  }
}

resource "aws_ecs_task_definition" "ecs-asg-hub" {
  container_definitions    = jsonencode([local.container_def_ecs-asg-hub_hub])
  cpu                      = "128"
  execution_role_arn       = aws_iam_role.execution_role_ecs_ecs-asg-hub.arn
  family                   = "ecs-asg-hub"
  memory                   = "100"
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]
  task_role_arn            = aws_iam_role.task_role_ecs_ecs-asg-hub.arn
  tags = {
    Name           = "ecs-asg-hub"
    State          = "ecs-asg-state"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_iam_role_policy_attachment.ecs_task_definition_ecs-asg-hub_execution_st_ecs-asg-state_attach]
}




### CATEGORY: CONFIG ###

resource "aws_ssm_document" "Struct8Probe-ecs-asg-k6-debug" {
  name = "Struct8Probe-f782657a-f005-4abb-aaea-eb2e8af8af58"
  content = <<EOF
{
  "schemaVersion": "2.2",
  "description": "Struct8 network probe. The command text is fixed here; the caller supplies only a target and a port.",
  "parameters": {
    "target": {
      "type": "String",
      "description": "Hostname or IP address to probe.",
      "interpolationType": "ENV_VAR",
      "allowedPattern": "^[A-Za-z0-9._-]{1,253}$"
    },
    "port": {
      "type": "String",
      "description": "TCP port to test.",
      "default": "443",
      "interpolationType": "ENV_VAR",
      "allowedPattern": "^[0-9]{1,5}$"
    }
  },
  "mainSteps": [
    {
      "action": "aws:runShellScript",
      "name": "struct8Probe",
      "inputs": {
        "timeoutSeconds": "60",
        "runCommand": [
          "if [ -z \"$SSM_target\" ]; then export SSM_target=\"{{target}}\"; fi",
          "if [ -z \"$SSM_port\" ]; then export SSM_port=\"{{port}}\"; fi",
          "echo '--- resolve ---'",
          "getent hosts \"$SSM_target\" || echo \"no DNS answer\"",
          "echo '--- icmp ---'",
          "ping -c 3 -W 2 \"$SSM_target\" || echo \"no ICMP reply (often filtered, not conclusive)\"",
          "echo '--- tcp ---'",
          "if timeout 5 bash -c 'exec 3<>/dev/tcp/\"$1\"/\"$2\"' _ \"$SSM_target\" \"$SSM_port\" 2>/dev/null; then echo \"port $SSM_port open\"; else echo \"port $SSM_port closed or filtered\"; fi"
        ]
      }
    }
  ]
}
  EOF
  document_format = "JSON"
  document_type   = "Command"
}




### CATEGORY: MISC ###

resource "null_resource" "cleanup_ecs-asg-cluster" {
  triggers = {
    cluster_name = aws_ecs_cluster.ecs-asg-cluster.name
  }
  depends_on = [aws_ecs_cluster.ecs-asg-cluster, aws_autoscaling_group.ecs-asg-nodes, aws_ecs_capacity_provider.asg-ec2-cp]
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
        ASGS="ecs-asg-nodes"
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
    when        = destroy
  }
}

resource "terraform_data" "seed_ecs-asg-hub-ecr" {
  triggers_replace = ["${path.module}/.external_modules/struct8-hub/image", "latest"]
  lifecycle {
    replace_triggered_by = [aws_ecr_repository.ecs-asg-hub-ecr]
  }
  depends_on = [aws_ecr_repository.ecs-asg-hub-ecr]
  provisioner "local-exec" {
    command = <<EOF
set -e
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin ${split("/", aws_ecr_repository.ecs-asg-hub-ecr.repository_url)[0]}
docker build -t ${aws_ecr_repository.ecs-asg-hub-ecr.repository_url}:latest ${path.module}/.external_modules/struct8-hub/image
docker push ${aws_ecr_repository.ecs-asg-hub-ecr.repository_url}:latest
  EOF
    interpreter = ["/bin/bash", "-c"]
  }
}


