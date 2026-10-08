terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  backend "s3" {
    bucket  = "struct8-import"
    key     = "952133486861/aws-backup-lab/main.tfstate"
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

data "aws_iam_policy_document" "ecs_task_definition_efs-writer_execution_st_aws-backup-lab_doc" {
  statement {
    sid       = "AllowWriteLogs"
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.logs-efs-writer.arn}:*"]
  }
}

resource "aws_iam_policy" "ecs_task_definition_efs-writer_execution_st_aws-backup-lab" {
  name        = "ecs_task_definition_efs-writer_execution_st_aws-backup-lab"
  description = "Access Policy for efs-writer (Role: execution)"
  policy      = data.aws_iam_policy_document.ecs_task_definition_efs-writer_execution_st_aws-backup-lab_doc.json
}

data "aws_iam_policy_document" "ecs_task_definition_efs-writer_st_aws-backup-lab_doc" {
  statement {
    sid       = "AllowPutAndCountItems"
    effect    = "Allow"
    actions   = ["dynamodb:PutItem", "dynamodb:Scan"]
    resources = [aws_dynamodb_table.lab-orders.arn, "${aws_dynamodb_table.lab-orders.arn}/*"]
  }
  statement {
    sid       = "AllowEFSBasicAccess"
    effect    = "Allow"
    actions   = ["elasticfilesystem:ClientMount", "elasticfilesystem:ClientRootAccess", "elasticfilesystem:ClientWrite"]
    resources = ["${aws_efs_file_system.lab-data.arn}:*"]
  }
}

resource "aws_iam_policy" "ecs_task_definition_efs-writer_st_aws-backup-lab" {
  name        = "ecs_task_definition_efs-writer_st_aws-backup-lab"
  description = "Access Policy for efs-writer"
  policy      = data.aws_iam_policy_document.ecs_task_definition_efs-writer_st_aws-backup-lab_doc.json
}

data "aws_iam_policy_document" "scheduler_schedule_efs-writer-every-5-min_st_aws-backup-lab_doc" {
  statement {
    sid       = "AllowSchedulerToRunTask"
    effect    = "Allow"
    actions   = ["ecs:RunTask"]
    resources = ["${aws_ecs_task_definition.efs-writer.arn_without_revision}:*"]
  }
  statement {
    sid       = "AllowSchedulerToPassTaskRoles"
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = [aws_ecs_task_definition.efs-writer.execution_role_arn, aws_ecs_task_definition.efs-writer.task_role_arn]
  }
}

resource "aws_iam_policy" "scheduler_schedule_efs-writer-every-5-min_st_aws-backup-lab" {
  name        = "scheduler_schedule_efs-writer-every-5-min_st_aws-backup-lab"
  description = "Access Policy for efs-writer-every-5-min"
  policy      = data.aws_iam_policy_document.scheduler_schedule_efs-writer-every-5-min_st_aws-backup-lab_doc.json
}

resource "aws_iam_role" "backup-lab-hourly_backup_role" {
  name = "backup-lab-hourly-8ee55440-backup"
  assume_role_policy = jsonencode({
  Version = "2012-10-17"
  Statement = [{
    Effect    = "Allow"
    Principal = { Service = "backup.amazonaws.com" }
    Action    = "sts:AssumeRole"
  }]
})
  tags = {
    Name           = "backup-lab-hourly_backup_role"
    State          = "aws-backup-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "efs-writer-every-5-min_role" {
  name = "efs-writer-every-5-min_role"
  assume_role_policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": "scheduler.amazonaws.com"
      }
    }
  ]
})
  force_detach_policies = false
  max_session_duration  = 3600
  path                  = "/"
  tags = {
    Name           = "efs-writer-every-5-min_role"
    State          = "aws-backup-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "execution_role_ecs_efs-writer" {
  name = "execution_role_ecs_efs-writer"
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
    Name           = "execution_role_ecs_efs-writer"
    State          = "aws-backup-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "task_role_ecs_efs-writer" {
  name = "task_role_ecs_efs-writer"
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
    Name           = "task_role_ecs_efs-writer"
    State          = "aws-backup-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role_policy_attachment" "backup-lab-hourly_backup_role_backup" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
  role       = aws_iam_role.backup-lab-hourly_backup_role.name
}

resource "aws_iam_role_policy_attachment" "backup-lab-hourly_backup_role_restores" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
  role       = aws_iam_role.backup-lab-hourly_backup_role.name
}

resource "aws_iam_role_policy_attachment" "backup-lab-hourly_backup_role_s3_backup" {
  policy_arn = "arn:aws:iam::aws:policy/AWSBackupServiceRolePolicyForS3Backup"
  role       = aws_iam_role.backup-lab-hourly_backup_role.name
}

resource "aws_iam_role_policy_attachment" "backup-lab-hourly_backup_role_s3_restore" {
  policy_arn = "arn:aws:iam::aws:policy/AWSBackupServiceRolePolicyForS3Restore"
  role       = aws_iam_role.backup-lab-hourly_backup_role.name
}

resource "aws_iam_role_policy_attachment" "ecs_task_definition_efs-writer_execution_st_aws-backup-lab_attach" {
  policy_arn = aws_iam_policy.ecs_task_definition_efs-writer_execution_st_aws-backup-lab.arn
  role       = aws_iam_role.execution_role_ecs_efs-writer.name
}

resource "aws_iam_role_policy_attachment" "ecs_task_definition_efs-writer_st_aws-backup-lab_attach" {
  policy_arn = aws_iam_policy.ecs_task_definition_efs-writer_st_aws-backup-lab.arn
  role       = aws_iam_role.task_role_ecs_efs-writer.name
}

resource "aws_iam_role_policy_attachment" "scheduler_schedule_efs-writer-every-5-min_st_aws-backup-lab_attach" {
  policy_arn = aws_iam_policy.scheduler_schedule_efs-writer-every-5-min_st_aws-backup-lab.arn
  role       = aws_iam_role.efs-writer-every-5-min_role.name
}




### CATEGORY: NETWORK ###

resource "aws_vpc" "aws-backup-lab" {
  cidr_block           = "10.21.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default"
  tags = {
    Name           = "aws-backup-lab"
    State          = "aws-backup-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "pubA1" {
  vpc_id                  = aws_vpc.aws-backup-lab.id
  availability_zone       = "us-west-2a"
  cidr_block              = "10.21.1.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name           = "pubA1"
    State          = "aws-backup-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_internet_gateway" "igw-backup-lab" {
  vpc_id = aws_vpc.aws-backup-lab.id
  tags = {
    Name           = "igw-backup-lab"
    State          = "aws-backup-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route" "route_rt-public-backup-lab_to_igw-backup-lab_ipv4" {
  gateway_id             = aws_internet_gateway.igw-backup-lab.id
  route_table_id         = aws_route_table.rt-public-backup-lab.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table" "rt-public-backup-lab" {
  vpc_id = aws_vpc.aws-backup-lab.id
  tags = {
    Name           = "rt-public-backup-lab"
    State          = "aws-backup-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route_table_association" "aws_route_table_association_pubA1_rt_public_backup_lab" {
  route_table_id = aws_route_table.rt-public-backup-lab.id
  subnet_id      = aws_subnet.pubA1.id
}

resource "aws_security_group" "ecs_task_definition_efs-writer_group" {
  name                   = "ecs_task_definition_efs-writer_group"
  vpc_id                 = aws_vpc.aws-backup-lab.id
  revoke_rules_on_delete = false
  tags = {
    Name           = "ecs_task_definition_efs-writer_group"
    State          = "aws-backup-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group" "efs_file_system_lab-data_group" {
  name                   = "efs_file_system_lab-data_group"
  vpc_id                 = aws_vpc.aws-backup-lab.id
  revoke_rules_on_delete = false
  tags = {
    Name           = "efs_file_system_lab-data_group"
    State          = "aws-backup-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group_rule" "rule_ecs_task_definition_efs_writer_group_egress_all_protocols" {
  security_group_id = aws_security_group.ecs_task_definition_efs-writer_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "rule_ecs_task_definition_efs_writer_group_to_efs_file_system_lab_data_group_tcp_2049" {
  security_group_id        = aws_security_group.efs_file_system_lab-data_group.id
  source_security_group_id = aws_security_group.ecs_task_definition_efs-writer_group.id
  description              = "Allow from ecs_task_definition_efs-writer_group (tcp:2049-2049)"
  from_port                = 2049
  protocol                 = "tcp"
  to_port                  = 2049
  type                     = "ingress"
}

resource "aws_security_group_rule" "rule_efs_file_system_lab_data_group_egress_all_protocols" {
  security_group_id = aws_security_group.efs_file_system_lab-data_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}




### CATEGORY: STORAGE ###

resource "aws_s3_bucket" "backup-lab-docs" {
  bucket              = "backup-lab-docs-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.region}-an"
  bucket_namespace    = "account-regional"
  force_destroy       = true
  object_lock_enabled = false
  tags = {
    "Struct8:Backup:backup-lab-hourly-8ee55440" = true
    Name                                        = "backup-lab-docs"
    State                                       = "aws-backup-lab"
    Struct8Creator                              = "Contato Struct"
  }
}

resource "aws_s3_bucket_ownership_controls" "backup-lab-docs_controls" {
  bucket = aws_s3_bucket.backup-lab-docs.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "backup-lab-docs_block" {
  block_public_acls       = true
  block_public_policy     = true
  bucket                  = aws_s3_bucket.backup-lab-docs.id
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "backup-lab-docs_configuration" {
  bucket = aws_s3_bucket.backup-lab-docs.id
  rule {
    bucket_key_enabled = true
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "backup-lab-docs_versioning" {
  bucket = aws_s3_bucket.backup-lab-docs.id
  versioning_configuration {
    mfa_delete = "Disabled"
    status     = "Enabled"
  }
}

resource "aws_s3_object" "doc-readme" {
  acl          = "private"
  bucket       = aws_s3_bucket.backup-lab-docs.bucket
  content      = "AWS Backup lab. This file was created by Terraform when the lab was applied."
  content_type = "text/plain"
  key          = "docs/readme.txt"
  tags = {
    Name           = "doc-readme"
    State          = "aws-backup-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_s3_object" "doc-report" {
  acl    = "private"
  bucket = aws_s3_bucket.backup-lab-docs.bucket
  content = <<EOF
order_id;customer;total
1001;Ana;129.90
1002;Bruno;54.00
1003;Carla;310.50
  EOF
  content_type = "text/csv"
  key          = "docs/report.csv"
  tags = {
    Name           = "doc-report"
    State          = "aws-backup-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_efs_access_point" "ap_efs-writer_lab-data" {
  file_system_id = aws_efs_file_system.lab-data.id
  posix_user {
    gid = "0"
    uid = "0"
  }
  root_directory {
    path = "/"
  }
  tags = {
    Name           = "ap_efs-writer_lab-data"
    State          = "aws-backup-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_efs_backup_policy" "lab-data_backup_policy" {
  file_system_id = aws_efs_file_system.lab-data.id
  backup_policy {
    status = "DISABLED"
  }
}

resource "aws_efs_file_system" "lab-data" {
  availability_zone_name = "us-west-2a"
  encrypted              = true
  throughput_mode        = "elastic"
  tags = {
    "Struct8:Backup:backup-lab-hourly-8ee55440" = true
    Name                                        = "lab-data"
    State                                       = "aws-backup-lab"
    Struct8Creator                              = "Contato Struct"
  }
}

resource "aws_efs_mount_target" "mt_lab-data_pubA1" {
  file_system_id  = aws_efs_file_system.lab-data.id
  subnet_id       = aws_subnet.pubA1.id
  security_groups = [aws_security_group.efs_file_system_lab-data_group.id]
}

resource "aws_backup_plan" "backup-lab-hourly" {
  name = "backup-lab-hourly"
  rule {
    rule_name         = "hourly"
    target_vault_name = aws_backup_vault.backup-lab-vault.name
    completion_window = 120
    schedule          = "cron(0 * * * ? *)"
    start_window      = 60
    lifecycle {
      delete_after = 1
    }
  }
  tags = {
    Name           = "backup-lab-hourly"
    State          = "aws-backup-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_backup_selection" "backup-lab-hourly_selection" {
  name      = "backup-lab-hourly-8ee55440-resources"
  plan_id   = aws_backup_plan.backup-lab-hourly.id
  resources = ["arn:aws:dynamodb:*:*:table/*", "arn:aws:elasticfilesystem:*:*:file-system/*", "arn:aws:s3:::*"]
  condition {
    string_equals {
      key   = "aws:ResourceTag/Struct8:Backup:backup-lab-hourly-8ee55440"
      value = true
    }
  }
  iam_role_arn = aws_iam_role.backup-lab-hourly_backup_role.arn
}

resource "aws_backup_vault" "backup-lab-vault" {
  name          = "backup-lab-vault"
  force_destroy = true
  tags = {
    Name           = "backup-lab-vault"
    State          = "aws-backup-lab"
    Struct8Creator = "Contato Struct"
  }
}




### CATEGORY: DATABASE ###

resource "aws_dynamodb_table" "lab-orders" {
  name                        = "lab-orders"
  billing_mode                = "PAY_PER_REQUEST"
  deletion_protection_enabled = false
  hash_key                    = "order_id"
  stream_enabled              = false
  table_class                 = "STANDARD"
  attribute {
    name = "order_id"
    type = "S"
  }
  tags = {
    "Struct8:Backup:backup-lab-hourly-8ee55440" = true
    Name                                        = "lab-orders"
    State                                       = "aws-backup-lab"
    Struct8Creator                              = "Contato Struct"
  }
}




### CATEGORY: CONTAINERS ###

resource "aws_ecs_cluster" "backup-lab-cluster" {
  name = "backup-lab-cluster"
  tags = {
    Name           = "backup-lab-cluster"
    State          = "aws-backup-lab"
    Struct8Creator = "Contato Struct"
  }
}

locals {
  container_def_efs-writer_efs-writer_1 = {
    name      = "efs-writer"
    image     = "public.ecr.aws/aws-cli/aws-cli:latest"
    essential = true
    cpu       = 256
    memory    = 512
    environment = [
      {
        name  = "NAME"
        value = "efs-writer"
      },
      {
        name  = "REGION"
        value = tostring(data.aws_region.current.region)
      },
      {
        name  = "ACCOUNT"
        value = tostring(data.aws_caller_identity.current.account_id)
      },
      {
        name  = "AWS_EFS_FILE_SYSTEM_ID_0"
        value = tostring(aws_efs_file_system.lab-data.id)
      },
      {
        name  = "AWS_DYNAMODB_TABLE_NAME_0"
        value = "lab-orders"
      }
    ]
    mountPoints = [
      {
        sourceVolume  = "lab-data"
        containerPath = "/mnt/efs"
        readOnly      = false
      }
    ]
    systemControls         = []
    volumesFrom            = []
    command                = ["set -e; T=$AWS_DYNAMODB_TABLE_NAME_0; test -n \"$T\" || { echo \"AWS_DYNAMODB_TABLE_NAME_0 is not set\"; exit 1; }; D=/mnt/efs/writer; mkdir -p $D; TS=$(date -u +%Y%m%dT%H%M%SZ); echo \"efs-writer run at $TS\" > $D/$TS.txt; echo $TS >> /mnt/efs/runs.log; N=$(ls $D | wc -l); echo \"files in $D: $N\"; CUST=$(echo alice bruno carla diego | cut -d' ' -f$((RANDOM % 4 + 1))); AMT=$(printf '%d.%02d' $((RANDOM % 900 + 10)) $((RANDOM % 100))); aws dynamodb put-item --table-name \"$T\" --item \"{\\\"order_id\\\":{\\\"S\\\":\\\"run-$TS\\\"},\\\"customer\\\":{\\\"S\\\":\\\"$CUST\\\"},\\\"amount\\\":{\\\"N\\\":\\\"$AMT\\\"},\\\"created_at\\\":{\\\"S\\\":\\\"$TS\\\"},\\\"efs_files\\\":{\\\"N\\\":\\\"$N\\\"}}\"; echo \"item run-$TS written to $T: $CUST $AMT\"; echo \"items in $T: $(aws dynamodb scan --table-name \"$T\" --select COUNT --query Count --output text)\"; echo \"root of the file system:\"; ls -la /mnt/efs"]
    entryPoint             = ["/bin/bash", "-c"]
    privileged             = false
    readonlyRootFilesystem = false
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.logs-efs-writer.name
        awslogs-region        = "us-west-2"
        awslogs-stream-prefix = "efs-writer"
      }
    }
  }
}

resource "aws_ecs_task_definition" "efs-writer" {
  container_definitions    = jsonencode([local.container_def_efs-writer_efs-writer_1])
  cpu                      = "256"
  execution_role_arn       = aws_iam_role.execution_role_ecs_efs-writer.arn
  family                   = "efs-writer"
  memory                   = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  task_role_arn            = aws_iam_role.task_role_ecs_efs-writer.arn
  runtime_platform {
    cpu_architecture        = "ARM64"
    operating_system_family = "LINUX"
  }
  tags = {
    Name           = "efs-writer"
    State          = "aws-backup-lab"
    Struct8Creator = "Contato Struct"
  }
  volume {
    name = "lab-data"
    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.lab-data.id
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.ap_efs-writer_lab-data.id
        iam             = "ENABLED"
      }
    }
  }
  depends_on = [aws_iam_role_policy_attachment.ecs_task_definition_efs-writer_st_aws-backup-lab_attach, aws_iam_role_policy_attachment.ecs_task_definition_efs-writer_execution_st_aws-backup-lab_attach]
}




### CATEGORY: INTEGRATION ###

resource "aws_scheduler_schedule" "efs-writer-every-5-min" {
  name                = "efs-writer-every-5-min"
  schedule_expression = "rate(5 minutes)"
  flexible_time_window {
    mode = "OFF"
  }
  target {
    arn      = aws_ecs_cluster.backup-lab-cluster.arn
    role_arn = aws_iam_role.efs-writer-every-5-min_role.arn
    ecs_parameters {
      launch_type         = "FARGATE"
      task_definition_arn = aws_ecs_task_definition.efs-writer.arn
      network_configuration {
        assign_public_ip = true
        security_groups  = [aws_security_group.ecs_task_definition_efs-writer_group.id]
        subnets          = [aws_subnet.pubA1.id]
      }
    }
  }
  depends_on = [aws_iam_role_policy_attachment.scheduler_schedule_efs-writer-every-5-min_st_aws-backup-lab_attach]
}




### CATEGORY: MONITORING ###

resource "aws_cloudwatch_log_group" "logs-efs-writer" {
  name              = "/aws/ecs/efs-writer"
  log_group_class   = "STANDARD"
  retention_in_days = 1
  skip_destroy      = false
  tags = {
    Name           = "logs-efs-writer"
    State          = "aws-backup-lab"
    Struct8Creator = "Contato Struct"
  }
}


