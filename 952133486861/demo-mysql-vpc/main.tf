terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  backend "s3" {
    bucket  = "struct8-import"
    key     = "952133486861/demo-mysql-vpc/main.tfstate"
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

resource "aws_iam_role" "role_monitoring_demo-mysql" {
  name = "role_monitoring_demo-mysql"
  assume_role_policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": "monitoring.rds.amazonaws.com"
      }
    }
  ]
})
  tags = {
    Name           = "role_monitoring_demo-mysql"
    State          = "demo-mysql-vpc"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role_policy_attachment" "service_role_AmazonRDSEnhancedMonitoringRole_to_demo-mysql_attach" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
  role       = aws_iam_role.role_monitoring_demo-mysql.name
}

resource "aws_kms_key" "demo-mysql-kms" {
  bypass_policy_lockout_safety_check = false
  customer_master_key_spec           = "SYMMETRIC_DEFAULT"
  deletion_window_in_days            = 30
  description                        = "CMK da demo RDS: criptografa o storage do demo-mysql e os CloudWatch Log Groups."
  enable_key_rotation                = true
  is_enabled                         = true
  key_usage                          = "ENCRYPT_DECRYPT"
  multi_region                       = false
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Enable IAM User Permissions",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      },
      "Action": "kms:*",
      "Resource": "*"
    }
  ]
}
  EOF
  rotation_period_in_days = 365
  tags = {
    Name           = "demo-mysql-kms"
    State          = "demo-mysql-vpc"
    Struct8Creator = "Contato Struct"
  }
}




### CATEGORY: NETWORK ###

resource "aws_vpc" "demo-mysql-vpc" {
  cidr_block       = "10.7.0.0/16"
  instance_tenancy = "default"
  tags = {
    Name           = "demo-mysql-vpc"
    State          = "demo-mysql-vpc"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "demo-mysql-private-a" {
  vpc_id                  = aws_vpc.demo-mysql-vpc.id
  availability_zone       = "us-west-2a"
  cidr_block              = "10.7.0.0/24"
  map_public_ip_on_launch = false
  tags = {
    Name           = "demo-mysql-private-a"
    State          = "demo-mysql-vpc"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "demo-mysql-private-b" {
  vpc_id                  = aws_vpc.demo-mysql-vpc.id
  availability_zone       = "us-west-2b"
  cidr_block              = "10.7.1.0/24"
  map_public_ip_on_launch = false
  tags = {
    Name           = "demo-mysql-private-b"
    State          = "demo-mysql-vpc"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group" "db_instance_demo-mysql_group" {
  name                   = "db_instance_demo-mysql_group"
  vpc_id                 = aws_vpc.demo-mysql-vpc.id
  revoke_rules_on_delete = false
  tags = {
    Name           = "db_instance_demo-mysql_group"
    State          = "demo-mysql-vpc"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group_rule" "rule_db_instance_demo_mysql_group_egress_all_protocols" {
  security_group_id = aws_security_group.db_instance_demo-mysql_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}




### CATEGORY: DATABASE ###

resource "aws_db_instance" "demo-mysql" {
  db_name                         = "appdb"
  db_subnet_group_name            = aws_db_subnet_group.subnet_group_demo-mysql.name
  kms_key_id                      = aws_kms_key.demo-mysql-kms.arn
  option_group_name               = aws_db_option_group.demo-mysql-options.name
  parameter_group_name            = aws_db_parameter_group.demo-mysql-params.name
  allocated_storage               = 20
  availability_zone               = aws_subnet.demo-mysql-private-a.availability_zone
  backup_retention_period         = 7
  backup_window                   = "03:00-04:00"
  copy_tags_to_snapshot           = true
  enabled_cloudwatch_logs_exports = ["general", "slowquery", "error", "audit"]
  engine                          = "mysql"
  engine_lifecycle_support        = "open-source-rds-extended-support-disabled"
  engine_version                  = "8.4"
  identifier                      = "demo-mysql"
  instance_class                  = "db.t4g.micro"
  maintenance_window              = "mon:04:30-mon:05:30"
  manage_master_user_password     = true
  max_allocated_storage           = 100
  monitoring_interval             = 60
  monitoring_role_arn             = aws_iam_role.role_monitoring_demo-mysql.arn
  skip_final_snapshot             = true
  storage_encrypted               = true
  storage_type                    = "gp3"
  upgrade_storage_config          = false
  username                        = "dbadmin"
  vpc_security_group_ids          = [aws_security_group.db_instance_demo-mysql_group.id]
  tags = {
    Name           = "demo-mysql"
    State          = "demo-mysql-vpc"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_cloudwatch_log_group.demo-mysql-general-log, aws_cloudwatch_log_group.demo-mysql-error-log, aws_cloudwatch_log_group.demo-mysql-slowquery-log, aws_cloudwatch_log_group.demo-mysql-audit-log, aws_cloudwatch_log_group.demo-mysql-app-log, aws_iam_role_policy_attachment.service_role_AmazonRDSEnhancedMonitoringRole_to_demo-mysql_attach]
}

resource "aws_db_option_group" "demo-mysql-options" {
  engine_name              = "mysql"
  major_engine_version     = "8.4"
  name_prefix              = "demo-mysql-options"
  option_group_description = "Option group MySQL 8.0 da demo com plugin de auditoria MariaDB."
  skip_destroy             = true
  lifecycle {
    create_before_destroy = false
  }
  option {
    option_name = "MARIADB_AUDIT_PLUGIN"
  }
  tags = {
    Name           = "demo-mysql-options"
    State          = "demo-mysql-vpc"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_db_parameter_group" "demo-mysql-params" {
  description  = "Parametros MySQL 8.0 para a demo: utf8mb4, limite de conexoes e slow query log habilitado."
  family       = "mysql8.4"
  name_prefix  = "demo-mysql-params"
  skip_destroy = false
  lifecycle {
    create_before_destroy = true
  }
  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }
  parameter {
    name  = "collation_server"
    value = "utf8mb4_unicode_ci"
  }
  parameter {
    name  = "max_connections"
    value = "200"
  }
  parameter {
    name  = "slow_query_log"
    value = "1"
  }
  parameter {
    name  = "long_query_time"
    value = "2"
  }
  tags = {
    Name           = "demo-mysql-params"
    State          = "demo-mysql-vpc"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_db_subnet_group" "subnet_group_demo-mysql" {
  name       = "demo-mysql-subnet-group"
  subnet_ids = [aws_subnet.demo-mysql-private-a.id, aws_subnet.demo-mysql-private-b.id]
  tags = {
    Name           = "subnet_group_demo-mysql"
    State          = "demo-mysql-vpc"
    Struct8Creator = "Contato Struct"
  }
}




### CATEGORY: MONITORING ###

resource "aws_cloudwatch_log_group" "demo-mysql-app-log" {
  name              = "/aws/rds/instance/demo-mysql/audit"
  log_group_class   = "STANDARD"
  retention_in_days = 30
  skip_destroy      = false
  tags = {
    Name           = "demo-mysql-app-log"
    State          = "demo-mysql-vpc"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_cloudwatch_log_group" "demo-mysql-audit-log" {
  name              = "/aws/rds/instance/demo-mysql/error"
  log_group_class   = "STANDARD"
  retention_in_days = 30
  skip_destroy      = false
  tags = {
    Name           = "demo-mysql-audit-log"
    State          = "demo-mysql-vpc"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_cloudwatch_log_group" "demo-mysql-error-log" {
  name              = "/aws/rds/instance/demo-mysql/general"
  log_group_class   = "STANDARD"
  retention_in_days = 1
  skip_destroy      = false
  tags = {
    Name           = "demo-mysql-error-log"
    State          = "demo-mysql-vpc"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_cloudwatch_log_group" "demo-mysql-general-log" {
  name              = "RDSOSMetrics"
  log_group_class   = "STANDARD"
  retention_in_days = 1
  skip_destroy      = false
  tags = {
    Name           = "demo-mysql-general-log"
    State          = "demo-mysql-vpc"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_cloudwatch_log_group" "demo-mysql-slowquery-log" {
  name              = "/aws/rds/instance/demo-mysql/slowquery"
  log_group_class   = "STANDARD"
  retention_in_days = 30
  skip_destroy      = false
  tags = {
    Name           = "demo-mysql-slowquery-log"
    State          = "demo-mysql-vpc"
    Struct8Creator = "Contato Struct"
  }
}


