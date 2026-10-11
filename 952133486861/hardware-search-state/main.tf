terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  backend "s3" {
    bucket  = "struct8-import"
    key     = "952133486861/hardware-search-state/main.tfstate"
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

data "aws_iam_policy_document" "lambda_function_api-search-hardware_st_hardware-search-state_doc" {
  statement {
    sid       = "AllowRDSDataApihardwaredbcluster"
    effect    = "Allow"
    actions   = ["rds-data:BatchExecuteStatement", "rds-data:BeginTransaction", "rds-data:CommitTransaction", "rds-data:ExecuteStatement", "rds-data:RollbackTransaction"]
    resources = [aws_rds_cluster.hardware-db-cluster.arn]
  }
  statement {
    sid       = "AllowRDSSecretAccesshardwaredbcluster"
    effect    = "Allow"
    actions   = ["secretsmanager:DescribeSecret", "secretsmanager:GetSecretValue"]
    resources = [aws_rds_cluster.hardware-db-cluster.master_user_secret[0].secret_arn]
  }
}

resource "aws_iam_policy" "lambda_function_api-search-hardware_st_hardware-search-state" {
  name        = "lambda_function_api-search-hardware_st_hardware-search-state"
  description = "Access Policy for api-search-hardware"
  policy      = data.aws_iam_policy_document.lambda_function_api-search-hardware_st_hardware-search-state_doc.json
}

data "aws_iam_policy_document" "lambda_function_worker-store-scraper_st_hardware-search-state_doc" {
  statement {
    sid       = "AllowRDSDataApihardwaredbcluster"
    effect    = "Allow"
    actions   = ["rds-data:BatchExecuteStatement", "rds-data:BeginTransaction", "rds-data:CommitTransaction", "rds-data:ExecuteStatement", "rds-data:RollbackTransaction"]
    resources = [aws_rds_cluster.hardware-db-cluster.arn]
  }
  statement {
    sid       = "AllowRDSSecretAccesshardwaredbcluster"
    effect    = "Allow"
    actions   = ["secretsmanager:DescribeSecret", "secretsmanager:GetSecretValue"]
    resources = [aws_rds_cluster.hardware-db-cluster.master_user_secret[0].secret_arn]
  }
  statement {
    sid       = "AllowReciveMessage"
    effect    = "Allow"
    actions   = ["sqs:DeleteMessage", "sqs:GetQueueAttributes", "sqs:ReceiveMessage"]
    resources = [aws_sqs_queue.queue-stores-update.arn]
  }
}

resource "aws_iam_policy" "lambda_function_worker-store-scraper_st_hardware-search-state" {
  name        = "lambda_function_worker-store-scraper_st_hardware-search-state"
  description = "Access Policy for worker-store-scraper"
  policy      = data.aws_iam_policy_document.lambda_function_worker-store-scraper_st_hardware-search-state_doc.json
}

resource "aws_iam_role" "api-search-hardware_role" {
  name = "api-search-hardware_role"
  assume_role_policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      }
    }
  ]
})
  force_detach_policies = false
  max_session_duration  = 3600
  path                  = "/"
  tags = {
    Name           = "api-search-hardware_role"
    State          = "hardware-search-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "worker-store-scraper_role" {
  name = "worker-store-scraper_role"
  assume_role_policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      }
    }
  ]
})
  force_detach_policies = false
  max_session_duration  = 3600
  path                  = "/"
  tags = {
    Name           = "worker-store-scraper_role"
    State          = "hardware-search-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role_policy_attachment" "lambda_function_api-search-hardware_st_hardware-search-state_attach" {
  policy_arn = aws_iam_policy.lambda_function_api-search-hardware_st_hardware-search-state.arn
  role       = aws_iam_role.api-search-hardware_role.name
}

resource "aws_iam_role_policy_attachment" "lambda_function_worker-store-scraper_st_hardware-search-state_attach" {
  policy_arn = aws_iam_policy.lambda_function_worker-store-scraper_st_hardware-search-state.arn
  role       = aws_iam_role.worker-store-scraper_role.name
}




### CATEGORY: NETWORK ###

resource "aws_vpc" "hardware-search-vpc" {
  cidr_block           = "10.50.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default"
  tags = {
    Name           = "hardware-search-vpc"
    State          = "hardware-search-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "subnet-db-a" {
  vpc_id                  = aws_vpc.hardware-search-vpc.id
  availability_zone       = "us-west-2a"
  cidr_block              = "10.50.10.0/24"
  map_public_ip_on_launch = false
  tags = {
    Name           = "subnet-db-a"
    State          = "hardware-search-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "subnet-db-b" {
  vpc_id                  = aws_vpc.hardware-search-vpc.id
  availability_zone       = "us-west-2b"
  cidr_block              = "10.50.11.0/24"
  map_public_ip_on_launch = false
  tags = {
    Name           = "subnet-db-b"
    State          = "hardware-search-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group" "rds_cluster_hardware-db-cluster_group" {
  name                   = "rds_cluster_hardware-db-cluster_group"
  vpc_id                 = aws_vpc.hardware-search-vpc.id
  revoke_rules_on_delete = false
  tags = {
    Name           = "rds_cluster_hardware-db-cluster_group"
    State          = "hardware-search-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group_rule" "rule_rds_cluster_hardware_db_cluster_group_egress_all_protocols" {
  security_group_id = aws_security_group.rds_cluster_hardware-db-cluster_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}




### CATEGORY: DATABASE ###

resource "aws_db_subnet_group" "subnet_group_hardware-db-cluster" {
  name       = "hardware-db-cluster-subnet-group"
  subnet_ids = [aws_subnet.subnet-db-a.id, aws_subnet.subnet-db-b.id]
  tags = {
    Name           = "subnet_group_hardware-db-cluster"
    State          = "hardware-search-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_rds_cluster" "hardware-db-cluster" {
  db_subnet_group_name        = aws_db_subnet_group.subnet_group_hardware-db-cluster.name
  apply_immediately           = true
  backup_retention_period     = 7
  cluster_identifier          = "hardware-db-cluster"
  copy_tags_to_snapshot       = true
  database_insights_mode      = "standard"
  enable_http_endpoint        = true
  engine                      = "aurora-postgresql"
  engine_version              = "16.8"
  manage_master_user_password = true
  master_username             = "dbadmin"
  monitoring_interval         = 0
  network_type                = "IPV4"
  port                        = 0
  skip_final_snapshot         = true
  storage_encrypted           = true
  vpc_security_group_ids      = [aws_security_group.rds_cluster_hardware-db-cluster_group.id]
  tags = {
    Name           = "hardware-db-cluster"
    State          = "hardware-search-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_rds_cluster_instance" "hardware-db-instance" {
  cluster_identifier    = aws_rds_cluster.hardware-db-cluster.id
  copy_tags_to_snapshot = true
  engine                = aws_rds_cluster.hardware-db-cluster.engine
  identifier            = "hardware-db-instance"
  instance_class        = "db.serverless"
  promotion_tier        = 1
  tags = {
    Name           = "hardware-db-instance"
    State          = "hardware-search-state"
    Struct8Creator = "Contato Struct"
  }
}




### CATEGORY: COMPUTE ###

resource "aws_lambda_function" "api-search-hardware" {
  function_name                  = "api-search-hardware"
  architectures                  = ["arm64"]
  filename                       = "dist/function.zip"
  handler                        = "index.handler"
  memory_size                    = 3008
  publish                        = false
  reserved_concurrent_executions = -1
  role                           = aws_iam_role.api-search-hardware_role.arn
  runtime                        = "nodejs20.x"
  timeout                        = 30
  environment {
    variables = {
    NAME                         = "api-search-hardware"
    REGION                       = data.aws_region.current.region
    ACCOUNT                      = data.aws_caller_identity.current.account_id
    AWS_RDS_CLUSTER_NAME_0       = aws_rds_cluster.hardware-db-cluster.cluster_identifier
    AWS_RDS_CLUSTER_ENGINE_0     = aws_rds_cluster.hardware-db-cluster.engine
    AWS_RDS_CLUSTER_ENDPOINT_0   = aws_rds_cluster.hardware-db-cluster.endpoint
    AWS_RDS_CLUSTER_PORT_0       = aws_rds_cluster.hardware-db-cluster.port
    AWS_RDS_CLUSTER_DB_NAME_0    = coalesce(aws_rds_cluster.hardware-db-cluster.database_name, "postgres")
    AWS_RDS_CLUSTER_SECRET_ARN_0 = one(aws_rds_cluster.hardware-db-cluster.master_user_secret[*].secret_arn)
    AWS_RDS_CLUSTER_ARN_0        = aws_rds_cluster.hardware-db-cluster.arn
    AWS_RDS_CLUSTER_DATA_API_0   = true
  }
  }
  tags = {
    Name           = "api-search-hardware"
    State          = "hardware-search-state"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_iam_role_policy_attachment.lambda_function_api-search-hardware_st_hardware-search-state_attach]
}

resource "aws_lambda_function" "worker-store-scraper" {
  function_name                  = "worker-store-scraper"
  architectures                  = ["arm64"]
  filename                       = "dist/function.zip"
  handler                        = "index.handler"
  memory_size                    = 3008
  publish                        = false
  reserved_concurrent_executions = -1
  role                           = aws_iam_role.worker-store-scraper_role.arn
  runtime                        = "nodejs20.x"
  timeout                        = 30
  environment {
    variables = {
    NAME                         = "worker-store-scraper"
    REGION                       = data.aws_region.current.region
    ACCOUNT                      = data.aws_caller_identity.current.account_id
    AWS_RDS_CLUSTER_NAME_0       = aws_rds_cluster.hardware-db-cluster.cluster_identifier
    AWS_RDS_CLUSTER_ENGINE_0     = aws_rds_cluster.hardware-db-cluster.engine
    AWS_RDS_CLUSTER_ENDPOINT_0   = aws_rds_cluster.hardware-db-cluster.endpoint
    AWS_RDS_CLUSTER_PORT_0       = aws_rds_cluster.hardware-db-cluster.port
    AWS_RDS_CLUSTER_DB_NAME_0    = coalesce(aws_rds_cluster.hardware-db-cluster.database_name, "postgres")
    AWS_RDS_CLUSTER_SECRET_ARN_0 = one(aws_rds_cluster.hardware-db-cluster.master_user_secret[*].secret_arn)
    AWS_RDS_CLUSTER_ARN_0        = aws_rds_cluster.hardware-db-cluster.arn
    AWS_RDS_CLUSTER_DATA_API_0   = true
  }
  }
  tags = {
    Name           = "worker-store-scraper"
    State          = "hardware-search-state"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_iam_role_policy_attachment.lambda_function_worker-store-scraper_st_hardware-search-state_attach]
}

resource "aws_lambda_permission" "perm_aws_sqs_queue_queue-stores-update_to_worker-store-scraper" {
  function_name = aws_lambda_function.worker-store-scraper.function_name
  statement_id  = "perm_aws_sqs_queue_queue-stores-update_to_worker-store-scraper"
  principal     = "sqs.amazonaws.com"
  action        = "lambda:InvokeFunction"
  source_arn    = aws_sqs_queue.queue-stores-update.arn
}




### CATEGORY: INTEGRATION ###

resource "aws_sqs_queue" "queue-stores-update" {
  name                              = "queue-stores-update"
  delay_seconds                     = 0
  fifo_queue                        = false
  kms_data_key_reuse_period_seconds = 300
  max_message_size                  = 262144
  message_retention_seconds         = 345600
  receive_wait_time_seconds         = 0
  sqs_managed_sse_enabled           = true
  visibility_timeout_seconds        = 30
  tags = {
    Name           = "queue-stores-update"
    State          = "hardware-search-state"
    Struct8Creator = "Contato Struct"
  }
}


