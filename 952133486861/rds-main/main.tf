terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  backend "s3" {
    bucket  = "struct8-import"
    key     = "952133486861/rds-main/main.tfstate"
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

data "aws_vpc" "demo-mysql-vpc" {
  filter {
    name   = "tag:Name"
    values = ["demo-mysql-vpc"]
  }
}

data "aws_kms_key" "demo-mysql-kms" {
  key_id = "alias/demo-mysql-kms--LhD-paX"
}




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
    State          = "rds-main"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role_policy_attachment" "service_role_AmazonRDSEnhancedMonitoringRole_to_demo-mysql_attach" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
  role       = aws_iam_role.role_monitoring_demo-mysql.name
}




### CATEGORY: NETWORK ###

resource "aws_subnet" "demo-mysql-private-a" {
  vpc_id                  = data.aws_vpc.demo-mysql-vpc.id
  availability_zone       = "us-west-2a"
  cidr_block              = "10.7.0.0/24"
  map_public_ip_on_launch = false
  tags = {
    Name           = "demo-mysql-private-a"
    State          = "rds-main"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "demo-mysql-private-b" {
  vpc_id                  = data.aws_vpc.demo-mysql-vpc.id
  availability_zone       = "us-west-2b"
  cidr_block              = "10.7.1.0/24"
  map_public_ip_on_launch = false
  tags = {
    Name           = "demo-mysql-private-b"
    State          = "rds-main"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group" "db_instance_demo-mysql_group" {
  name                   = "db_instance_demo-mysql_group"
  vpc_id                 = data.aws_vpc.demo-mysql-vpc.id
  revoke_rules_on_delete = false
  tags = {
    Name           = "db_instance_demo-mysql_group"
    State          = "rds-main"
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

data "aws_resourcegroupstaggingapi_resources" "option_group_demo-mysql-options" {
  resource_type_filters = ["rds:og"]
  lifecycle {
    postcondition {
      condition     = length(self.resource_tag_mapping_list) > 0
      error_message = "No RDS option group tagged Name=demo-mysql-options exists in this region. Apply the state that creates it before this one."
    }
    postcondition {
      condition     = length(self.resource_tag_mapping_list) < 2
      error_message = "More than one RDS option group is tagged Name=demo-mysql-options in this region, and this state cannot tell which one to use. Leave one group with that name."
    }
  }
  tag_filter {
    key    = "Name"
    values = ["demo-mysql-options"]
  }
}

data "aws_resourcegroupstaggingapi_resources" "parameter_group_demo-mysql-params" {
  resource_type_filters = ["rds:pg"]
  lifecycle {
    postcondition {
      condition     = length(self.resource_tag_mapping_list) > 0
      error_message = "No RDS DB parameter group tagged Name=demo-mysql-params exists in this region. Apply the state that creates it before this one."
    }
    postcondition {
      condition     = length(self.resource_tag_mapping_list) < 2
      error_message = "More than one RDS DB parameter group is tagged Name=demo-mysql-params in this region, and this state cannot tell which one to use. Leave one group with that name."
    }
  }
  tag_filter {
    key    = "Name"
    values = ["demo-mysql-params"]
  }
}

resource "aws_db_instance" "demo-mysql" {
  db_name                         = "appdb"
  db_subnet_group_name            = aws_db_subnet_group.subnet_group_demo-mysql.name
  kms_key_id                      = data.aws_kms_key.demo-mysql-kms.arn
  option_group_name               = element(split(":", data.aws_resourcegroupstaggingapi_resources.option_group_demo-mysql-options.resource_tag_mapping_list[0].resource_arn), 6)
  parameter_group_name            = element(split(":", data.aws_resourcegroupstaggingapi_resources.parameter_group_demo-mysql-params.resource_tag_mapping_list[0].resource_arn), 6)
  allocated_storage               = 20
  availability_zone               = aws_subnet.demo-mysql-private-a.availability_zone
  backup_retention_period         = 7
  backup_window                   = "03:00-04:00"
  copy_tags_to_snapshot           = true
  enabled_cloudwatch_logs_exports = ["error", "slowquery", "audit", "general"]
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
    State          = "rds-main"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_cloudwatch_log_group.mysql-logs-error, aws_cloudwatch_log_group.mysql-logs-slowquery, aws_cloudwatch_log_group.mysql-logs-audit, aws_cloudwatch_log_group.mysql-logs-general, aws_cloudwatch_log_group.mysql-logs-monitoring, aws_iam_role_policy_attachment.service_role_AmazonRDSEnhancedMonitoringRole_to_demo-mysql_attach]
}

resource "aws_db_subnet_group" "subnet_group_demo-mysql" {
  name       = "demo-mysql-subnet-group"
  subnet_ids = [aws_subnet.demo-mysql-private-a.id, aws_subnet.demo-mysql-private-b.id]
  tags = {
    Name           = "subnet_group_demo-mysql"
    State          = "rds-main"
    Struct8Creator = "Contato Struct"
  }
}




### CATEGORY: MONITORING ###

resource "aws_cloudwatch_log_group" "mysql-logs-audit" {
  name              = "/aws/rds/instance/demo-mysql/audit"
  log_group_class   = "STANDARD"
  retention_in_days = 1
  skip_destroy      = false
  tags = {
    Name           = "mysql-logs-audit"
    State          = "rds-main"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_cloudwatch_log_group" "mysql-logs-error" {
  name              = "/aws/rds/instance/demo-mysql/error"
  log_group_class   = "STANDARD"
  retention_in_days = 1
  skip_destroy      = false
  tags = {
    Name           = "mysql-logs-error"
    State          = "rds-main"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_cloudwatch_log_group" "mysql-logs-general" {
  name              = "/aws/rds/instance/demo-mysql/general"
  log_group_class   = "STANDARD"
  retention_in_days = 1
  skip_destroy      = false
  tags = {
    Name           = "mysql-logs-general"
    State          = "rds-main"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_cloudwatch_log_group" "mysql-logs-monitoring" {
  name              = "RDSOSMetrics"
  log_group_class   = "STANDARD"
  retention_in_days = 1
  skip_destroy      = false
  tags = {
    Name           = "mysql-logs-monitoring"
    State          = "rds-main"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_cloudwatch_log_group" "mysql-logs-slowquery" {
  name              = "/aws/rds/instance/demo-mysql/slowquery"
  log_group_class   = "STANDARD"
  retention_in_days = 1
  skip_destroy      = false
  tags = {
    Name           = "mysql-logs-slowquery"
    State          = "rds-main"
    Struct8Creator = "Contato Struct"
  }
}


