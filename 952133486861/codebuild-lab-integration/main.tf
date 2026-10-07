terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  backend "s3" {
    bucket  = "struct8-import"
    key     = "952133486861/codebuild-lab-integration/main.tfstate"
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

data "aws_codestarconnections_connection" "codebuild-lab-github" {
  name = "codebuild-lab-github"
}

data "aws_iam_role" "role_eventbridge_codebuild-lab-release-succeeded" {
  name = "role_eventbridge_codebuild-lab-release-succeeded"
}




### CATEGORY: IAM ###

data "aws_iam_policy_document" "cloudwatch_event_rule_codebuild-lab-nightly_st_codebuild-lab-integration_doc" {
  statement {
    sid       = "AllowEventBridgeToStartBuild"
    effect    = "Allow"
    actions   = ["codebuild:StartBuild"]
    resources = [aws_codebuild_project.codebuild-lab-integration.arn]
  }
}

resource "aws_iam_policy" "cloudwatch_event_rule_codebuild-lab-nightly_st_codebuild-lab-integration" {
  name        = "cloudwatch_event_rule_codebuild-lab-nightly_st_codebuild-lab-integration"
  description = "Access Policy for codebuild-lab-nightly"
  policy      = data.aws_iam_policy_document.cloudwatch_event_rule_codebuild-lab-nightly_st_codebuild-lab-integration_doc.json
}

data "aws_iam_policy_document" "cloudwatch_event_rule_codebuild-lab-release-succeeded_st_codebuild-lab-ci_doc" {
  statement {
    sid       = "AllowEventBridgeToStartBuild"
    effect    = "Allow"
    actions   = ["codebuild:StartBuild"]
    resources = [aws_codebuild_project.codebuild-lab-integration.arn]
  }
}

resource "aws_iam_policy" "cloudwatch_event_rule_codebuild-lab-release-succeeded_st_codebuild-lab-ci" {
  name        = "cloudwatch_event_rule_codebuild-lab-release-succeeded_st_codebuild-lab-ci"
  description = "Access Policy for codebuild-lab-release-succeeded"
  policy      = data.aws_iam_policy_document.cloudwatch_event_rule_codebuild-lab-release-succeeded_st_codebuild-lab-ci_doc.json
}

data "aws_iam_policy_document" "codebuild_project_codebuild-lab-integration_st_codebuild-lab-integration_doc" {
  statement {
    sid       = "AllowWriteLogs"
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.codebuild-lab-integration-logs.arn}:*"]
  }
  statement {
    sid       = "AllowUseOfConnection"
    effect    = "Allow"
    actions   = ["codeconnections:GetConnection", "codeconnections:GetConnectionToken", "codestar-connections:GetConnection", "codestar-connections:GetConnectionToken"]
    resources = [data.aws_codestarconnections_connection.codebuild-lab-github.arn]
  }
  statement {
    sid       = "AllowRDSSecretAccesscodebuildlabordersdb"
    effect    = "Allow"
    actions   = ["secretsmanager:DescribeSecret", "secretsmanager:GetSecretValue"]
    resources = [aws_db_instance.codebuild-lab-orders-db.master_user_secret[0].secret_arn]
  }
  statement {
    sid       = "DescribeAndManageNetworkInterfaces"
    effect    = "Allow"
    actions   = ["ec2:CreateNetworkInterface", "ec2:DeleteNetworkInterface", "ec2:DescribeDhcpOptions", "ec2:DescribeNetworkInterfaces", "ec2:DescribeSecurityGroups", "ec2:DescribeSubnets", "ec2:DescribeVpcs"]
    resources = ["*"]
  }
  statement {
    sid       = "PublishTestReportsOfThisProject"
    effect    = "Allow"
    actions   = ["codebuild:BatchPutCodeCoverages", "codebuild:BatchPutTestCases", "codebuild:CreateReport", "codebuild:CreateReportGroup", "codebuild:UpdateReport"]
    resources = ["arn:aws:codebuild:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:report-group/codebuild-lab-integration-*"]
  }
  statement {
    sid       = "AttachNetworkInterfacesInTheProjectSubnets"
    effect    = "Allow"
    actions   = ["ec2:CreateNetworkInterfacePermission"]
    resources = ["arn:aws:ec2:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:network-interface/*"]
    condition {
      test     = "StringEquals"
      variable = "ec2:Subnet"
      values   = [aws_subnet.codebuild-lab-build-a.arn, aws_subnet.codebuild-lab-build-b.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "ec2:AuthorizedService"
      values   = ["codebuild.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "codebuild_project_codebuild-lab-integration_st_codebuild-lab-integration" {
  name        = "codebuild_project_codebuild-lab-integration_st_codebuild-lab-integration"
  description = "Access Policy for codebuild-lab-integration"
  policy      = data.aws_iam_policy_document.codebuild_project_codebuild-lab-integration_st_codebuild-lab-integration_doc.json
}

resource "aws_iam_role" "codebuild-lab-integration_role" {
  name = "codebuild-lab-integration_role"
  assume_role_policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      }
    }
  ]
})
  force_detach_policies = false
  max_session_duration  = 3600
  path                  = "/"
  tags = {
    Name           = "codebuild-lab-integration_role"
    State          = "codebuild-lab-integration"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "role_eventbridge_codebuild-lab-nightly" {
  name = "role_eventbridge_codebuild-lab-nightly"
  assume_role_policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": "events.amazonaws.com"
      }
    }
  ]
})
  tags = {
    Name           = "role_eventbridge_codebuild-lab-nightly"
    State          = "codebuild-lab-integration"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role_policy_attachment" "cloudwatch_event_rule_codebuild-lab-nightly_st_codebuild-lab-integration_attach" {
  policy_arn = aws_iam_policy.cloudwatch_event_rule_codebuild-lab-nightly_st_codebuild-lab-integration.arn
  role       = aws_iam_role.role_eventbridge_codebuild-lab-nightly.name
}

resource "aws_iam_role_policy_attachment" "cloudwatch_event_rule_codebuild-lab-release-succeeded_st_codebuild-lab-ci_attach" {
  policy_arn = aws_iam_policy.cloudwatch_event_rule_codebuild-lab-release-succeeded_st_codebuild-lab-ci.arn
  role       = data.aws_iam_role.role_eventbridge_codebuild-lab-release-succeeded.name
}

resource "aws_iam_role_policy_attachment" "codebuild_project_codebuild-lab-integration_st_codebuild-lab-integration_attach" {
  policy_arn = aws_iam_policy.codebuild_project_codebuild-lab-integration_st_codebuild-lab-integration.arn
  role       = aws_iam_role.codebuild-lab-integration_role.name
}




### CATEGORY: NETWORK ###

resource "aws_vpc" "codebuild-lab-vpc" {
  cidr_block       = "10.6.0.0/16"
  instance_tenancy = "default"
  tags = {
    Name           = "codebuild-lab-vpc"
    State          = "codebuild-lab-integration"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "codebuild-lab-build-a" {
  vpc_id                  = aws_vpc.codebuild-lab-vpc.id
  availability_zone       = "us-west-2a"
  cidr_block              = "10.6.2.0/24"
  map_public_ip_on_launch = false
  tags = {
    Name           = "codebuild-lab-build-a"
    State          = "codebuild-lab-integration"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "codebuild-lab-build-b" {
  vpc_id                  = aws_vpc.codebuild-lab-vpc.id
  availability_zone       = "us-west-2b"
  cidr_block              = "10.6.3.0/24"
  map_public_ip_on_launch = false
  tags = {
    Name           = "codebuild-lab-build-b"
    State          = "codebuild-lab-integration"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "codebuild-lab-db-a" {
  vpc_id                  = aws_vpc.codebuild-lab-vpc.id
  availability_zone       = "us-west-2a"
  cidr_block              = "10.6.0.0/24"
  map_public_ip_on_launch = false
  tags = {
    Name           = "codebuild-lab-db-a"
    State          = "codebuild-lab-integration"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "codebuild-lab-db-b" {
  vpc_id                  = aws_vpc.codebuild-lab-vpc.id
  availability_zone       = "us-west-2b"
  cidr_block              = "10.6.1.0/24"
  map_public_ip_on_launch = false
  tags = {
    Name           = "codebuild-lab-db-b"
    State          = "codebuild-lab-integration"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_internet_gateway" "codebuild-lab-igw" {
  vpc_id = aws_vpc.codebuild-lab-vpc.id
  tags = {
    Name           = "codebuild-lab-igw"
    State          = "codebuild-lab-integration"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_nat_gateway" "codebuild-lab-nat" {
  vpc_id            = aws_vpc.codebuild-lab-vpc.id
  availability_mode = "regional"
  connectivity_type = "public"
  tags = {
    Name           = "codebuild-lab-nat"
    State          = "codebuild-lab-integration"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_internet_gateway.codebuild-lab-igw]
}

resource "aws_route" "route_codebuild-lab-build-rt_to_codebuild-lab-nat_ipv4" {
  nat_gateway_id         = aws_nat_gateway.codebuild-lab-nat.id
  route_table_id         = aws_route_table.codebuild-lab-build-rt.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table" "codebuild-lab-build-rt" {
  vpc_id = aws_vpc.codebuild-lab-vpc.id
  tags = {
    Name           = "codebuild-lab-build-rt"
    State          = "codebuild-lab-integration"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route_table_association" "aws_route_table_association_codebuild_lab_build_a_codebuild_lab_build_rt" {
  route_table_id = aws_route_table.codebuild-lab-build-rt.id
  subnet_id      = aws_subnet.codebuild-lab-build-a.id
}

resource "aws_route_table_association" "aws_route_table_association_codebuild_lab_build_b_codebuild_lab_build_rt" {
  route_table_id = aws_route_table.codebuild-lab-build-rt.id
  subnet_id      = aws_subnet.codebuild-lab-build-b.id
}

resource "aws_security_group" "codebuild_project_codebuild-lab-integration_group" {
  name                   = "codebuild_project_codebuild-lab-integration_group"
  vpc_id                 = aws_vpc.codebuild-lab-vpc.id
  description            = "CodeBuild integration project"
  revoke_rules_on_delete = false
  tags = {
    Name           = "codebuild_project_codebuild-lab-integration_group"
    State          = "codebuild-lab-integration"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group" "db_instance_codebuild-lab-orders-db_group" {
  name                   = "db_instance_codebuild-lab-orders-db_group"
  vpc_id                 = aws_vpc.codebuild-lab-vpc.id
  revoke_rules_on_delete = false
  tags = {
    Name           = "db_instance_codebuild-lab-orders-db_group"
    State          = "codebuild-lab-integration"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group_rule" "rule_codebuild_project_codebuild_lab_integration_group_egress_all_protocols" {
  security_group_id = aws_security_group.codebuild_project_codebuild-lab-integration_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "rule_codebuild_project_codebuild_lab_integration_group_to_db_instance_codebuild_lab_orders_db_group_tcp_5432" {
  security_group_id        = aws_security_group.db_instance_codebuild-lab-orders-db_group.id
  source_security_group_id = aws_security_group.codebuild_project_codebuild-lab-integration_group.id
  description              = "PostgreSQL from the integration builds"
  from_port                = 5432
  protocol                 = "tcp"
  to_port                  = 5432
  type                     = "ingress"
}

resource "aws_security_group_rule" "rule_db_instance_codebuild_lab_orders_db_group_egress_all_protocols" {
  security_group_id = aws_security_group.db_instance_codebuild-lab-orders-db_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}




### CATEGORY: DATABASE ###

resource "aws_db_instance" "codebuild-lab-orders-db" {
  db_name                     = "orders"
  db_subnet_group_name        = aws_db_subnet_group.subnet_group_codebuild-lab-orders-db.name
  allocated_storage           = 20
  availability_zone           = aws_subnet.codebuild-lab-db-a.availability_zone
  backup_retention_period     = 0
  copy_tags_to_snapshot       = true
  delete_automated_backups    = false
  engine                      = "postgres"
  engine_lifecycle_support    = "open-source-rds-extended-support-disabled"
  engine_version              = "16"
  identifier                  = "codebuild-lab-orders-db"
  instance_class              = "db.t4g.micro"
  manage_master_user_password = true
  max_allocated_storage       = 100
  port                        = 5432
  skip_final_snapshot         = true
  storage_encrypted           = true
  storage_type                = "gp3"
  upgrade_storage_config      = false
  username                    = "orders"
  vpc_security_group_ids      = [aws_security_group.db_instance_codebuild-lab-orders-db_group.id]
  tags = {
    Name           = "codebuild-lab-orders-db"
    State          = "codebuild-lab-integration"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_db_subnet_group" "subnet_group_codebuild-lab-orders-db" {
  name       = "codebuild-lab-orders-db-subnet-group"
  subnet_ids = [aws_subnet.codebuild-lab-db-a.id, aws_subnet.codebuild-lab-db-b.id]
  tags = {
    Name           = "subnet_group_codebuild-lab-orders-db"
    State          = "codebuild-lab-integration"
    Struct8Creator = "Contato Struct"
  }
}




### CATEGORY: INTEGRATION ###

resource "aws_cloudwatch_event_rule" "codebuild-lab-nightly" {
  name                = "codebuild-lab-nightly"
  description         = "Runs the integration tests every day at 00:00 UTC."
  schedule_expression = "cron(0 0 * * ? *)"
  state               = "ENABLED"
  tags = {
    Name           = "codebuild-lab-nightly"
    State          = "codebuild-lab-integration"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_cloudwatch_event_target" "nightly-integration" {
  arn      = aws_codebuild_project.codebuild-lab-integration.arn
  role_arn = aws_iam_role.role_eventbridge_codebuild-lab-nightly.arn
  rule     = aws_cloudwatch_event_rule.codebuild-lab-nightly.name
}




### CATEGORY: MONITORING ###

resource "aws_cloudwatch_log_group" "codebuild-lab-integration-logs" {
  name              = "/aws/codebuild/codebuild-lab-integration"
  log_group_class   = "STANDARD"
  retention_in_days = 14
  skip_destroy      = false
  tags = {
    Name           = "codebuild-lab-integration-logs"
    State          = "codebuild-lab-integration"
    Struct8Creator = "Contato Struct"
  }
}




### CATEGORY: DEVTOOLS ###

resource "aws_codebuild_project" "codebuild-lab-integration" {
  source {
    buildspec           = "buildspec/integration.yml"
    git_clone_depth     = 1
    location            = "https://github.com/Struct8/codebuild-lab.git"
    report_build_status = false
    type                = "GITHUB"
    auth {
      resource = data.aws_codestarconnections_connection.codebuild-lab-github.arn
      type     = "CODECONNECTIONS"
    }
  }
  name             = "codebuild-lab-integration"
  auto_retry_limit = 1
  build_timeout    = 20
  description      = "Migrations and integration tests against PostgreSQL inside the VPC."
  service_role     = aws_iam_role.codebuild-lab-integration_role.arn
  artifacts {
    type = "NO_ARTIFACTS"
  }
  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/amazonlinux-x86_64-standard:6.0"
    type         = "LINUX_CONTAINER"
    environment_variable {
      name  = "NAME"
      type  = "PLAINTEXT"
      value = "codebuild-lab-integration"
    }
    environment_variable {
      name  = "REGION"
      type  = "PLAINTEXT"
      value = data.aws_region.current.region
    }
    environment_variable {
      name  = "ACCOUNT"
      type  = "PLAINTEXT"
      value = data.aws_caller_identity.current.account_id
    }
    environment_variable {
      name  = "AWS_DB_INSTANCE_NAME_0"
      type  = "PLAINTEXT"
      value = aws_db_instance.codebuild-lab-orders-db.identifier
    }
    environment_variable {
      name  = "AWS_DB_INSTANCE_ENGINE_0"
      type  = "PLAINTEXT"
      value = aws_db_instance.codebuild-lab-orders-db.engine
    }
    environment_variable {
      name  = "AWS_DB_INSTANCE_ENDPOINT_0"
      type  = "PLAINTEXT"
      value = aws_db_instance.codebuild-lab-orders-db.endpoint
    }
    environment_variable {
      name  = "AWS_DB_INSTANCE_DB_NAME_0"
      type  = "PLAINTEXT"
      value = aws_db_instance.codebuild-lab-orders-db.db_name
    }
    environment_variable {
      name  = "AWS_DB_INSTANCE_SECRET_ARN_0"
      type  = "PLAINTEXT"
      value = one(aws_db_instance.codebuild-lab-orders-db.master_user_secret[*].secret_arn)
    }
    environment_variable {
      name  = "AWS_DB_INSTANCE_USER_NAME_0"
      type  = "PLAINTEXT"
      value = "${one(aws_db_instance.codebuild-lab-orders-db.master_user_secret[*].secret_arn)}:username::"
    }
    environment_variable {
      name  = "AWS_CODECONNECTIONS_CONNECTION_ARN_0"
      type  = "PLAINTEXT"
      value = data.aws_codestarconnections_connection.codebuild-lab-github.arn
    }
    environment_variable {
      name  = "AWS_CODECONNECTIONS_CONNECTION_NAME_0"
      type  = "PLAINTEXT"
      value = data.aws_codestarconnections_connection.codebuild-lab-github.name
    }
  }
  logs_config {
    cloudwatch_logs {
      group_name = aws_cloudwatch_log_group.codebuild-lab-integration-logs.name
      status     = "ENABLED"
    }
  }
  tags = {
    Name           = "codebuild-lab-integration"
    State          = "codebuild-lab-integration"
    Struct8Creator = "Contato Struct"
  }
  vpc_config {
    vpc_id             = aws_subnet.codebuild-lab-build-a.vpc_id
    security_group_ids = [aws_security_group.codebuild_project_codebuild-lab-integration_group.id]
    subnets            = [aws_subnet.codebuild-lab-build-a.id, aws_subnet.codebuild-lab-build-b.id]
  }
  depends_on = [aws_iam_role_policy_attachment.codebuild_project_codebuild-lab-integration_st_codebuild-lab-integration_attach]
}


