terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  backend "s3" {
    bucket  = "struct8-import"
    key     = "952133486861/Stateless-mon/main.tfstate"
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

### EXTERNAL REFERENCES ###

data "aws_efs_file_system" "efs-grafana-lgtm-mon" {
  tags = {
    Name = "efs-grafana-lgtm-mon"
  }
}

data "aws_vpc" "vpc-grafana-lgtm-mon" {
  filter {
    name   = "tag:Name"
    values = ["vpc-grafana-lgtm-mon"]
  }
}

data "aws_lb_listener" "listener-https1-mon" {
  load_balancer_arn = data.aws_lb.alb-grafana-mon.arn
  port              = 443
}

data "aws_instance" "ec2-nat-grafana-mon" {
  filter {
    name   = "tag:Name"
    values = ["ec2-nat-grafana-mon"]
  }
  filter {
    name   = "instance-state-name"
    values = ["running"]
  }
}

data "aws_s3_bucket" "lgtm-tempo-blocks-mon" {
  bucket = "lgtm-tempo-blocks-mon-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.region}-an"
}

data "aws_s3_bucket" "lgtm-grafana-config-mon" {
  bucket = "lgtm-grafana-config-mon-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.region}-an"
}

data "aws_s3_bucket" "lgtm-loki-chunks-mon" {
  bucket = "lgtm-loki-chunks-mon-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.region}-an"
}

data "aws_security_group" "lb_alb-grafana-mon_group" {
  filter {
    name   = "tag:Name"
    values = ["lb_alb-grafana-mon_group"]
  }
}

data "aws_security_group" "efs_file_system_efs-grafana-lgtm-mon_group" {
  filter {
    name   = "tag:Name"
    values = ["efs_file_system_efs-grafana-lgtm-mon_group"]
  }
}

data "aws_lb" "alb-grafana-mon" {
  name = "alb-grafana-mon"
}




### CATEGORY: IAM ###

resource "aws_iam_instance_profile" "lgtm-ecs-asg-mon_profile" {
  name = "lgtm-ecs-asg-mon_profile"
  role = aws_iam_role.lgtm-ecs-asg-mon_role.name
  tags = {
    Name           = "lgtm-ecs-asg-mon_profile"
    State          = "Stateless-mon"
    Struct8Creator = "Contato Struct"
  }
}

data "aws_iam_policy_document" "autoscaling_group_lgtm-ecs-asg-mon_st_Stateless-mon_doc" {
  statement {
    sid       = "AllowLgtmclustermon"
    effect    = "Allow"
    actions   = ["ecs:DeregisterContainerInstance", "ecs:DiscoverPollEndpoint", "ecs:Poll", "ecs:RegisterContainerInstance", "ecs:StartTelemetrySession", "ecs:Submit*"]
    resources = [aws_ecs_cluster.lgtm-cluster-mon.arn]
  }
}

resource "aws_iam_policy" "autoscaling_group_lgtm-ecs-asg-mon_st_Stateless-mon" {
  name        = "autoscaling_group_lgtm-ecs-asg-mon_st_Stateless-mon"
  description = "Access Policy for lgtm-ecs-asg-mon"
  policy      = data.aws_iam_policy_document.autoscaling_group_lgtm-ecs-asg-mon_st_Stateless-mon_doc.json
}

data "aws_iam_policy_document" "ecs_task_definition_alloy-mon_execution_st_Stateless-mon_doc" {
  statement {
    sid       = "AllowWriteLogs"
    effect    = "Allow"
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.logs-alloy-mon.arn}:*"]
  }
}

resource "aws_iam_policy" "ecs_task_definition_alloy-mon_execution_st_Stateless-mon" {
  name        = "ecs_task_definition_alloy-mon_execution_st_Stateless-mon"
  description = "Access Policy for alloy-mon (Role: execution)"
  policy      = data.aws_iam_policy_document.ecs_task_definition_alloy-mon_execution_st_Stateless-mon_doc.json
}

data "aws_iam_policy_document" "ecs_task_definition_alloy-mon_st_Stateless-mon_doc" {
  statement {
    sid       = "AllowRemoteWrite"
    effect    = "Allow"
    actions   = ["aps:GetLabels", "aps:GetMetricMetadata", "aps:GetSeries", "aps:RemoteWrite"]
    resources = [aws_prometheus_workspace.lgtm-amp-mon.arn]
  }
}

resource "aws_iam_policy" "ecs_task_definition_alloy-mon_st_Stateless-mon" {
  name        = "ecs_task_definition_alloy-mon_st_Stateless-mon"
  description = "Access Policy for alloy-mon"
  policy      = data.aws_iam_policy_document.ecs_task_definition_alloy-mon_st_Stateless-mon_doc.json
}

data "aws_iam_policy_document" "ecs_task_definition_grafana-mon_execution_st_Stateless-mon_doc" {
  statement {
    sid       = "AllowWriteLogs"
    effect    = "Allow"
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.logs-grafana-mon.arn}:*"]
  }
}

resource "aws_iam_policy" "ecs_task_definition_grafana-mon_execution_st_Stateless-mon" {
  name        = "ecs_task_definition_grafana-mon_execution_st_Stateless-mon"
  description = "Access Policy for grafana-mon (Role: execution)"
  policy      = data.aws_iam_policy_document.ecs_task_definition_grafana-mon_execution_st_Stateless-mon_doc.json
}

data "aws_iam_policy_document" "ecs_task_definition_grafana-mon_st_Stateless-mon_doc" {
  statement {
    sid       = "AllowEFSBasicAccess"
    effect    = "Allow"
    actions   = ["elasticfilesystem:ClientMount", "elasticfilesystem:ClientRootAccess", "elasticfilesystem:ClientWrite"]
    resources = ["${data.aws_efs_file_system.efs-grafana-lgtm-mon.arn}:*"]
  }
  statement {
    sid       = "AllowQuery"
    effect    = "Allow"
    actions   = ["aps:DescribeWorkspace", "aps:GetLabels", "aps:GetMetricMetadata", "aps:GetSeries", "aps:ListWorkspaces", "aps:QueryMetrics"]
    resources = [aws_prometheus_workspace.lgtm-amp-mon.arn]
  }
  statement {
    sid       = "AllowBucketLevelActions"
    effect    = "Allow"
    actions   = ["s3:GetBucketLocation", "s3:ListBucket"]
    resources = [data.aws_s3_bucket.lgtm-grafana-config-mon.arn]
  }
  statement {
    sid       = "AllowObjectCRUD"
    effect    = "Allow"
    actions   = ["s3:DeleteObject", "s3:GetObject", "s3:PutObject"]
    resources = ["${data.aws_s3_bucket.lgtm-grafana-config-mon.arn}/*"]
  }
}

resource "aws_iam_policy" "ecs_task_definition_grafana-mon_st_Stateless-mon" {
  name        = "ecs_task_definition_grafana-mon_st_Stateless-mon"
  description = "Access Policy for grafana-mon"
  policy      = data.aws_iam_policy_document.ecs_task_definition_grafana-mon_st_Stateless-mon_doc.json
}

data "aws_iam_policy_document" "ecs_task_definition_loki-mon_execution_st_Stateless-mon_doc" {
  statement {
    sid       = "AllowWriteLogs"
    effect    = "Allow"
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.logs-loki-mon.arn}:*"]
  }
}

resource "aws_iam_policy" "ecs_task_definition_loki-mon_execution_st_Stateless-mon" {
  name        = "ecs_task_definition_loki-mon_execution_st_Stateless-mon"
  description = "Access Policy for loki-mon (Role: execution)"
  policy      = data.aws_iam_policy_document.ecs_task_definition_loki-mon_execution_st_Stateless-mon_doc.json
}

data "aws_iam_policy_document" "ecs_task_definition_loki-mon_st_Stateless-mon_doc" {
  statement {
    sid       = "AllowBucketLevelActions"
    effect    = "Allow"
    actions   = ["s3:GetBucketLocation", "s3:ListBucket"]
    resources = [data.aws_s3_bucket.lgtm-loki-chunks-mon.arn]
  }
  statement {
    sid       = "AllowObjectCRUD"
    effect    = "Allow"
    actions   = ["s3:DeleteObject", "s3:GetObject", "s3:PutObject"]
    resources = ["${data.aws_s3_bucket.lgtm-loki-chunks-mon.arn}/*"]
  }
}

resource "aws_iam_policy" "ecs_task_definition_loki-mon_st_Stateless-mon" {
  name        = "ecs_task_definition_loki-mon_st_Stateless-mon"
  description = "Access Policy for loki-mon"
  policy      = data.aws_iam_policy_document.ecs_task_definition_loki-mon_st_Stateless-mon_doc.json
}

data "aws_iam_policy_document" "ecs_task_definition_tempo-mon_execution_st_Stateless-mon_doc" {
  statement {
    sid       = "AllowWriteLogs"
    effect    = "Allow"
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.logs-tempo-mon.arn}:*"]
  }
}

resource "aws_iam_policy" "ecs_task_definition_tempo-mon_execution_st_Stateless-mon" {
  name        = "ecs_task_definition_tempo-mon_execution_st_Stateless-mon"
  description = "Access Policy for tempo-mon (Role: execution)"
  policy      = data.aws_iam_policy_document.ecs_task_definition_tempo-mon_execution_st_Stateless-mon_doc.json
}

data "aws_iam_policy_document" "ecs_task_definition_tempo-mon_st_Stateless-mon_doc" {
  statement {
    sid       = "AllowBucketLevelActions"
    effect    = "Allow"
    actions   = ["s3:GetBucketLocation", "s3:ListBucket"]
    resources = [data.aws_s3_bucket.lgtm-tempo-blocks-mon.arn]
  }
  statement {
    sid       = "AllowObjectCRUD"
    effect    = "Allow"
    actions   = ["s3:DeleteObject", "s3:GetObject", "s3:PutObject"]
    resources = ["${data.aws_s3_bucket.lgtm-tempo-blocks-mon.arn}/*"]
  }
}

resource "aws_iam_policy" "ecs_task_definition_tempo-mon_st_Stateless-mon" {
  name        = "ecs_task_definition_tempo-mon_st_Stateless-mon"
  description = "Access Policy for tempo-mon"
  policy      = data.aws_iam_policy_document.ecs_task_definition_tempo-mon_st_Stateless-mon_doc.json
}

data "aws_iam_policy_document" "Debug-asg-mon_debug_permissions" {
  statement {
    sid       = "SendToTaggedInstancesOnly"
    effect    = "Allow"
    actions   = ["ssm:SendCommand"]
    resources = ["arn:aws:ec2:*:*:instance/*"]
    condition {
      test     = "StringEquals"
      values   = ["Vz6HFyU4chYBtvk4gbnjo"]
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
      values   = ["Vz6HFyU4chYBtvk4gbnjo"]
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

data "aws_iam_policy_document" "Debug-asg-mon_debug_trust" {
  statement {
    effect = "Allow"
    principals {
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/CrossAccountStruct8"]
      type        = "AWS"
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "Struct8Debug-Debug-asg-mon" {
  name                 = "Struct8Debug-Vz6HFyU4chYBtvk4gbnjo"
  assume_role_policy   = data.aws_iam_policy_document.Debug-asg-mon_debug_trust.json
  max_session_duration = 3600
}

resource "aws_iam_role" "execution_role_ecs_alloy-mon" {
  name = "execution_role_ecs_alloy-mon"
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
    Name           = "execution_role_ecs_alloy-mon"
    State          = "Stateless-mon"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "execution_role_ecs_grafana-mon" {
  name = "execution_role_ecs_grafana-mon"
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
    Name           = "execution_role_ecs_grafana-mon"
    State          = "Stateless-mon"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "execution_role_ecs_loki-mon" {
  name = "execution_role_ecs_loki-mon"
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
    Name           = "execution_role_ecs_loki-mon"
    State          = "Stateless-mon"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "execution_role_ecs_tempo-mon" {
  name = "execution_role_ecs_tempo-mon"
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
    Name           = "execution_role_ecs_tempo-mon"
    State          = "Stateless-mon"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "lgtm-ecs-asg-mon_role" {
  name = "lgtm-ecs-asg-mon_role"
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
    Name           = "lgtm-ecs-asg-mon_role"
    State          = "Stateless-mon"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "task_role_ecs_alloy-mon" {
  name = "task_role_ecs_alloy-mon"
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
    Name           = "task_role_ecs_alloy-mon"
    State          = "Stateless-mon"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "task_role_ecs_grafana-mon" {
  name = "task_role_ecs_grafana-mon"
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
    Name           = "task_role_ecs_grafana-mon"
    State          = "Stateless-mon"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "task_role_ecs_loki-mon" {
  name = "task_role_ecs_loki-mon"
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
    Name           = "task_role_ecs_loki-mon"
    State          = "Stateless-mon"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "task_role_ecs_tempo-mon" {
  name = "task_role_ecs_tempo-mon"
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
    Name           = "task_role_ecs_tempo-mon"
    State          = "Stateless-mon"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role_policy" "Struct8Debug-Debug-asg-mon_policy" {
  name   = "Struct8Debug-Vz6HFyU4chYBtvk4gbnjo-policy"
  policy = data.aws_iam_policy_document.Debug-asg-mon_debug_permissions.json
  role   = aws_iam_role.Struct8Debug-Debug-asg-mon.id
}

resource "aws_iam_role_policy_attachment" "AmazonSSMManagedInstanceCore_to_lgtm-ecs-asg-mon_attach" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.lgtm-ecs-asg-mon_role.name
}

resource "aws_iam_role_policy_attachment" "autoscaling_group_lgtm-ecs-asg-mon_st_Stateless-mon_attach" {
  policy_arn = aws_iam_policy.autoscaling_group_lgtm-ecs-asg-mon_st_Stateless-mon.arn
  role       = aws_iam_role.lgtm-ecs-asg-mon_role.name
}

resource "aws_iam_role_policy_attachment" "ecs_task_definition_alloy-mon_execution_st_Stateless-mon_attach" {
  policy_arn = aws_iam_policy.ecs_task_definition_alloy-mon_execution_st_Stateless-mon.arn
  role       = aws_iam_role.execution_role_ecs_alloy-mon.name
}

resource "aws_iam_role_policy_attachment" "ecs_task_definition_alloy-mon_st_Stateless-mon_attach" {
  policy_arn = aws_iam_policy.ecs_task_definition_alloy-mon_st_Stateless-mon.arn
  role       = aws_iam_role.task_role_ecs_alloy-mon.name
}

resource "aws_iam_role_policy_attachment" "ecs_task_definition_grafana-mon_execution_st_Stateless-mon_attach" {
  policy_arn = aws_iam_policy.ecs_task_definition_grafana-mon_execution_st_Stateless-mon.arn
  role       = aws_iam_role.execution_role_ecs_grafana-mon.name
}

resource "aws_iam_role_policy_attachment" "ecs_task_definition_grafana-mon_st_Stateless-mon_attach" {
  policy_arn = aws_iam_policy.ecs_task_definition_grafana-mon_st_Stateless-mon.arn
  role       = aws_iam_role.task_role_ecs_grafana-mon.name
}

resource "aws_iam_role_policy_attachment" "ecs_task_definition_loki-mon_execution_st_Stateless-mon_attach" {
  policy_arn = aws_iam_policy.ecs_task_definition_loki-mon_execution_st_Stateless-mon.arn
  role       = aws_iam_role.execution_role_ecs_loki-mon.name
}

resource "aws_iam_role_policy_attachment" "ecs_task_definition_loki-mon_st_Stateless-mon_attach" {
  policy_arn = aws_iam_policy.ecs_task_definition_loki-mon_st_Stateless-mon.arn
  role       = aws_iam_role.task_role_ecs_loki-mon.name
}

resource "aws_iam_role_policy_attachment" "ecs_task_definition_tempo-mon_execution_st_Stateless-mon_attach" {
  policy_arn = aws_iam_policy.ecs_task_definition_tempo-mon_execution_st_Stateless-mon.arn
  role       = aws_iam_role.execution_role_ecs_tempo-mon.name
}

resource "aws_iam_role_policy_attachment" "ecs_task_definition_tempo-mon_st_Stateless-mon_attach" {
  policy_arn = aws_iam_policy.ecs_task_definition_tempo-mon_st_Stateless-mon.arn
  role       = aws_iam_role.task_role_ecs_tempo-mon.name
}

resource "aws_iam_role_policy_attachment" "service_role_AmazonEC2ContainerServiceforEC2Role_to_lgtm-ecs-asg-mon_attach" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
  role       = aws_iam_role.lgtm-ecs-asg-mon_role.name
}




### CATEGORY: NETWORK ###

resource "aws_vpc_endpoint" "s3-gateway-endpoint-mon_S3" {
  service_name      = "com.amazonaws.us-west-2.s3"
  vpc_id            = data.aws_vpc.vpc-grafana-lgtm-mon.id
  route_table_ids   = [aws_route_table.rtb-private-mon.id]
  vpc_endpoint_type = "Gateway"
  tags = {
    DifName        = "s3-gateway-endpoint-mon_S3"
    Name           = "s3-gateway-endpoint-mon"
    State          = "Stateless-mon"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "snet-app-1a-mon" {
  vpc_id                              = data.aws_vpc.vpc-grafana-lgtm-mon.id
  availability_zone                   = "us-west-2a"
  cidr_block                          = "10.4.2.0/24"
  map_public_ip_on_launch             = false
  private_dns_hostname_type_on_launch = "ip-name"
  tags = {
    Name           = "private-hub-a"
    State          = "Stateless-mon"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "snet-app-1b-mon" {
  vpc_id                              = data.aws_vpc.vpc-grafana-lgtm-mon.id
  availability_zone                   = "us-west-2b"
  cidr_block                          = "10.4.3.0/24"
  map_public_ip_on_launch             = false
  private_dns_hostname_type_on_launch = "ip-name"
  tags = {
    Name           = "private-hub-b"
    State          = "Stateless-mon"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route" "route_rtb-private-mon_to_ec2-nat-grafana-mon_ipv4" {
  network_interface_id   = data.aws_instance.ec2-nat-grafana-mon.network_interface_id
  route_table_id         = aws_route_table.rtb-private-mon.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table" "rtb-private-mon" {
  vpc_id = data.aws_vpc.vpc-grafana-lgtm-mon.id
  tags = {
    Name           = "rtb-private-mon"
    State          = "Stateless-mon"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route_table_association" "aws_route_table_association_snet_app_1a_mon_rtb_private_mon" {
  route_table_id = aws_route_table.rtb-private-mon.id
  subnet_id      = aws_subnet.snet-app-1a-mon.id
}

resource "aws_route_table_association" "aws_route_table_association_snet_app_1b_mon_rtb_private_mon" {
  route_table_id = aws_route_table.rtb-private-mon.id
  subnet_id      = aws_subnet.snet-app-1b-mon.id
}

resource "aws_security_group" "autoscaling_group_lgtm-ecs-asg-mon_group" {
  name                   = "autoscaling_group_lgtm-ecs-asg-mon_group"
  vpc_id                 = data.aws_vpc.vpc-grafana-lgtm-mon.id
  revoke_rules_on_delete = false
  tags = {
    Name           = "autoscaling_group_lgtm-ecs-asg-mon_group"
    State          = "Stateless-mon"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group" "ecs_task_definition_alloy-mon_group" {
  name                   = "ecs_task_definition_alloy-mon_group"
  vpc_id                 = data.aws_vpc.vpc-grafana-lgtm-mon.id
  description            = "SG for the alloy ECS service (collector, UI on 12345). Egress open so alloy can remote-write to mimir/loki/tempo over Service Connect. No inbound service traffic expected."
  revoke_rules_on_delete = false
  tags = {
    Name           = "ecs_task_definition_alloy-mon_group"
    State          = "Stateless-mon"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group" "ecs_task_definition_grafana-mon_group" {
  name                   = "ecs_task_definition_grafana-mon_group"
  vpc_id                 = data.aws_vpc.vpc-grafana-lgtm-mon.id
  description            = "SG for the grafana ECS service (UI on 3000, served by the ALB). Egress open so grafana can query mimir/loki/tempo over Service Connect; ingress on 3000 comes from the ALB."
  revoke_rules_on_delete = false
  tags = {
    Name           = "ecs_task_definition_grafana-mon_group"
    State          = "Stateless-mon"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group" "ecs_task_definition_loki-mon_group" {
  name                   = "ecs_task_definition_loki-mon_group"
  vpc_id                 = data.aws_vpc.vpc-grafana-lgtm-mon.id
  description            = "SG for the loki ECS service (logs, listens on 3100). Ingress on 3100 is added by the Service Connect wires from grafana and alloy; egress open for S3 (chunks) and peers."
  revoke_rules_on_delete = false
  tags = {
    Name           = "ecs_task_definition_loki-mon_group"
    State          = "Stateless-mon"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group" "ecs_task_definition_tempo-mon_group" {
  name                   = "ecs_task_definition_tempo-mon_group"
  vpc_id                 = data.aws_vpc.vpc-grafana-lgtm-mon.id
  description            = "SG for the tempo ECS service (traces, listens on 3200). Ingress on 3200 is added by the Service Connect wires from grafana and alloy; egress open for S3 (blocks) and peers."
  revoke_rules_on_delete = false
  tags = {
    Name           = "ecs_task_definition_tempo-mon_group"
    State          = "Stateless-mon"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group_rule" "rule_autoscaling_group_lgtm_ecs_asg_mon_group_egress_all_protocols" {
  security_group_id = aws_security_group.autoscaling_group_lgtm-ecs-asg-mon_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "rule_ecs_task_definition_alloy_mon_group_egress_all_protocols" {
  security_group_id = aws_security_group.ecs_task_definition_alloy-mon_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "rule_ecs_task_definition_alloy_mon_group_to_ecs_task_definition_loki_mon_group_tcp_3100" {
  security_group_id        = aws_security_group.ecs_task_definition_loki-mon_group.id
  source_security_group_id = aws_security_group.ecs_task_definition_alloy-mon_group.id
  description              = "alloy to loki (logs push, Service Connect) on 3100"
  from_port                = 3100
  protocol                 = "tcp"
  to_port                  = 3100
  type                     = "ingress"
}

resource "aws_security_group_rule" "rule_ecs_task_definition_alloy_mon_group_to_ecs_task_definition_tempo_mon_group_tcp_3100" {
  security_group_id        = aws_security_group.ecs_task_definition_tempo-mon_group.id
  source_security_group_id = aws_security_group.ecs_task_definition_alloy-mon_group.id
  description              = "alloy to loki (logs push, Service Connect) on 3100"
  from_port                = 3100
  protocol                 = "tcp"
  to_port                  = 3100
  type                     = "ingress"
}

resource "aws_security_group_rule" "rule_ecs_task_definition_alloy_mon_group_to_ecs_task_definition_tempo_mon_group_tcp_3200" {
  security_group_id        = aws_security_group.ecs_task_definition_tempo-mon_group.id
  source_security_group_id = aws_security_group.ecs_task_definition_alloy-mon_group.id
  description              = "alloy to tempo (traces push, Service Connect) on 3200"
  from_port                = 3200
  protocol                 = "tcp"
  to_port                  = 3200
  type                     = "ingress"
}

resource "aws_security_group_rule" "rule_ecs_task_definition_grafana_mon_group_egress_all_protocols" {
  security_group_id = aws_security_group.ecs_task_definition_grafana-mon_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "rule_ecs_task_definition_grafana_mon_group_to_ecs_task_definition_loki_mon_group_tcp_3100" {
  security_group_id        = aws_security_group.ecs_task_definition_loki-mon_group.id
  source_security_group_id = aws_security_group.ecs_task_definition_grafana-mon_group.id
  description              = "grafana to loki (logs query, Service Connect) on 3100"
  from_port                = 3100
  protocol                 = "tcp"
  to_port                  = 3100
  type                     = "ingress"
}

resource "aws_security_group_rule" "rule_ecs_task_definition_grafana_mon_group_to_ecs_task_definition_tempo_mon_group_tcp_3100" {
  security_group_id        = aws_security_group.ecs_task_definition_tempo-mon_group.id
  source_security_group_id = aws_security_group.ecs_task_definition_grafana-mon_group.id
  description              = "grafana to loki (logs query, Service Connect) on 3100"
  from_port                = 3100
  protocol                 = "tcp"
  to_port                  = 3100
  type                     = "ingress"
}

resource "aws_security_group_rule" "rule_ecs_task_definition_grafana_mon_group_to_ecs_task_definition_tempo_mon_group_tcp_3200" {
  security_group_id        = aws_security_group.ecs_task_definition_tempo-mon_group.id
  source_security_group_id = aws_security_group.ecs_task_definition_grafana-mon_group.id
  description              = "grafana to tempo (traces query, Service Connect) on 3200"
  from_port                = 3200
  protocol                 = "tcp"
  to_port                  = 3200
  type                     = "ingress"
}

resource "aws_security_group_rule" "rule_ecs_task_definition_grafana_mon_group_to_efs_file_system_efs_grafana_lgtm_mon_group_tcp_2049" {
  security_group_id        = data.aws_security_group.efs_file_system_efs-grafana-lgtm-mon_group.id
  source_security_group_id = aws_security_group.ecs_task_definition_grafana-mon_group.id
  description              = "NFS from Grafana ECS task"
  from_port                = 2049
  protocol                 = "tcp"
  to_port                  = 2049
  type                     = "ingress"
}

resource "aws_security_group_rule" "rule_ecs_task_definition_loki_mon_group_egress_all_protocols" {
  security_group_id = aws_security_group.ecs_task_definition_loki-mon_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "rule_ecs_task_definition_tempo_mon_group_egress_all_protocols" {
  security_group_id = aws_security_group.ecs_task_definition_tempo-mon_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "rule_lb_alb_grafana_mon_group_to_ecs_task_definition_grafana_mon_group_tcp_3000" {
  security_group_id        = aws_security_group.ecs_task_definition_grafana-mon_group.id
  source_security_group_id = data.aws_security_group.lb_alb-grafana-mon_group.id
  description              = "Allow from lb_alb-grafana-mon_group (tcp:3000-3000)"
  from_port                = 3000
  protocol                 = "tcp"
  to_port                  = 3000
  type                     = "ingress"
}

resource "aws_security_group_rule" "rule_lb_alb_grafana_mon_group_to_ecs_task_definition_tempo_mon_group_tcp_3000" {
  security_group_id        = aws_security_group.ecs_task_definition_tempo-mon_group.id
  source_security_group_id = data.aws_security_group.lb_alb-grafana-mon_group.id
  description              = "Allow from lb_alb-grafana-mon_group (tcp:3000-3000)"
  from_port                = 3000
  protocol                 = "tcp"
  to_port                  = 3000
  type                     = "ingress"
}

resource "aws_service_discovery_http_namespace" "lgtm-connect-mon" {
  name        = "lgtm-connect-mon"
  description = "HTTP namespace for ECS Service Connect. Replaces the DNS-based service discovery: grafana and alloy reach mimir/loki/tempo by name over Service Connect, which load-balances client-side across each target's replicas."
  tags = {
    Name           = "lgtm-connect-mon"
    State          = "Stateless-mon"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_lb_listener_rule" "rule-grafana-host-mon" {
  action {
    order = 1
    type  = "forward"
    forward {
      target_group {
        arn = aws_lb_target_group.tg-grafana-mon.arn
      }
    }
  }
  condition {
    host_header {
      values = ["grafana.cloudman.pro"]
    }
  }
  listener_arn = data.aws_lb_listener.listener-https1-mon.arn
  priority     = 10
  tags = {
    Name           = "rule-grafana-host-mon"
    State          = "Stateless-mon"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_lb_target_group" "tg-grafana-mon" {
  name                              = "tg-grafana-mon"
  vpc_id                            = data.aws_vpc.vpc-grafana-lgtm-mon.id
  deregistration_delay              = "30"
  ip_address_type                   = "ipv4"
  load_balancing_algorithm_type     = "round_robin"
  load_balancing_anomaly_mitigation = "off"
  load_balancing_cross_zone_enabled = "use_load_balancer_configuration"
  port                              = 8080
  protocol                          = "HTTP"
  protocol_version                  = "HTTP1"
  slow_start                        = 0
  target_type                       = "ip"
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
  stickiness {
    cookie_duration = 86400
    enabled         = false
    type            = "lb_cookie"
  }
  tags = {
    Name           = "tg-grafana-mon"
    State          = "Stateless-mon"
    Struct8Creator = "Contato Struct"
  }
  target_group_health {
    dns_failover {
      minimum_healthy_targets_count      = "1"
      minimum_healthy_targets_percentage = "off"
    }
    unhealthy_state_routing {
      minimum_healthy_targets_count      = 1
      minimum_healthy_targets_percentage = "off"
    }
  }
}




### CATEGORY: STORAGE ###

resource "aws_efs_access_point" "ap_grafana-mon_efs-grafana-lgtm-mon" {
  file_system_id = data.aws_efs_file_system.efs-grafana-lgtm-mon.id
  posix_user {
    gid = "472"
    uid = "472"
  }
  root_directory {
    path = "/grafana-data"
    creation_info {
      owner_gid   = "472"
      owner_uid   = "472"
      permissions = "0755"
    }
  }
  tags = {
    Name           = "ap_grafana-mon_efs-grafana-lgtm-mon"
    State          = "Stateless-mon"
    Struct8Creator = "Contato Struct"
  }
}




### CATEGORY: COMPUTE ###

data "aws_ami" "AMI_Data_Source_lgtm-ecs-lt-mon" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-ecs-hvm-2023.*-kernel-6.1-arm64"]
  }
}

resource "aws_launch_template" "lgtm-ecs-lt-mon" {
  image_id               = data.aws_ami.AMI_Data_Source_lgtm-ecs-lt-mon.id
  name                   = "lgtm-ecs-lt-mon"
  instance_type          = "m6g.medium"
  update_default_version = true
  user_data = base64encode(<<-EOFUData
#!/bin/bash

# --- BEGIN STRUCT8 VARIABLES ---
cat << 'EOFENV' > /etc/struct8_env
ECS_CLUSTER="${aws_ecs_cluster.lgtm-cluster-mon.name}"
NAME="lgtm-ecs-asg-mon"
REGION="${data.aws_region.current.region}"
ACCOUNT="${data.aws_caller_identity.current.account_id}"
EOFENV
cat /etc/struct8_env >> /etc/environment
sed 's/^/export /' /etc/struct8_env > /etc/profile.d/struct8_vars.sh
chmod +x /etc/profile.d/struct8_vars.sh
chmod 644 /etc/struct8_env
# --- END STRUCT8 VARIABLES ---

# --- BEGIN STRUCT8 ECS BOOTSTRAP ---
mkdir -p /etc/ecs
source /etc/struct8_env
echo "ECS_CLUSTER=$ECS_CLUSTER" >> /etc/ecs/ecs.config
echo "ECS_ENABLE_CONTAINER_METADATA=true" >> /etc/ecs/ecs.config
# --- END STRUCT8 ECS BOOTSTRAP ---


EOFUData
)
  vpc_security_group_ids = [aws_security_group.autoscaling_group_lgtm-ecs-asg-mon_group.id]
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
    name = aws_iam_instance_profile.lgtm-ecs-asg-mon_profile.name
  }
  metadata_options {
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 1
    http_tokens                 = "required"
  }
  tag_specifications {
    resource_type = "volume"
    tags = {
    Struct8Debug   = "Vz6HFyU4chYBtvk4gbnjo"
    Name           = "lgtm-ecs-asg-mon"
    State          = "Stateless-mon"
    Struct8Creator = "Contato Struct"
  }
  }
  tags = {
    Name           = "lgtm-ecs-lt-mon"
    State          = "Stateless-mon"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_autoscaling_group" "lgtm-ecs-asg-mon" {
  name                    = "lgtm-ecs-asg-mon"
  default_instance_warmup = 0
  desired_capacity        = 1
  health_check_type       = "EC2"
  max_instance_lifetime   = 0
  max_size                = 1
  metrics_granularity     = "1Minute"
  min_elb_capacity        = 0
  min_size                = 1
  protect_from_scale_in   = true
  termination_policies    = ["Default"]
  vpc_zone_identifier     = [aws_subnet.snet-app-1a-mon.id, aws_subnet.snet-app-1b-mon.id]
  wait_for_elb_capacity   = 0
  launch_template {
    version = aws_launch_template.lgtm-ecs-lt-mon.latest_version
    id      = aws_launch_template.lgtm-ecs-lt-mon.id
  }
  tag {
    key                 = "Struct8Debug"
    propagate_at_launch = true
    value               = "Vz6HFyU4chYBtvk4gbnjo"
  }
  tag {
    key                 = "Name"
    propagate_at_launch = true
    value               = "lgtm-ecs-asg-mon"
  }
  tag {
    key                 = "State"
    propagate_at_launch = true
    value               = "Stateless-mon"
  }
  tag {
    key                 = "Struct8Creator"
    propagate_at_launch = true
    value               = "Contato Struct"
  }
}

resource "aws_appautoscaling_policy" "alloy-scale-cpu" {
  name               = "alloy-scale-cpu"
  resource_id        = aws_appautoscaling_target.alloy-scale-target-mon.resource_id
  policy_type        = "TargetTrackingScaling"
  scalable_dimension = aws_appautoscaling_target.alloy-scale-target-mon.scalable_dimension
  service_namespace  = aws_appautoscaling_target.alloy-scale-target-mon.service_namespace
  target_tracking_scaling_policy_configuration {
    disable_scale_in   = false
    scale_in_cooldown  = 120
    scale_out_cooldown = 60
    target_value       = 60
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}

resource "aws_appautoscaling_policy" "grafana-scale-cpu" {
  name               = "grafana-scale-cpu"
  resource_id        = aws_appautoscaling_target.grafana-scale-target-mon.resource_id
  policy_type        = "TargetTrackingScaling"
  scalable_dimension = aws_appautoscaling_target.grafana-scale-target-mon.scalable_dimension
  service_namespace  = aws_appautoscaling_target.grafana-scale-target-mon.service_namespace
  target_tracking_scaling_policy_configuration {
    disable_scale_in   = false
    scale_in_cooldown  = 120
    scale_out_cooldown = 60
    target_value       = 40
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}

resource "aws_appautoscaling_policy" "loki-scale-cpu" {
  name               = "loki-scale-cpu"
  resource_id        = aws_appautoscaling_target.loki-scale-target-mon.resource_id
  policy_type        = "TargetTrackingScaling"
  scalable_dimension = aws_appautoscaling_target.loki-scale-target-mon.scalable_dimension
  service_namespace  = aws_appautoscaling_target.loki-scale-target-mon.service_namespace
  target_tracking_scaling_policy_configuration {
    disable_scale_in   = false
    scale_in_cooldown  = 120
    scale_out_cooldown = 60
    target_value       = 60
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}

resource "aws_appautoscaling_policy" "tempo-scale-cpu" {
  name               = "tempo-scale-cpu"
  resource_id        = aws_appautoscaling_target.tempo-scale-target-mon.resource_id
  policy_type        = "TargetTrackingScaling"
  scalable_dimension = aws_appautoscaling_target.tempo-scale-target-mon.scalable_dimension
  service_namespace  = aws_appautoscaling_target.tempo-scale-target-mon.service_namespace
  target_tracking_scaling_policy_configuration {
    disable_scale_in   = false
    scale_in_cooldown  = 120
    scale_out_cooldown = 60
    target_value       = 60
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}

resource "aws_appautoscaling_target" "alloy-scale-target-mon" {
  resource_id        = "service/${aws_ecs_cluster.lgtm-cluster-mon.name}/${aws_ecs_service.alloy-mon_service.name}"
  max_capacity       = 2
  min_capacity       = 1
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
  tags = {
    Name           = "alloy-scale-target-mon"
    State          = "Stateless-mon"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_appautoscaling_target" "grafana-scale-target-mon" {
  resource_id        = "service/${aws_ecs_cluster.lgtm-cluster-mon.name}/${aws_ecs_service.grafana-mon_service.name}"
  max_capacity       = 1
  min_capacity       = 1
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
  suspended_state {
    dynamic_scaling_in_suspended  = false
    dynamic_scaling_out_suspended = false
    scheduled_scaling_suspended   = false
  }
  tags = {
    Name           = "hub-scale-target"
    State          = "Stateless-mon"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_appautoscaling_target" "loki-scale-target-mon" {
  resource_id        = "service/${aws_ecs_cluster.lgtm-cluster-mon.name}/${aws_ecs_service.loki-mon_service.name}"
  max_capacity       = 2
  min_capacity       = 1
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
  tags = {
    Name           = "loki-scale-target-mon"
    State          = "Stateless-mon"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_appautoscaling_target" "tempo-scale-target-mon" {
  resource_id        = "service/${aws_ecs_cluster.lgtm-cluster-mon.name}/${aws_ecs_service.tempo-mon_service.name}"
  max_capacity       = 2
  min_capacity       = 1
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
  tags = {
    Name           = "tempo-scale-target-mon"
    State          = "Stateless-mon"
    Struct8Creator = "Contato Struct"
  }
}




### CATEGORY: CONTAINERS ###

resource "aws_ecs_capacity_provider" "lgtm-ec2-cp-mon" {
  name = "lgtm-ec2-cp-mon"
  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.lgtm-ecs-asg-mon.arn
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
    Name           = "lgtm-ec2-cp-mon"
    State          = "Stateless-mon"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_ecs_cluster" "lgtm-cluster-mon" {
  name = "ltfargate-target-mon"
  service_connect_defaults {
    namespace = aws_service_discovery_http_namespace.lgtm-connect-mon.arn
  }
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
  tags = {
    Name           = "ltfargate-target"
    State          = "Stateless-mon"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_ecs_cluster_capacity_providers" "assoc_cp_to_lgtm-cluster-mon" {
  cluster_name       = aws_ecs_cluster.lgtm-cluster-mon.name
  capacity_providers = ["FARGATE_SPOT", aws_ecs_capacity_provider.lgtm-ec2-cp-mon.name]
}

resource "aws_ecs_service" "alloy-mon_service" {
  name                    = "alloy-mon_service"
  cluster                 = aws_ecs_cluster.lgtm-cluster-mon.id
  desired_count           = 1
  enable_ecs_managed_tags = true
  force_delete            = true
  scheduling_strategy     = "REPLICA"
  task_definition         = "${aws_ecs_task_definition.alloy-mon.family}:${aws_ecs_task_definition.alloy-mon.revision}"
  capacity_provider_strategy {
    base              = 0
    capacity_provider = aws_ecs_capacity_provider.lgtm-ec2-cp-mon.name
    weight            = 1
  }
  lifecycle {
    ignore_changes = [desired_count]
  }
  network_configuration {
    assign_public_ip = false
    security_groups  = [aws_security_group.autoscaling_group_lgtm-ecs-asg-mon_group.id, aws_security_group.ecs_task_definition_alloy-mon_group.id]
    subnets          = [aws_subnet.snet-app-1a-mon.id, aws_subnet.snet-app-1b-mon.id]
  }
  ordered_placement_strategy {
    field = "cpu"
    type  = "binpack"
  }
  service_connect_configuration {
    enabled = true
  }
  tags = {
    Name           = "alloy-mon_service"
    State          = "Stateless-mon"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_ecs_service" "grafana-mon_service" {
  name                    = "grafana-mon_service"
  cluster                 = aws_ecs_cluster.lgtm-cluster-mon.id
  desired_count           = 1
  enable_ecs_managed_tags = true
  force_delete            = true
  scheduling_strategy     = "REPLICA"
  task_definition         = "${aws_ecs_task_definition.grafana-mon.family}:${aws_ecs_task_definition.grafana-mon.revision}"
  capacity_provider_strategy {
    base              = 0
    capacity_provider = aws_ecs_capacity_provider.lgtm-ec2-cp-mon.name
    weight            = 1
  }
  lifecycle {
    ignore_changes = [desired_count]
  }
  load_balancer {
    container_name   = "grafana"
    container_port   = 3000
    target_group_arn = aws_lb_target_group.tg-grafana-mon.arn
  }
  network_configuration {
    assign_public_ip = false
    security_groups  = [aws_security_group.autoscaling_group_lgtm-ecs-asg-mon_group.id, aws_security_group.ecs_task_definition_grafana-mon_group.id]
    subnets          = [aws_subnet.snet-app-1a-mon.id, aws_subnet.snet-app-1b-mon.id]
  }
  ordered_placement_strategy {
    field = "cpu"
    type  = "binpack"
  }
  service_connect_configuration {
    enabled = true
  }
  tags = {
    Name           = "grafana-mon_service"
    State          = "Stateless-mon"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_ecs_service" "loki-mon_service" {
  name                    = "loki-mon_service"
  cluster                 = aws_ecs_cluster.lgtm-cluster-mon.id
  desired_count           = 1
  enable_ecs_managed_tags = true
  force_delete            = true
  scheduling_strategy     = "REPLICA"
  task_definition         = "${aws_ecs_task_definition.loki-mon.family}:${aws_ecs_task_definition.loki-mon.revision}"
  capacity_provider_strategy {
    base              = 0
    capacity_provider = aws_ecs_capacity_provider.lgtm-ec2-cp-mon.name
    weight            = 1
  }
  lifecycle {
    ignore_changes = [desired_count]
  }
  network_configuration {
    assign_public_ip = false
    security_groups  = [aws_security_group.autoscaling_group_lgtm-ecs-asg-mon_group.id, aws_security_group.ecs_task_definition_loki-mon_group.id]
    subnets          = [aws_subnet.snet-app-1a-mon.id, aws_subnet.snet-app-1b-mon.id]
  }
  ordered_placement_strategy {
    field = "cpu"
    type  = "binpack"
  }
  service_connect_configuration {
    enabled = true
    service {
      discovery_name = "loki"
      port_name      = "loki-3100"
      client_alias {
        dns_name = "loki"
        port     = 3100
      }
    }
  }
  tags = {
    Name           = "loki-mon_service"
    State          = "Stateless-mon"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_ecs_service" "tempo-mon_service" {
  name                    = "tempo-mon_service"
  cluster                 = aws_ecs_cluster.lgtm-cluster-mon.id
  desired_count           = 1
  enable_ecs_managed_tags = true
  force_delete            = true
  scheduling_strategy     = "REPLICA"
  task_definition         = "${aws_ecs_task_definition.tempo-mon.family}:${aws_ecs_task_definition.tempo-mon.revision}"
  capacity_provider_strategy {
    base              = 0
    capacity_provider = aws_ecs_capacity_provider.lgtm-ec2-cp-mon.name
    weight            = 1
  }
  lifecycle {
    ignore_changes = [desired_count]
  }
  network_configuration {
    assign_public_ip = false
    security_groups  = [aws_security_group.autoscaling_group_lgtm-ecs-asg-mon_group.id, aws_security_group.ecs_task_definition_tempo-mon_group.id]
    subnets          = [aws_subnet.snet-app-1a-mon.id, aws_subnet.snet-app-1b-mon.id]
  }
  ordered_placement_strategy {
    field = "cpu"
    type  = "binpack"
  }
  service_connect_configuration {
    enabled = true
    service {
      discovery_name = "tempo"
      port_name      = "tempo-3200"
      client_alias {
        dns_name = "tempo"
        port     = 3200
      }
    }
  }
  tags = {
    Name           = "tempo-mon_service"
    State          = "Stateless-mon"
    Struct8Creator = "Contato Struct"
  }
}

locals {
  container_def_alloy-mon_alloy = {
    name      = "alloy"
    image     = "grafana/alloy:v1.3.0"
    essential = true
    memory    = 512
    portMappings = [
      {
        protocol      = "tcp"
        containerPort = 12345
        hostPort      = 12345
      }
    ]
    environment = [
      {
        name  = "NAME"
        value = "alloy-mon"
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
        name  = "AWS_ECS_TASK_DEFINITION_NAME_TEMPO"
        value = "tempo-mon"
      },
      {
        name  = "AWS_ECS_CAPACITY_PROVIDER_NAME_0"
        value = "lgtm-ec2-cp-mon"
      },
      {
        name  = "AWS_ECS_TASK_DEFINITION_NAME_LOKI"
        value = "loki-mon"
      },
      {
        name  = "AWS_PROMETHEUS_WORKSPACE_ENDPOINT_0"
        value = aws_prometheus_workspace.lgtm-amp-mon.prometheus_endpoint
      },
      {
        name  = "AWS_PROMETHEUS_WORKSPACE_ID_0"
        value = aws_prometheus_workspace.lgtm-amp-mon.id
      }
    ]
    mountPoints            = []
    systemControls         = []
    volumesFrom            = []
    command                = ["run", "/etc/alloy/config.alloy"]
    privileged             = false
    readonlyRootFilesystem = false
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.logs-alloy-mon.name
        awslogs-region        = "us-west-2"
        awslogs-stream-prefix = "alloy"
      }
    }
  }
}

resource "aws_ecs_task_definition" "alloy-mon" {
  container_definitions    = jsonencode([local.container_def_alloy-mon_alloy])
  execution_role_arn       = aws_iam_role.execution_role_ecs_alloy-mon.arn
  family                   = "alloy"
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  task_role_arn            = aws_iam_role.task_role_ecs_alloy-mon.arn
  tags = {
    Name           = "alloy-mon"
    State          = "Stateless-mon"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_iam_role_policy_attachment.ecs_task_definition_alloy-mon_st_Stateless-mon_attach, aws_iam_role_policy_attachment.ecs_task_definition_alloy-mon_execution_st_Stateless-mon_attach]
}

locals {
  container_def_grafana-mon_grafana = {
    name         = "grafana"
    image        = "grafana/grafana:11.2.0"
    essential    = true
    memory       = 512
    startTimeout = 30
    stopTimeout  = 30
    portMappings = [
      {
        protocol      = "tcp"
        containerPort = 3000
        hostPort      = 3000
      }
    ]
    environment = [
      {
        name  = "GF_PATHS_PROVISIONING"
        value = "/etc/grafana/provisioning"
      },
      {
        name  = "GF_PATHS_DATA"
        value = "/var/lib/grafana"
      },
      {
        name  = "GF_PATHS_LOGS"
        value = "/var/log/grafana"
      },
      {
        name  = "GF_PATHS_PLUGINS"
        value = "/var/lib/grafana/plugins"
      },
      {
        name  = "GF_SECURITY_ADMIN_USER"
        value = "admin"
      },
      {
        name  = "GF_INSTALL_PLUGINS"
        value = "grafana-clock-panel,grafana-simple-json-datasource"
      },
      {
        name  = "NAME"
        value = "grafana-mon"
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
        value = "lgtm-ec2-cp-mon"
      },
      {
        name  = "AWS_S3_BUCKET_NAME_0"
        value = "lgtm-grafana-config-mon-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.region}-an"
      },
      {
        name  = "AWS_ECS_TASK_DEFINITION_NAME_TEMPO"
        value = "tempo-mon"
      },
      {
        name  = "AWS_ECS_TASK_DEFINITION_NAME_LOKI"
        value = "loki-mon"
      },
      {
        name  = "AWS_PROMETHEUS_WORKSPACE_ENDPOINT_0"
        value = aws_prometheus_workspace.lgtm-amp-mon.prometheus_endpoint
      },
      {
        name  = "AWS_PROMETHEUS_WORKSPACE_ID_0"
        value = aws_prometheus_workspace.lgtm-amp-mon.id
      },
      {
        name  = "AWS_EFS_FILE_SYSTEM_ID_0"
        value = data.aws_efs_file_system.efs-grafana-lgtm-mon.id
      }
    ]
    mountPoints = [
      {
        sourceVolume  = "efs-grafana-lgtm-mon"
        containerPath = "/var/lib/grafana"
        readOnly      = false
      }
    ]
    systemControls         = []
    volumesFrom            = []
    user                   = "472:472"
    privileged             = false
    readonlyRootFilesystem = false
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.logs-grafana-mon.name
        awslogs-region        = "us-west-2"
        awslogs-stream-prefix = "grafana"
      }
    }
  }
}

resource "aws_ecs_task_definition" "grafana-mon" {
  container_definitions    = jsonencode([local.container_def_grafana-mon_grafana])
  execution_role_arn       = aws_iam_role.execution_role_ecs_grafana-mon.arn
  family                   = "grafana"
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  task_role_arn            = aws_iam_role.task_role_ecs_grafana-mon.arn
  tags = {
    Name           = "grafana-mon"
    State          = "Stateless-mon"
    Struct8Creator = "Contato Struct"
  }
  volume {
    name = "efs-grafana-lgtm-mon"
    efs_volume_configuration {
      file_system_id     = data.aws_efs_file_system.efs-grafana-lgtm-mon.id
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.ap_grafana-mon_efs-grafana-lgtm-mon.id
        iam             = "ENABLED"
      }
    }
  }
  depends_on = [aws_iam_role_policy_attachment.ecs_task_definition_grafana-mon_st_Stateless-mon_attach, aws_iam_role_policy_attachment.ecs_task_definition_grafana-mon_execution_st_Stateless-mon_attach]
}

locals {
  container_def_loki-mon_loki = {
    name      = "loki"
    image     = "grafana/loki:3.1.0"
    essential = true
    memory    = 768
    portMappings = [
      {
        protocol      = "tcp"
        containerPort = 3100
        hostPort      = 3100
        name          = "loki-3100"
      }
    ]
    environment = [
      {
        name  = "NAME"
        value = "loki-mon"
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
        value = "lgtm-ec2-cp-mon"
      },
      {
        name  = "AWS_S3_BUCKET_NAME_0"
        value = "lgtm-loki-chunks-mon-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.region}-an"
      }
    ]
    mountPoints            = []
    systemControls         = []
    volumesFrom            = []
    entryPoint             = ["-config.file=/etc/loki/config.yaml"]
    privileged             = false
    readonlyRootFilesystem = false
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.logs-loki-mon.name
        awslogs-region        = "us-west-2"
        awslogs-stream-prefix = "loki"
      }
    }
  }
}

resource "aws_ecs_task_definition" "loki-mon" {
  container_definitions    = jsonencode([local.container_def_loki-mon_loki])
  execution_role_arn       = aws_iam_role.execution_role_ecs_loki-mon.arn
  family                   = "loki"
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  task_role_arn            = aws_iam_role.task_role_ecs_loki-mon.arn
  tags = {
    Name           = "loki-mon"
    State          = "Stateless-mon"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_iam_role_policy_attachment.ecs_task_definition_loki-mon_st_Stateless-mon_attach, aws_iam_role_policy_attachment.ecs_task_definition_loki-mon_execution_st_Stateless-mon_attach]
}

locals {
  container_def_tempo-mon_tempo = {
    name      = "tempo"
    image     = "grafana/tempo:2.5.0"
    essential = true
    memory    = 768
    portMappings = [
      {
        protocol      = "tcp"
        containerPort = 3200
        hostPort      = 3200
        name          = "tempo-3200"
      }
    ]
    environment = [
      {
        name  = "NAME"
        value = "tempo-mon"
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
        value = "lgtm-ec2-cp-mon"
      },
      {
        name  = "AWS_S3_BUCKET_NAME_0"
        value = "lgtm-tempo-blocks-mon-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.region}-an"
      }
    ]
    mountPoints            = []
    systemControls         = []
    volumesFrom            = []
    entryPoint             = ["-config.file=/etc/tempo/config.yaml"]
    privileged             = false
    readonlyRootFilesystem = false
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.logs-tempo-mon.name
        awslogs-region        = "us-west-2"
        awslogs-stream-prefix = "tempo"
      }
    }
  }
}

resource "aws_ecs_task_definition" "tempo-mon" {
  container_definitions    = jsonencode([local.container_def_tempo-mon_tempo])
  execution_role_arn       = aws_iam_role.execution_role_ecs_tempo-mon.arn
  family                   = "tempo"
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  task_role_arn            = aws_iam_role.task_role_ecs_tempo-mon.arn
  tags = {
    Name           = "tempo-mon"
    State          = "Stateless-mon"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_iam_role_policy_attachment.ecs_task_definition_tempo-mon_st_Stateless-mon_attach, aws_iam_role_policy_attachment.ecs_task_definition_tempo-mon_execution_st_Stateless-mon_attach]
}




### CATEGORY: MONITORING ###

resource "aws_cloudwatch_log_group" "logs-alloy-mon" {
  name              = "/aws/ecs/alloy-mon"
  log_group_class   = "STANDARD"
  retention_in_days = 7
  skip_destroy      = false
  tags = {
    Name           = "logs-alloy-mon"
    State          = "Stateless-mon"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_cloudwatch_log_group" "logs-grafana-mon" {
  name              = "/aws/ecs/grafana-mon"
  log_group_class   = "STANDARD"
  retention_in_days = 7
  skip_destroy      = false
  tags = {
    Name           = "logs-grafana-mon"
    State          = "Stateless-mon"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_cloudwatch_log_group" "logs-loki-mon" {
  name              = "/aws/ecs/loki-mon"
  log_group_class   = "STANDARD"
  retention_in_days = 7
  skip_destroy      = false
  tags = {
    Name           = "logs-loki-mon"
    State          = "Stateless-mon"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_cloudwatch_log_group" "logs-tempo-mon" {
  name              = "/aws/ecs/tempo-mon"
  log_group_class   = "STANDARD"
  retention_in_days = 7
  skip_destroy      = false
  tags = {
    Name           = "logs-tempo-mon"
    State          = "Stateless-mon"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_prometheus_workspace" "lgtm-amp-mon" {
  alias = "lgtm-amp-mon"
  tags = {
    Name           = "lgtm-amp-mon"
    State          = "Stateless-mon"
    Struct8Creator = "Contato Struct"
  }
}




### CATEGORY: MISC ###

resource "null_resource" "cleanup_lgtm-cluster-mon" {
  triggers = {
    cluster_name = aws_ecs_cluster.lgtm-cluster-mon.name
  }
  depends_on = [aws_ecs_cluster.lgtm-cluster-mon, aws_autoscaling_group.lgtm-ecs-asg-mon, aws_ecs_capacity_provider.lgtm-ec2-cp-mon]
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
        ASGS="lgtm-ecs-asg-mon"
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


