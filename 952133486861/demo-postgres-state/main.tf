terraform {
  required_providers {
    archive = {
      source = "hashicorp/archive"
    }
    aws = {
      source = "hashicorp/aws"
    }
  }

  backend "s3" {
    bucket  = "struct8-import"
    key     = "952133486861/demo-postgres-state/main.tfstate"
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

resource "aws_iam_instance_profile" "demo-cloudbeaver_profile" {
  name = "demo-cloudbeaver_profile"
  role = aws_iam_role.demo-cloudbeaver_role.name
  tags = {
    Name           = "demo-cloudbeaver_profile"
    State          = "demo-postgres-state"
    Struct8Creator = "Contato Struct"
  }
}

data "aws_iam_policy_document" "db_proxy_demo-postgres-proxy_st_demo-postgres-state_doc" {
  statement {
    sid       = "ReadDatabaseCredentials"
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [one(aws_db_instance.demo-postgres1.master_user_secret[*].secret_arn)]
  }
}

resource "aws_iam_policy" "db_proxy_demo-postgres-proxy_st_demo-postgres-state" {
  name        = "db_proxy_demo-postgres-proxy_st_demo-postgres-state"
  description = "Access Policy for demo-postgres-proxy"
  policy      = data.aws_iam_policy_document.db_proxy_demo-postgres-proxy_st_demo-postgres-state_doc.json
}

data "aws_iam_policy_document" "instance_demo-cloudbeaver_st_demo-postgres-state_doc" {
  statement {
    sid       = "AllowRDSSecretAccessdemopostgres1"
    effect    = "Allow"
    actions   = ["secretsmanager:DescribeSecret", "secretsmanager:GetSecretValue"]
    resources = [aws_db_instance.demo-postgres1.master_user_secret[0].secret_arn]
  }
}

resource "aws_iam_policy" "instance_demo-cloudbeaver_st_demo-postgres-state" {
  name        = "instance_demo-cloudbeaver_st_demo-postgres-state"
  description = "Access Policy for demo-cloudbeaver"
  policy      = data.aws_iam_policy_document.instance_demo-cloudbeaver_st_demo-postgres-state_doc.json
}

data "aws_iam_policy_document" "lambda_function_demo-postgres-api1_st_demo-postgres-state_doc" {
  statement {
    sid       = "AllowWriteLogs"
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.demo-postgres-log1.arn}:*"]
  }
}

resource "aws_iam_policy" "lambda_function_demo-postgres-api1_st_demo-postgres-state" {
  name        = "lambda_function_demo-postgres-api1_st_demo-postgres-state"
  description = "Access Policy for demo-postgres-api1"
  policy      = data.aws_iam_policy_document.lambda_function_demo-postgres-api1_st_demo-postgres-state_doc.json
}

data "aws_iam_policy_document" "lambda_function_demo-postgres-direct_st_demo-postgres-state_doc" {
  statement {
    sid       = "AllowWriteLogs"
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.demo-postgres-log1.arn}:*"]
  }
  statement {
    sid       = "AllowRDSSecretAccessdemopostgres1"
    effect    = "Allow"
    actions   = ["secretsmanager:DescribeSecret", "secretsmanager:GetSecretValue"]
    resources = [aws_db_instance.demo-postgres1.master_user_secret[0].secret_arn]
  }
}

resource "aws_iam_policy" "lambda_function_demo-postgres-direct_st_demo-postgres-state" {
  name        = "lambda_function_demo-postgres-direct_st_demo-postgres-state"
  description = "Access Policy for demo-postgres-direct"
  policy      = data.aws_iam_policy_document.lambda_function_demo-postgres-direct_st_demo-postgres-state_doc.json
}

data "aws_iam_policy_document" "scheduler_schedule_demo-direct-schedule_st_demo-postgres-state_doc" {
  statement {
    sid       = "AllowSchedulerToInvokeFunction"
    effect    = "Allow"
    actions   = ["lambda:InvokeFunction"]
    resources = [aws_lambda_function.demo-postgres-direct.arn]
  }
}

resource "aws_iam_policy" "scheduler_schedule_demo-direct-schedule_st_demo-postgres-state" {
  name        = "scheduler_schedule_demo-direct-schedule_st_demo-postgres-state"
  description = "Access Policy for demo-direct-schedule"
  policy      = data.aws_iam_policy_document.scheduler_schedule_demo-direct-schedule_st_demo-postgres-state_doc.json
}

data "aws_iam_policy_document" "scheduler_schedule_demo-insert-schedule_st_demo-postgres-state_doc" {
  statement {
    sid       = "AllowSchedulerToInvokeFunction"
    effect    = "Allow"
    actions   = ["lambda:InvokeFunction"]
    resources = [aws_lambda_function.demo-postgres-api1.arn]
  }
}

resource "aws_iam_policy" "scheduler_schedule_demo-insert-schedule_st_demo-postgres-state" {
  name        = "scheduler_schedule_demo-insert-schedule_st_demo-postgres-state"
  description = "Access Policy for demo-insert-schedule"
  policy      = data.aws_iam_policy_document.scheduler_schedule_demo-insert-schedule_st_demo-postgres-state_doc.json
}

resource "aws_iam_role" "demo-cloudbeaver_role" {
  name = "demo-cloudbeaver_role"
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
    Name           = "demo-cloudbeaver_role"
    State          = "demo-postgres-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "demo-direct-schedule_role" {
  name = "demo-direct-schedule_role"
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
    Name           = "demo-direct-schedule_role"
    State          = "demo-postgres-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "demo-insert-schedule_role" {
  name = "demo-insert-schedule_role"
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
    Name           = "demo-insert-schedule_role"
    State          = "demo-postgres-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "demo-postgres-api1_role" {
  name = "demo-postgres-api1_role"
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
    Name           = "demo-postgres-api1_role"
    State          = "demo-postgres-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "demo-postgres-direct_role" {
  name = "demo-postgres-direct_role"
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
    Name           = "demo-postgres-direct_role"
    State          = "demo-postgres-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "role_rds_proxy_demo-postgres-proxy" {
  name = "role_rds_proxy_demo-postgres-proxy"
  assume_role_policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": "rds.amazonaws.com"
      }
    }
  ]
})
  tags = {
    Name           = "role_rds_proxy_demo-postgres-proxy"
    State          = "demo-postgres-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role_policy_attachment" "db_proxy_demo-postgres-proxy_st_demo-postgres-state_attach" {
  policy_arn = aws_iam_policy.db_proxy_demo-postgres-proxy_st_demo-postgres-state.arn
  role       = aws_iam_role.role_rds_proxy_demo-postgres-proxy.name
}

resource "aws_iam_role_policy_attachment" "instance_demo-cloudbeaver_st_demo-postgres-state_attach" {
  policy_arn = aws_iam_policy.instance_demo-cloudbeaver_st_demo-postgres-state.arn
  role       = aws_iam_role.demo-cloudbeaver_role.name
}

resource "aws_iam_role_policy_attachment" "lambda_function_demo-postgres-api1_st_demo-postgres-state_attach" {
  policy_arn = aws_iam_policy.lambda_function_demo-postgres-api1_st_demo-postgres-state.arn
  role       = aws_iam_role.demo-postgres-api1_role.name
}

resource "aws_iam_role_policy_attachment" "lambda_function_demo-postgres-direct_st_demo-postgres-state_attach" {
  policy_arn = aws_iam_policy.lambda_function_demo-postgres-direct_st_demo-postgres-state.arn
  role       = aws_iam_role.demo-postgres-direct_role.name
}

resource "aws_iam_role_policy_attachment" "scheduler_schedule_demo-direct-schedule_st_demo-postgres-state_attach" {
  policy_arn = aws_iam_policy.scheduler_schedule_demo-direct-schedule_st_demo-postgres-state.arn
  role       = aws_iam_role.demo-direct-schedule_role.name
}

resource "aws_iam_role_policy_attachment" "scheduler_schedule_demo-insert-schedule_st_demo-postgres-state_attach" {
  policy_arn = aws_iam_policy.scheduler_schedule_demo-insert-schedule_st_demo-postgres-state.arn
  role       = aws_iam_role.demo-insert-schedule_role.name
}




### CATEGORY: NETWORK ###

resource "aws_vpc" "VPC2" {
  cidr_block       = "10.8.0.0/16"
  instance_tenancy = "default"
  tags = {
    Name           = "VPC2"
    State          = "demo-postgres-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "demo-postgres-private-a" {
  vpc_id                  = aws_vpc.VPC2.id
  availability_zone       = "us-west-2a"
  cidr_block              = "10.8.0.0/24"
  map_public_ip_on_launch = false
  tags = {
    Name           = "demo-postgres-private-a"
    State          = "demo-postgres-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "demo-postgres-private-b" {
  vpc_id                  = aws_vpc.VPC2.id
  availability_zone       = "us-west-2b"
  cidr_block              = "10.8.1.0/24"
  map_public_ip_on_launch = false
  tags = {
    Name           = "demo-postgres-private-b"
    State          = "demo-postgres-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "demo-public-a" {
  vpc_id                  = aws_vpc.VPC2.id
  availability_zone       = "us-west-2a"
  cidr_block              = "10.8.10.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name           = "demo-public-a"
    State          = "demo-postgres-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_internet_gateway" "demo-igw" {
  vpc_id = aws_vpc.VPC2.id
  tags = {
    Name           = "demo-igw"
    State          = "demo-postgres-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route" "route_demo-public-rt_to_demo-igw_ipv4" {
  gateway_id             = aws_internet_gateway.demo-igw.id
  route_table_id         = aws_route_table.demo-public-rt.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table" "demo-public-rt" {
  vpc_id = aws_vpc.VPC2.id
  tags = {
    Name           = "demo-public-rt"
    State          = "demo-postgres-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route_table_association" "aws_route_table_association_demo_public_a_demo_public_rt" {
  route_table_id = aws_route_table.demo-public-rt.id
  subnet_id      = aws_subnet.demo-public-a.id
}

resource "aws_security_group" "db_instance_demo-postgres1_group" {
  name                   = "db_instance_demo-postgres1_group"
  vpc_id                 = aws_vpc.VPC2.id
  revoke_rules_on_delete = false
  tags = {
    Name           = "db_instance_demo-postgres1_group"
    State          = "demo-postgres-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group" "db_proxy_demo-postgres-proxy_group" {
  name                   = "db_proxy_demo-postgres-proxy_group"
  vpc_id                 = aws_vpc.VPC2.id
  revoke_rules_on_delete = false
  tags = {
    Name           = "db_proxy_demo-postgres-proxy_group"
    State          = "demo-postgres-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group" "instance_demo-cloudbeaver_group" {
  name                   = "instance_demo-cloudbeaver_group"
  vpc_id                 = aws_vpc.VPC2.id
  description            = "CloudBeaver web UI"
  revoke_rules_on_delete = false
  tags = {
    Name           = "instance_demo-cloudbeaver_group"
    State          = "demo-postgres-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group_rule" "rule_db_instance_demo_postgres1_group_egress_all_protocols" {
  security_group_id = aws_security_group.db_instance_demo-postgres1_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "rule_db_instance_demo_postgres1_group_to_db_proxy_demo_postgres_proxy_group_tcp_5432" {
  security_group_id        = aws_security_group.db_proxy_demo-postgres-proxy_group.id
  source_security_group_id = aws_security_group.db_instance_demo-postgres1_group.id
  description              = "Allow from db_instance_demo-postgres1_group (tcp:5432-5432)"
  from_port                = 5432
  protocol                 = "tcp"
  to_port                  = 5432
  type                     = "ingress"
}

resource "aws_security_group_rule" "rule_db_proxy_demo_postgres_proxy_group_egress_all_protocols" {
  security_group_id = aws_security_group.db_proxy_demo-postgres-proxy_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "rule_db_proxy_demo_postgres_proxy_group_to_db_instance_demo_postgres1_group_tcp_5432" {
  security_group_id        = aws_security_group.db_instance_demo-postgres1_group.id
  source_security_group_id = aws_security_group.db_proxy_demo-postgres-proxy_group.id
  description              = "Allow from RDS Proxy demo-postgres-proxy"
  from_port                = 5432
  protocol                 = "tcp"
  to_port                  = 5432
  type                     = "ingress"
}

resource "aws_security_group_rule" "rule_instance_demo_cloudbeaver_group_egress_all_protocols" {
  security_group_id = aws_security_group.instance_demo-cloudbeaver_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "rule_instance_demo_cloudbeaver_group_ingress_tcp_8978" {
  security_group_id = aws_security_group.instance_demo-cloudbeaver_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 8978
  protocol          = "tcp"
  to_port           = 8978
  type              = "ingress"
}

resource "aws_security_group_rule" "rule_instance_demo_cloudbeaver_group_to_db_instance_demo_postgres1_group_tcp_5432" {
  security_group_id        = aws_security_group.db_instance_demo-postgres1_group.id
  source_security_group_id = aws_security_group.instance_demo-cloudbeaver_group.id
  description              = "Allow from instance_demo-cloudbeaver_group (tcp:5432-5432)"
  from_port                = 5432
  protocol                 = "tcp"
  to_port                  = 5432
  type                     = "ingress"
}




### CATEGORY: DATABASE ###

resource "aws_db_instance" "demo-postgres1" {
  db_name                         = "appdb"
  db_subnet_group_name            = aws_db_subnet_group.subnet_group_demo-postgres1.name
  parameter_group_name            = aws_db_parameter_group.demo-postgres-params1.name
  allocated_storage               = 20
  availability_zone               = aws_subnet.demo-postgres-private-a.availability_zone
  backup_retention_period         = 7
  backup_window                   = "03:00-04:00"
  copy_tags_to_snapshot           = true
  delete_automated_backups        = false
  deletion_protection             = true
  enabled_cloudwatch_logs_exports = ["postgresql"]
  engine                          = "postgres"
  engine_lifecycle_support        = "open-source-rds-extended-support-disabled"
  engine_version                  = "18"
  identifier                      = "demo-postgres1"
  instance_class                  = "db.t3.micro"
  maintenance_window              = "mon:04:30-mon:05:30"
  manage_master_user_password     = true
  max_allocated_storage           = 100
  port                            = 5432
  skip_final_snapshot             = true
  storage_encrypted               = true
  storage_type                    = "gp3"
  upgrade_storage_config          = false
  username                        = "dbadmin"
  vpc_security_group_ids          = [aws_security_group.db_instance_demo-postgres1_group.id]
  tags = {
    Name           = "demo-postgres1"
    State          = "demo-postgres-state"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_cloudwatch_log_group.demo-postgres-log1]
}

resource "aws_db_parameter_group" "demo-postgres-params1" {
  description  = "Parametros PostgreSQL 18 para a demo"
  family       = "postgres18"
  name_prefix  = "demo-postgres-params1"
  skip_destroy = false
  lifecycle {
    create_before_destroy = true
  }
  tags = {
    Name           = "demo-postgres-params1"
    State          = "demo-postgres-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_db_proxy" "demo-postgres-proxy" {
  name                   = "demo-postgres-proxy"
  engine_family          = "POSTGRESQL"
  require_tls            = true
  role_arn               = aws_iam_role.role_rds_proxy_demo-postgres-proxy.arn
  vpc_security_group_ids = [aws_security_group.db_proxy_demo-postgres-proxy_group.id]
  vpc_subnet_ids         = [aws_subnet.demo-postgres-private-a.id]
  auth {
    auth_scheme               = "SECRETS"
    client_password_auth_type = "POSTGRES_SCRAM_SHA_256"
    iam_auth                  = "DISABLED"
    secret_arn                = one(aws_db_instance.demo-postgres1.master_user_secret[*].secret_arn)
  }
  tags = {
    Name           = "demo-postgres-proxy"
    State          = "demo-postgres-state"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_iam_role_policy_attachment.db_proxy_demo-postgres-proxy_st_demo-postgres-state_attach]
}

resource "aws_db_proxy_target" "demo-postgres-proxy_target" {
  db_proxy_name          = aws_db_proxy.demo-postgres-proxy.name
  target_group_name      = "default"
  db_instance_identifier = aws_db_instance.demo-postgres1.identifier
}

resource "aws_db_subnet_group" "subnet_group_demo-postgres1" {
  name       = "demo-postgres1-subnet-group"
  subnet_ids = [aws_subnet.demo-postgres-private-a.id, aws_subnet.demo-postgres-private-b.id]
  tags = {
    Name           = "subnet_group_demo-postgres1"
    State          = "demo-postgres-state"
    Struct8Creator = "Contato Struct"
  }
}




### CATEGORY: COMPUTE ###

data "local_file" "UserData_demo-cloudbeaver" {
  filename = "${path.module}/.external_modules/struct8-templates/templates/ec2-cloudbeaver/v1/user_data/cloudbeaver.sh"
}

data "aws_ami" "AMI_Data_Source_demo-cloudbeaver" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-kernel-6.1-x86_64"]
  }
}

resource "aws_instance" "demo-cloudbeaver" {
  subnet_id                   = aws_subnet.demo-public-a.id
  ami                         = data.aws_ami.AMI_Data_Source_demo-cloudbeaver.id
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.demo-cloudbeaver_profile.name
  instance_type               = "t3.small"
  user_data_base64 = base64encode(<<-EOFUData
#!/bin/bash

${data.local_file.UserData_demo-cloudbeaver.content}
EOFUData
)
  vpc_security_group_ids = [aws_security_group.instance_demo-cloudbeaver_group.id]
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
    Name           = "demo-cloudbeaver"
    State          = "demo-postgres-state"
    Struct8Creator = "Contato Struct"
  }
}

data "archive_file" "archive_struct8-hub_demo-postgres-api1" {
  output_path = "${path.module}/struct8-hub_demo-postgres-api1.zip"
  source_dir  = "${path.module}/.external_modules/struct8-hub/prebuilt"
  type        = "zip"
}

resource "aws_lambda_function" "demo-postgres-api1" {
  function_name                  = "demo-postgres-api1"
  architectures                  = ["arm64"]
  description                    = "API Lambda que consome o banco demo-postgres"
  filename                       = data.archive_file.archive_struct8-hub_demo-postgres-api1.output_path
  handler                        = "index.handler"
  memory_size                    = 3008
  publish                        = false
  reserved_concurrent_executions = -1
  role                           = aws_iam_role.demo-postgres-api1_role.arn
  runtime                        = "python3.13"
  source_code_hash               = data.archive_file.archive_struct8-hub_demo-postgres-api1.output_base64sha256
  timeout                        = 30
  environment {
    variables = {
    NAME                    = "demo-postgres-api1"
    REGION                  = data.aws_region.current.region
    ACCOUNT                 = data.aws_caller_identity.current.account_id
    AWS_DB_PROXY_ENDPOINT_0 = aws_db_proxy.demo-postgres-proxy.endpoint
    AWS_DB_PROXY_PORT_0     = "5432"
  }
  }
  tags = {
    Name           = "demo-postgres-api1"
    State          = "demo-postgres-state"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_iam_role_policy_attachment.lambda_function_demo-postgres-api1_st_demo-postgres-state_attach]
}

data "archive_file" "archive_struct8-hub_demo-postgres-direct" {
  output_path = "${path.module}/struct8-hub_demo-postgres-direct.zip"
  source_dir  = "${path.module}/.external_modules/struct8-hub/prebuilt"
  type        = "zip"
}

resource "aws_lambda_function" "demo-postgres-direct" {
  function_name                  = "demo-postgres-direct"
  architectures                  = ["arm64"]
  description                    = "Lambda que acessa o RDS DIRETO (sem proxy), rodando o Struct8 Hub"
  filename                       = data.archive_file.archive_struct8-hub_demo-postgres-direct.output_path
  handler                        = "index.handler"
  memory_size                    = 3008
  publish                        = false
  reserved_concurrent_executions = -1
  role                           = aws_iam_role.demo-postgres-direct_role.arn
  runtime                        = "nodejs22.x"
  source_code_hash               = data.archive_file.archive_struct8-hub_demo-postgres-direct.output_base64sha256
  timeout                        = 30
  environment {
    variables = {
    NAME                         = "demo-postgres-direct"
    REGION                       = data.aws_region.current.region
    ACCOUNT                      = data.aws_caller_identity.current.account_id
    AWS_DB_INSTANCE_ENDPOINT_0   = aws_db_instance.demo-postgres1.endpoint
    AWS_DB_INSTANCE_DB_NAME_0    = aws_db_instance.demo-postgres1.db_name
    AWS_DB_INSTANCE_SECRET_ARN_0 = one(aws_db_instance.demo-postgres1.master_user_secret[*].secret_arn)
    AWS_DB_INSTANCE_USER_NAME_0  = "${one(aws_db_instance.demo-postgres1.master_user_secret[*].secret_arn)}:username::"
  }
  }
  tags = {
    Name           = "demo-postgres-direct"
    State          = "demo-postgres-state"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_iam_role_policy_attachment.lambda_function_demo-postgres-direct_st_demo-postgres-state_attach]
}




### CATEGORY: INTEGRATION ###

resource "aws_scheduler_schedule" "demo-direct-schedule" {
  name                = "demo-direct-schedule"
  description         = "Dispara a Lambda direta (Hub) a cada 1 minuto"
  schedule_expression = "rate(1 minute)"
  flexible_time_window {
    mode = "OFF"
  }
  target {
    arn      = aws_lambda_function.demo-postgres-direct.arn
    input    = "{\"action\":\"insert-direct\",\"source\":\"eventbridge-scheduler\",\"table\":\"demo_items\"}"
    role_arn = aws_iam_role.demo-direct-schedule_role.arn
  }
  depends_on = [aws_iam_role_policy_attachment.scheduler_schedule_demo-direct-schedule_st_demo-postgres-state_attach]
}

resource "aws_scheduler_schedule" "demo-insert-schedule" {
  name                = "demo-insert-schedule"
  description         = "Dispara a Lambda a cada 1 minuto para inserir itens no RDS"
  schedule_expression = "rate(1 minute)"
  flexible_time_window {
    mode = "OFF"
  }
  target {
    arn      = aws_lambda_function.demo-postgres-api1.arn
    input    = "{\"action\":\"insert\",\"source\":\"eventbridge-scheduler\",\"table\":\"demo_items\"}"
    role_arn = aws_iam_role.demo-insert-schedule_role.arn
  }
  depends_on = [aws_iam_role_policy_attachment.scheduler_schedule_demo-insert-schedule_st_demo-postgres-state_attach]
}




### CATEGORY: MONITORING ###

resource "aws_cloudwatch_log_group" "demo-postgres-log1" {
  name              = "/aws/rds/instance/demo-postgres1/postgresql"
  log_group_class   = "STANDARD"
  retention_in_days = 30
  skip_destroy      = false
  tags = {
    Name           = "demo-postgres-log1"
    State          = "demo-postgres-state"
    Struct8Creator = "Contato Struct"
  }
}


