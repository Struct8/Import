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
    key     = "952133486861/beanstalk-wordpress/main.tfstate"
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

resource "aws_iam_instance_profile" "beanstalk-wordpress-web_profile" {
  name = "beanstalk-wordpress-web_profile"
  role = aws_iam_role.beanstalk-wordpress-web_role.name
  tags = {
    Name           = "beanstalk-wordpress-web_profile"
    State          = "beanstalk-wordpress"
    Struct8Creator = "Contato Struct"
  }
}

data "aws_iam_policy_document" "elastic_beanstalk_environment_beanstalk-wordpress-web_st_beanstalk-wordpress_doc" {
  statement {
    sid       = "AllowRDSSecretAccesswpebdb"
    effect    = "Allow"
    actions   = ["secretsmanager:DescribeSecret", "secretsmanager:GetSecretValue"]
    resources = [aws_db_instance.wp-eb-db.master_user_secret[0].secret_arn]
  }
  statement {
    sid       = "AllowEFSBasicAccess"
    effect    = "Allow"
    actions   = ["elasticfilesystem:ClientMount", "elasticfilesystem:ClientRootAccess", "elasticfilesystem:ClientWrite"]
    resources = ["${aws_efs_file_system.wp-eb-files.arn}:*"]
  }
  statement {
    sid       = "BeanstalkSourceBundle"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.beanstalk-wordpress-versions.arn}/beanstalk/beanstalk-wordpress-web/*"]
  }
  statement {
    sid       = "AllowReadParam"
    effect    = "Allow"
    actions   = ["ssm:GetParameter"]
    resources = [aws_ssm_parameter.ebWpAdminPassword.arn]
  }
  statement {
    sid       = "AllowSecureStringDecrypt"
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = ["*"]
    condition {
      test     = "StringLike"
      values   = ["ssm.*.amazonaws.com"]
      variable = "kms:ViaService"
    }
  }
}

resource "aws_iam_policy" "elastic_beanstalk_environment_beanstalk-wordpress-web_st_beanstalk-wordpress" {
  name        = "elastic_beanstalk_environment_beanstalk-wordpress-web_st_beanstalk-wordpress"
  description = "Access Policy for beanstalk-wordpress-web"
  policy      = data.aws_iam_policy_document.elastic_beanstalk_environment_beanstalk-wordpress-web_st_beanstalk-wordpress_doc.json
}

data "aws_iam_policy_document" "wp-eb-debug_debug_permissions" {
  statement {
    sid       = "SendToTaggedInstancesOnly"
    effect    = "Allow"
    actions   = ["ssm:SendCommand"]
    resources = ["arn:aws:ec2:*:*:instance/*"]
    condition {
      test     = "StringEquals"
      values   = ["vcKwUxgX387SjdjWFmDL_"]
      variable = "aws:ResourceTag/Struct8Debug"
    }
  }
  statement {
    sid       = "PinnedDocumentOnly"
    effect    = "Allow"
    actions   = ["ssm:SendCommand"]
    resources = ["arn:aws:ssm:*:${data.aws_caller_identity.current.account_id}:document/Struct8Probe-vcKwUxgX387SjdjWFmDL_"]
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
      values   = ["vcKwUxgX387SjdjWFmDL_"]
      variable = "aws:ResourceTag/Struct8Debug"
    }
  }
}

data "aws_iam_policy_document" "wp-eb-debug_debug_trust" {
  statement {
    effect = "Allow"
    principals {
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/CrossAccountStruct8"]
      type        = "AWS"
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "Struct8Debug-wp-eb-debug" {
  name                 = "Struct8Debug-vcKwUxgX387SjdjWFmDL_"
  assume_role_policy   = data.aws_iam_policy_document.wp-eb-debug_debug_trust.json
  max_session_duration = 3600
}

resource "aws_iam_role" "beanstalk-wordpress-web_role" {
  name = "beanstalk-wordpress-web_role"
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
    Name           = "beanstalk-wordpress-web_role"
    State          = "beanstalk-wordpress"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role_policy" "Struct8Debug-wp-eb-debug_policy" {
  name   = "Struct8Debug-vcKwUxgX387SjdjWFmDL_-policy"
  policy = data.aws_iam_policy_document.wp-eb-debug_debug_permissions.json
  role   = aws_iam_role.Struct8Debug-wp-eb-debug.id
}

resource "aws_iam_role_policy_attachment" "AWSElasticBeanstalkMulticontainerDocker_to_beanstalk-wordpress-web_attach" {
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkMulticontainerDocker"
  role       = aws_iam_role.beanstalk-wordpress-web_role.name
}

resource "aws_iam_role_policy_attachment" "AWSElasticBeanstalkWebTier_to_beanstalk-wordpress-web_attach" {
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
  role       = aws_iam_role.beanstalk-wordpress-web_role.name
}

resource "aws_iam_role_policy_attachment" "AWSElasticBeanstalkWorkerTier_to_beanstalk-wordpress-web_attach" {
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWorkerTier"
  role       = aws_iam_role.beanstalk-wordpress-web_role.name
}

resource "aws_iam_role_policy_attachment" "AmazonSSMManagedInstanceCore_to_beanstalk-wordpress-web_attach" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.beanstalk-wordpress-web_role.name
}

resource "aws_iam_role_policy_attachment" "elastic_beanstalk_environment_beanstalk-wordpress-web_st_beanstalk-wordpress_attach" {
  policy_arn = aws_iam_policy.elastic_beanstalk_environment_beanstalk-wordpress-web_st_beanstalk-wordpress.arn
  role       = aws_iam_role.beanstalk-wordpress-web_role.name
}




### CATEGORY: NETWORK ###

resource "aws_vpc" "vpc-beanstalk-wordpress" {
  cidr_block           = "10.41.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default"
  tags = {
    Name           = "vpc-beanstalk-wordpress"
    State          = "beanstalk-wordpress"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "wp-app-a" {
  vpc_id                  = aws_vpc.vpc-beanstalk-wordpress.id
  availability_zone       = "us-west-2a"
  cidr_block              = "10.41.10.0/24"
  map_public_ip_on_launch = false
  tags = {
    Name           = "wp-app-a"
    State          = "beanstalk-wordpress"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "wp-app-b" {
  vpc_id                  = aws_vpc.vpc-beanstalk-wordpress.id
  availability_zone       = "us-west-2b"
  cidr_block              = "10.41.11.0/24"
  map_public_ip_on_launch = false
  tags = {
    Name           = "wp-app-b"
    State          = "beanstalk-wordpress"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "wp-public-a" {
  vpc_id                  = aws_vpc.vpc-beanstalk-wordpress.id
  availability_zone       = "us-west-2a"
  cidr_block              = "10.41.0.0/24"
  map_public_ip_on_launch = false
  tags = {
    Name           = "wp-public-a"
    State          = "beanstalk-wordpress"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "wp-public-b" {
  vpc_id                  = aws_vpc.vpc-beanstalk-wordpress.id
  availability_zone       = "us-west-2b"
  cidr_block              = "10.41.1.0/24"
  map_public_ip_on_launch = false
  tags = {
    Name           = "wp-public-b"
    State          = "beanstalk-wordpress"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_internet_gateway" "igw-beanstalk-wordpress" {
  vpc_id = aws_vpc.vpc-beanstalk-wordpress.id
  tags = {
    Name           = "igw-beanstalk-wordpress"
    State          = "beanstalk-wordpress"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_nat_gateway" "nat-beanstalk-wordpress" {
  vpc_id            = aws_vpc.vpc-beanstalk-wordpress.id
  availability_mode = "regional"
  connectivity_type = "public"
  tags = {
    Name           = "nat-beanstalk-wordpress"
    State          = "beanstalk-wordpress"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_internet_gateway.igw-beanstalk-wordpress]
}

resource "aws_route" "route_rt-private-wp_to_nat-beanstalk-wordpress_ipv4" {
  nat_gateway_id         = aws_nat_gateway.nat-beanstalk-wordpress.id
  route_table_id         = aws_route_table.rt-private-wp.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route" "route_rt-public-wp1_to_igw-beanstalk-wordpress_ipv4" {
  gateway_id             = aws_internet_gateway.igw-beanstalk-wordpress.id
  route_table_id         = aws_route_table.rt-public-wp1.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table" "rt-private-wp" {
  vpc_id = aws_vpc.vpc-beanstalk-wordpress.id
  tags = {
    Name           = "rt-private-wp"
    State          = "beanstalk-wordpress"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route_table" "rt-public-wp1" {
  vpc_id = aws_vpc.vpc-beanstalk-wordpress.id
  tags = {
    Name           = "rt-public-wp1"
    State          = "beanstalk-wordpress"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route_table_association" "aws_route_table_association_wp_app_a_rt_private_wp" {
  route_table_id = aws_route_table.rt-private-wp.id
  subnet_id      = aws_subnet.wp-app-a.id
}

resource "aws_route_table_association" "aws_route_table_association_wp_app_b_rt_private_wp" {
  route_table_id = aws_route_table.rt-private-wp.id
  subnet_id      = aws_subnet.wp-app-b.id
}

resource "aws_route_table_association" "aws_route_table_association_wp_public_a_rt_public_wp1" {
  route_table_id = aws_route_table.rt-public-wp1.id
  subnet_id      = aws_subnet.wp-public-a.id
}

resource "aws_route_table_association" "aws_route_table_association_wp_public_b_rt_public_wp1" {
  route_table_id = aws_route_table.rt-public-wp1.id
  subnet_id      = aws_subnet.wp-public-b.id
}

resource "aws_security_group" "db_instance_wp-eb-db_group" {
  name                   = "db_instance_wp-eb-db_group"
  vpc_id                 = aws_vpc.vpc-beanstalk-wordpress.id
  revoke_rules_on_delete = false
  tags = {
    Name           = "db_instance_wp-eb-db_group"
    State          = "beanstalk-wordpress"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group" "efs_file_system_wp-eb-files_group" {
  name                   = "efs_file_system_wp-eb-files_group"
  vpc_id                 = aws_vpc.vpc-beanstalk-wordpress.id
  revoke_rules_on_delete = false
  tags = {
    Name           = "efs_file_system_wp-eb-files_group"
    State          = "beanstalk-wordpress"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group" "elastic_beanstalk_environment_beanstalk-wordpress-web_group" {
  name                   = "elastic_beanstalk_environment_beanstalk-wordpress-web_group"
  vpc_id                 = aws_vpc.vpc-beanstalk-wordpress.id
  revoke_rules_on_delete = false
  tags = {
    Name           = "elastic_beanstalk_environment_beanstalk-wordpress-web_group"
    State          = "beanstalk-wordpress"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group_rule" "rule_db_instance_wp_eb_db_group_egress_all_protocols" {
  security_group_id = aws_security_group.db_instance_wp-eb-db_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "rule_efs_file_system_wp_eb_files_group_egress_all_protocols" {
  security_group_id = aws_security_group.efs_file_system_wp-eb-files_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "rule_elastic_beanstalk_environment_beanstalk_wordpress_web_group_egress_all_protocols" {
  security_group_id = aws_security_group.elastic_beanstalk_environment_beanstalk-wordpress-web_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "rule_elastic_beanstalk_environment_beanstalk_wordpress_web_group_to_db_instance_wp_eb_db_group_tcp_3306" {
  security_group_id        = aws_security_group.db_instance_wp-eb-db_group.id
  source_security_group_id = aws_security_group.elastic_beanstalk_environment_beanstalk-wordpress-web_group.id
  description              = "Allow from elastic_beanstalk_environment_beanstalk-wordpress-web_group (tcp:3306-3306)"
  from_port                = 3306
  protocol                 = "tcp"
  to_port                  = 3306
  type                     = "ingress"
}

resource "aws_security_group_rule" "rule_elastic_beanstalk_environment_beanstalk_wordpress_web_group_to_efs_file_system_wp_eb_files_group_tcp_2049" {
  security_group_id        = aws_security_group.efs_file_system_wp-eb-files_group.id
  source_security_group_id = aws_security_group.elastic_beanstalk_environment_beanstalk-wordpress-web_group.id
  description              = "Allow from elastic_beanstalk_environment_beanstalk-wordpress-web_group (tcp:2049-2049)"
  from_port                = 2049
  protocol                 = "tcp"
  to_port                  = 2049
  type                     = "ingress"
}




### CATEGORY: STORAGE ###

resource "aws_s3_bucket" "beanstalk-wordpress-versions" {
  bucket              = "beanstalk-wordpress-versions-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.region}-an"
  bucket_namespace    = "account-regional"
  force_destroy       = true
  object_lock_enabled = false
  tags = {
    Name           = "beanstalk-wordpress-versions"
    State          = "beanstalk-wordpress"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_s3_bucket_ownership_controls" "beanstalk-wordpress-versions_controls" {
  bucket = aws_s3_bucket.beanstalk-wordpress-versions.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "beanstalk-wordpress-versions_block" {
  block_public_acls       = true
  block_public_policy     = true
  bucket                  = aws_s3_bucket.beanstalk-wordpress-versions.id
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "beanstalk-wordpress-versions_configuration" {
  bucket = aws_s3_bucket.beanstalk-wordpress-versions.id
  rule {
    bucket_key_enabled = true
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "beanstalk-wordpress-versions_versioning" {
  bucket = aws_s3_bucket.beanstalk-wordpress-versions.id
  versioning_configuration {
    mfa_delete = "Disabled"
    status     = "Suspended"
  }
}

resource "aws_s3_object" "beanstalk-wordpress-web_bundle" {
  source       = data.archive_file.eb_struct8-templates_beanstalk-wordpress-web.output_path
  bucket       = aws_s3_bucket.beanstalk-wordpress-versions.id
  content_type = "application/zip"
  etag         = filemd5("${data.archive_file.eb_struct8-templates_beanstalk-wordpress-web.output_path}")
  key          = "beanstalk/beanstalk-wordpress-web/${substr(sha1(join(",", [for f in sort(fileset("${path.module}/.external_modules/struct8-templates/templates/beanstalk-wordpress/v1/app", "**")) : "${f}:${filesha1("${path.module}/.external_modules/struct8-templates/templates/beanstalk-wordpress/v1/app/${f}")}"])), 0, 16)}.zip"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_efs_file_system" "wp-eb-files" {
  encrypted       = true
  throughput_mode = "elastic"
  tags = {
    Name           = "wp-eb-files"
    State          = "beanstalk-wordpress"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_efs_mount_target" "mt_wp-eb-files_wp-app-a" {
  file_system_id  = aws_efs_file_system.wp-eb-files.id
  subnet_id       = aws_subnet.wp-app-a.id
  security_groups = [aws_security_group.efs_file_system_wp-eb-files_group.id]
}

resource "aws_efs_mount_target" "mt_wp-eb-files_wp-app-b" {
  file_system_id  = aws_efs_file_system.wp-eb-files.id
  subnet_id       = aws_subnet.wp-app-b.id
  security_groups = [aws_security_group.efs_file_system_wp-eb-files_group.id]
}




### CATEGORY: DATABASE ###

resource "aws_db_instance" "wp-eb-db" {
  db_name                     = "wordpress"
  db_subnet_group_name        = aws_db_subnet_group.subnet_group_wp-eb-db.name
  allocated_storage           = 20
  availability_zone           = aws_subnet.wp-app-a.availability_zone
  backup_retention_period     = 0
  copy_tags_to_snapshot       = true
  engine                      = "mysql"
  engine_lifecycle_support    = "open-source-rds-extended-support-disabled"
  engine_version              = "8.4"
  identifier                  = "wp-eb-db"
  instance_class              = "db.t4g.micro"
  manage_master_user_password = true
  max_allocated_storage       = 100
  skip_final_snapshot         = true
  storage_encrypted           = true
  storage_type                = "gp3"
  upgrade_storage_config      = false
  username                    = "admin"
  vpc_security_group_ids      = [aws_security_group.db_instance_wp-eb-db_group.id]
  tags = {
    Name           = "wp-eb-db"
    State          = "beanstalk-wordpress"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_db_subnet_group" "subnet_group_wp-eb-db" {
  name       = "wp-eb-db-subnet-group"
  subnet_ids = [aws_subnet.wp-app-a.id, aws_subnet.wp-app-b.id]
  tags = {
    Name           = "subnet_group_wp-eb-db"
    State          = "beanstalk-wordpress"
    Struct8Creator = "Contato Struct"
  }
}




### CATEGORY: COMPUTE ###

resource "aws_elastic_beanstalk_application" "beanstalk-wordpress" {
  name = "beanstalk-wordpress"
  tags = {
    State          = "beanstalk-wordpress"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_elastic_beanstalk_application_version" "beanstalk-wordpress-web_version" {
  name        = "beanstalk-wordpress-web-${substr(sha1(join(",", [for f in sort(fileset("${path.module}/.external_modules/struct8-templates/templates/beanstalk-wordpress/v1/app", "**")) : "${f}:${filesha1("${path.module}/.external_modules/struct8-templates/templates/beanstalk-wordpress/v1/app/${f}")}"])), 0, 16)}"
  application = aws_elastic_beanstalk_application.beanstalk-wordpress.name
  bucket      = aws_s3_bucket.beanstalk-wordpress-versions.id
  key         = aws_s3_object.beanstalk-wordpress-web_bundle.key
  lifecycle {
    create_before_destroy = true
  }
}

data "archive_file" "eb_struct8-templates_beanstalk-wordpress-web" {
  output_path = "${path.module}/eb_struct8-templates_beanstalk-wordpress-web_${substr(sha1(join(",", [for f in sort(fileset("${path.module}/.external_modules/struct8-templates/templates/beanstalk-wordpress/v1/app", "**")) : "${f}:${filesha1("${path.module}/.external_modules/struct8-templates/templates/beanstalk-wordpress/v1/app/${f}")}"])), 0, 16)}.zip"
  source_dir  = "${path.module}/.external_modules/struct8-templates/templates/beanstalk-wordpress/v1/app"
  type        = "zip"
}

resource "aws_elastic_beanstalk_environment" "beanstalk-wordpress-web" {
  name                   = "beanstalk-wordpress-web"
  solution_stack_name    = "64bit Amazon Linux 2023 v4.14.0 running Docker"
  application            = aws_elastic_beanstalk_application.beanstalk-wordpress.name
  version_label          = aws_elastic_beanstalk_application_version.beanstalk-wordpress-web_version.name
  wait_for_ready_timeout = "20m"
  setting {
    name      = "NAME"
    namespace = "aws:elasticbeanstalk:application:environment"
    value     = "beanstalk-wordpress-web"
  }
  setting {
    name      = "REGION"
    namespace = "aws:elasticbeanstalk:application:environment"
    value     = "${data.aws_region.current.region}"
  }
  setting {
    name      = "ACCOUNT"
    namespace = "aws:elasticbeanstalk:application:environment"
    value     = "${data.aws_caller_identity.current.account_id}"
  }
  setting {
    name      = "AWS_ELASTIC_BEANSTALK_APPLICATION_NAME_0"
    namespace = "aws:elasticbeanstalk:application:environment"
    value     = "beanstalk-wordpress"
  }
  setting {
    name      = "AWS_DB_INSTANCE_NAME_0"
    namespace = "aws:elasticbeanstalk:application:environment"
    value     = "${aws_db_instance.wp-eb-db.identifier}"
  }
  setting {
    name      = "AWS_DB_INSTANCE_ENGINE_0"
    namespace = "aws:elasticbeanstalk:application:environment"
    value     = "${aws_db_instance.wp-eb-db.engine}"
  }
  setting {
    name      = "AWS_DB_INSTANCE_ENDPOINT_0"
    namespace = "aws:elasticbeanstalk:application:environment"
    value     = "${aws_db_instance.wp-eb-db.endpoint}"
  }
  setting {
    name      = "AWS_DB_INSTANCE_DB_NAME_0"
    namespace = "aws:elasticbeanstalk:application:environment"
    value     = "${aws_db_instance.wp-eb-db.db_name}"
  }
  setting {
    name      = "AWS_DB_INSTANCE_SECRET_ARN_0"
    namespace = "aws:elasticbeanstalk:application:environment"
    value     = "${one(aws_db_instance.wp-eb-db.master_user_secret[*].secret_arn)}"
  }
  setting {
    name      = "AWS_DB_INSTANCE_USER_NAME_0"
    namespace = "aws:elasticbeanstalk:application:environment"
    value     = "${one(aws_db_instance.wp-eb-db.master_user_secret[*].secret_arn)}:username::"
  }
  setting {
    name      = "AWS_EFS_FILE_SYSTEM_ID_0"
    namespace = "aws:elasticbeanstalk:application:environment"
    value     = "${aws_efs_file_system.wp-eb-files.id}"
  }
  setting {
    name      = "AWS_SSM_PARAMETER_NAME_ADMIN"
    namespace = "aws:elasticbeanstalk:application:environment"
    value     = "ebWpAdminPassword"
  }
  setting {
    name      = "VPCId"
    namespace = "aws:ec2:vpc"
    value     = aws_vpc.vpc-beanstalk-wordpress.id
  }
  setting {
    name      = "Subnets"
    namespace = "aws:ec2:vpc"
    value     = "${aws_subnet.wp-app-a.id},${aws_subnet.wp-app-b.id}"
  }
  setting {
    name      = "ELBSubnets"
    namespace = "aws:ec2:vpc"
    value     = "${aws_subnet.wp-public-a.id},${aws_subnet.wp-public-b.id}"
  }
  setting {
    name      = "EnvironmentType"
    namespace = "aws:elasticbeanstalk:environment"
    value     = "LoadBalanced"
  }
  setting {
    name      = "InstanceTypes"
    namespace = "aws:ec2:instances"
    value     = "t4g.small"
  }
  setting {
    name      = "SupportedArchitectures"
    namespace = "aws:ec2:instances"
    value     = "arm64"
  }
  setting {
    name      = "LoadBalancerType"
    namespace = "aws:elasticbeanstalk:environment"
    value     = "application"
  }
  setting {
    name      = "MinSize"
    namespace = "aws:autoscaling:asg"
    value     = "2"
  }
  setting {
    name      = "MaxSize"
    namespace = "aws:autoscaling:asg"
    value     = "4"
  }
  setting {
    name      = "SecurityGroups"
    namespace = "aws:autoscaling:launchconfiguration"
    value     = aws_security_group.elastic_beanstalk_environment_beanstalk-wordpress-web_group.id
  }
  setting {
    name      = "IamInstanceProfile"
    namespace = "aws:autoscaling:launchconfiguration"
    value     = aws_iam_instance_profile.beanstalk-wordpress-web_profile.name
  }
  tags = {
    Struct8Debug   = "vcKwUxgX387SjdjWFmDL_"
    State          = "beanstalk-wordpress"
    Struct8Creator = "Contato Struct"
  }
}




### CATEGORY: CONFIG ###

resource "aws_ssm_document" "Struct8Probe-wp-eb-debug" {
  name = "Struct8Probe-vcKwUxgX387SjdjWFmDL_"
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

resource "aws_ssm_parameter" "ebWpAdminPassword" {
  name        = "ebWpAdminPassword"
  data_type   = "text"
  description = "Password of the WordPress administrator created by the first start of the site. Terraform generates it."
  overwrite   = false
  tier        = "Standard"
  type        = "SecureString"
  value = jsonencode({
    "aws_subnet" = {
      "wp-app-a" = {
        "id"                             = "${aws_subnet.wp-app-a.id}"
        "arn"                            = "${aws_subnet.wp-app-a.arn}"
        "owner_id"                       = "${aws_subnet.wp-app-a.owner_id}"
        "ipv6_cidr_block_association_id" = "${aws_subnet.wp-app-a.ipv6_cidr_block_association_id}"
      }
    }
  })
  lifecycle {
    ignore_changes = [value]
  }
  tags = {
    Name           = "ebWpAdminPassword"
    State          = "beanstalk-wordpress"
    Struct8Creator = "Contato Struct"
  }
}


