terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    random = {
      source = "hashicorp/random"
    }
  }

  backend "s3" {
    bucket  = "struct8-import"
    key     = "952133486861/wordpress-professional/main.tfstate"
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

### SYSTEM DATA SOURCES ###

data "aws_route53_zone" "zoneWordpress" {
  name = "cloudman.pro"
}

data "aws_cloudfront_origin_request_policy" "policy_allviewerexcepthostheader" {
  name = "Managed-AllViewerExceptHostHeader"
}

data "aws_cloudfront_cache_policy" "policy_cachingdisabled" {
  name = "Managed-CachingDisabled"
}

data "aws_cloudfront_response_headers_policy" "policy_securityheaderspolicy" {
  name = "Managed-SecurityHeadersPolicy"
}

data "aws_cloudfront_cache_policy" "policy_cachingoptimized" {
  name = "Managed-CachingOptimized"
}

data "aws_ec2_managed_prefix_list" "cloudfront_origin_facing" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}




### CATEGORY: IAM ###

resource "aws_iam_instance_profile" "asgWordpress_profile" {
  name = "asgWordpress_profile"
  role = aws_iam_role.asgWordpress_role.name
  tags = {
    Name           = "asgWordpress_profile"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
}

data "aws_iam_policy_document" "autoscaling_group_asgWordpress_st_wordpress-professional_doc" {
  statement {
    sid       = "AllowWpcluster"
    effect    = "Allow"
    actions   = ["ecs:DeregisterContainerInstance", "ecs:DiscoverPollEndpoint", "ecs:Poll", "ecs:RegisterContainerInstance", "ecs:StartTelemetrySession", "ecs:Submit*"]
    resources = [aws_ecs_cluster.wp-cluster.arn]
  }
}

resource "aws_iam_policy" "autoscaling_group_asgWordpress_st_wordpress-professional" {
  name        = "autoscaling_group_asgWordpress_st_wordpress-professional"
  description = "Access Policy for asgWordpress"
  policy      = data.aws_iam_policy_document.autoscaling_group_asgWordpress_st_wordpress-professional_doc.json
}

data "aws_iam_policy_document" "ecs_task_definition_wordpress_execution_st_wordpress-professional_doc" {
  statement {
    sid       = "AllowWriteLogs"
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.logsWordpress.arn}:*"]
  }
  statement {
    sid       = "AllowDecryptInjectedSecrets"
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = [aws_kms_key.kmsWordpress.arn]
  }
  statement {
    sid       = "AllowRDSSecretAccesswpaurora"
    effect    = "Allow"
    actions   = ["secretsmanager:DescribeSecret", "secretsmanager:GetSecretValue"]
    resources = [aws_rds_cluster.wp-aurora.master_user_secret[0].secret_arn]
  }
  statement {
    sid       = "AllowSecretAccess"
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [aws_secretsmanager_secret.wpSecrets.arn]
  }
}

resource "aws_iam_policy" "ecs_task_definition_wordpress_execution_st_wordpress-professional" {
  name        = "ecs_task_definition_wordpress_execution_st_wordpress-professional"
  description = "Access Policy for wordpress (Role: execution)"
  policy      = data.aws_iam_policy_document.ecs_task_definition_wordpress_execution_st_wordpress-professional_doc.json
}

data "aws_iam_policy_document" "ecs_task_definition_wordpress_st_wordpress-professional_doc" {
  statement {
    sid       = "AllowEFSBasicAccess"
    effect    = "Allow"
    actions   = ["elasticfilesystem:ClientMount", "elasticfilesystem:ClientWrite"]
    resources = [aws_efs_file_system.wpContent.arn]
  }
  statement {
    sid       = "AllowRDSSecretAccesswpaurora"
    effect    = "Allow"
    actions   = ["secretsmanager:DescribeSecret", "secretsmanager:GetSecretValue"]
    resources = [aws_rds_cluster.wp-aurora.master_user_secret[0].secret_arn]
  }
  statement {
    sid       = "AllowBucketLevelActions"
    effect    = "Allow"
    actions   = ["s3:GetBucketLocation", "s3:GetBucketOwnershipControls", "s3:GetBucketPublicAccessBlock", "s3:ListBucket"]
    resources = [aws_s3_bucket.wpMedia.arn]
  }
  statement {
    sid       = "AllowObjectCRUD"
    effect    = "Allow"
    actions   = ["s3:DeleteObject", "s3:GetObject", "s3:PutObject"]
    resources = ["${aws_s3_bucket.wpMedia.arn}/*"]
  }
}

resource "aws_iam_policy" "ecs_task_definition_wordpress_st_wordpress-professional" {
  name        = "ecs_task_definition_wordpress_st_wordpress-professional"
  description = "Access Policy for wordpress"
  policy      = data.aws_iam_policy_document.ecs_task_definition_wordpress_st_wordpress-professional_doc.json
}

resource "aws_iam_role" "asgWordpress_role" {
  name = "asgWordpress_role"
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
    Name           = "asgWordpress_role"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "execution_role_ecs_wordpress" {
  name = "execution_role_ecs_wordpress"
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
  tags = {
    Name           = "execution_role_ecs_wordpress"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "task_role_ecs_wordpress" {
  name = "task_role_ecs_wordpress"
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
  tags = {
    Name           = "task_role_ecs_wordpress"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role_policy_attachment" "autoscaling_group_asgWordpress_st_wordpress-professional_attach" {
  policy_arn = aws_iam_policy.autoscaling_group_asgWordpress_st_wordpress-professional.arn
  role       = aws_iam_role.asgWordpress_role.name
}

resource "aws_iam_role_policy_attachment" "ecs_task_definition_wordpress_execution_st_wordpress-professional_attach" {
  policy_arn = aws_iam_policy.ecs_task_definition_wordpress_execution_st_wordpress-professional.arn
  role       = aws_iam_role.execution_role_ecs_wordpress.name
}

resource "aws_iam_role_policy_attachment" "ecs_task_definition_wordpress_st_wordpress-professional_attach" {
  policy_arn = aws_iam_policy.ecs_task_definition_wordpress_st_wordpress-professional.arn
  role       = aws_iam_role.task_role_ecs_wordpress.name
}

resource "aws_iam_role_policy_attachment" "service_role_AmazonEC2ContainerServiceforEC2Role_to_asgWordpress_attach" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
  role       = aws_iam_role.asgWordpress_role.name
}

resource "aws_kms_key" "kmsWordpress" {
  bypass_policy_lockout_safety_check = false
  deletion_window_in_days            = 30
  enable_key_rotation                = true
  is_enabled                         = true
  multi_region                       = false
  rotation_period_in_days            = 365
  tags = {
    Name           = "kmsWordpress"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_secretsmanager_secret" "wpSecrets" {
  kms_key_id              = aws_kms_key.kmsWordpress.id
  name                    = "wpSecrets"
  description             = "Password of the WordPress database user. Terraform generates it, and each WordPress task creates or updates that user at startup with the Aurora master credentials."
  recovery_window_in_days = 0
  tags = {
    Name           = "wpSecrets"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_secretsmanager_secret_version" "wpSecrets_version" {
  secret_id      = aws_secretsmanager_secret.wpSecrets.id
  secret_string  = random_password.wpDbPassword.result
  version_stages = ["AWSCURRENT"]
}

resource "aws_acm_certificate" "certAlb" {
  domain_name       = "origin.wp.cloudman.pro"
  key_algorithm     = "RSA_2048"
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
  options {
    certificate_transparency_logging_preference = "ENABLED"
  }
  tags = {
    Name           = "certAlb"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_acm_certificate" "certWordpress" {
  domain_name       = "wp.cloudman.pro"
  key_algorithm     = "RSA_2048"
  region            = "us-east-1"
  validation_method = "DNS"
  options {
    certificate_transparency_logging_preference = "ENABLED"
  }
  tags = {
    Name           = "certWordpress"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_acm_certificate_validation" "Validation_certAlb" {
  certificate_arn         = aws_acm_certificate.certAlb.arn
  validation_record_fqdns = [for record in aws_route53_record.Route53_Record_certAlb_origin_wp_cloudman_pro : record.fqdn]
}

resource "aws_acm_certificate_validation" "Validation_certWordpress" {
  certificate_arn         = aws_acm_certificate.certWordpress.arn
  region                  = "us-east-1"
  validation_record_fqdns = [for record in aws_route53_record.Route53_Record_certWordpress_wp_cloudman_pro : record.fqdn]
}




### CATEGORY: NETWORK ###

resource "aws_vpc" "wordpress-professional" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default"
  tags = {
    Name           = "wordpress-professional"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_vpc_endpoint" "vpce-s3_S3" {
  service_name      = "com.amazonaws.us-west-2.s3"
  vpc_id            = aws_vpc.wordpress-professional.id
  route_table_ids   = [aws_route_table.rt-public-wp.id, aws_route_table.rtPrivate.id]
  vpc_endpoint_type = "Gateway"
  tags = {
    DifName        = "vpce-s3_S3"
    Name           = "vpce-s3"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
  timeouts {
    create = "10m"
    delete = "10m"
    update = "10m"
  }
}

resource "aws_vpc_endpoint" "vpceLogs_LOGS" {
  service_name        = "com.amazonaws.${data.aws_region.current.region}.logs"
  vpc_id              = aws_vpc.wordpress-professional.id
  ip_address_type     = "ipv4"
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.sg_vpce_vpceLogs.id]
  subnet_ids          = [aws_subnet.appB.id, aws_subnet.appA.id]
  vpc_endpoint_type   = "Interface"
  tags = {
    Name           = "vpceLogs"
    DifName        = "vpceLogs_LOGS"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
  timeouts {
    create = "10m"
    delete = "10m"
    update = "10m"
  }
}

resource "aws_vpc_endpoint" "vpceSecrets_SECRETSMANAGER" {
  service_name        = "com.amazonaws.${data.aws_region.current.region}.secretsmanager"
  vpc_id              = aws_vpc.wordpress-professional.id
  ip_address_type     = "ipv4"
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.sg_vpce_vpceSecrets.id]
  subnet_ids          = [aws_subnet.appB.id, aws_subnet.appA.id]
  vpc_endpoint_type   = "Interface"
  tags = {
    Name           = "vpceSecrets"
    DifName        = "vpceSecrets_SECRETSMANAGER"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
  timeouts {
    create = "10m"
    delete = "10m"
    update = "10m"
  }
}

resource "aws_subnet" "appA" {
  vpc_id                  = aws_vpc.wordpress-professional.id
  availability_zone       = "us-west-2a"
  cidr_block              = "10.0.11.0/24"
  map_public_ip_on_launch = false
  tags = {
    Name           = "appA"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "appB" {
  vpc_id                  = aws_vpc.wordpress-professional.id
  availability_zone       = "us-west-2b"
  cidr_block              = "10.0.12.0/24"
  map_public_ip_on_launch = false
  tags = {
    Name           = "appB"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "dataA" {
  vpc_id                  = aws_vpc.wordpress-professional.id
  availability_zone       = "us-west-2a"
  cidr_block              = "10.0.21.0/24"
  map_public_ip_on_launch = false
  tags = {
    Name           = "dataA"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "dataB" {
  vpc_id                  = aws_vpc.wordpress-professional.id
  availability_zone       = "us-west-2b"
  cidr_block              = "10.0.22.0/24"
  map_public_ip_on_launch = false
  tags = {
    Name           = "dataB"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "pubA" {
  vpc_id                  = aws_vpc.wordpress-professional.id
  availability_zone       = "us-west-2a"
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name           = "pubA"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "pubB" {
  vpc_id                  = aws_vpc.wordpress-professional.id
  availability_zone       = "us-west-2b"
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name           = "pubB"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_internet_gateway" "igw-wp" {
  vpc_id = aws_vpc.wordpress-professional.id
  tags = {
    Name           = "igw-wp"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_nat_gateway" "nat-wp" {
  vpc_id            = aws_vpc.wordpress-professional.id
  availability_mode = "regional"
  connectivity_type = "public"
  tags = {
    Name           = "nat-wp"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_internet_gateway.igw-wp]
}

resource "aws_route" "route_rt-public-wp_to_igw-wp_ipv4" {
  gateway_id             = aws_internet_gateway.igw-wp.id
  route_table_id         = aws_route_table.rt-public-wp.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route" "route_rtPrivate_to_nat-wp_ipv4" {
  nat_gateway_id         = aws_nat_gateway.nat-wp.id
  route_table_id         = aws_route_table.rtPrivate.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route53_record" "Route53_Record_certAlb_origin_wp_cloudman_pro" {
  for_each = {
    for dvo in aws_acm_certificate.certAlb.domain_validation_options : dvo.domain_name => dvo
    if dvo.domain_name == "origin.wp.cloudman.pro"
  }
  name            = each.value.resource_record_name
  zone_id         = data.aws_route53_zone.zoneWordpress.zone_id
  allow_overwrite = true
  records         = [each.value.resource_record_value]
  ttl             = 300
  type            = each.value.resource_record_type
}

resource "aws_route53_record" "Route53_Record_certWordpress_wp_cloudman_pro" {
  for_each = {
    for dvo in aws_acm_certificate.certWordpress.domain_validation_options : dvo.domain_name => dvo
    if dvo.domain_name == "wp.cloudman.pro"
  }
  name            = each.value.resource_record_name
  zone_id         = data.aws_route53_zone.zoneWordpress.zone_id
  allow_overwrite = true
  records         = [each.value.resource_record_value]
  ttl             = 300
  type            = each.value.resource_record_type
}

resource "aws_route53_record" "alias_a_aws_cloudfront_distribution_cdnWordpress_wp_cloudman_pro" {
  name    = "wp.cloudman.pro"
  zone_id = data.aws_route53_zone.zoneWordpress.zone_id
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.cdnWordpress.domain_name
    zone_id                = aws_cloudfront_distribution.cdnWordpress.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "alias_a_aws_lb_alb-wp_origin_wp_cloudman_pro" {
  name    = "origin.wp.cloudman.pro"
  zone_id = data.aws_route53_zone.zoneWordpress.zone_id
  type    = "A"
  alias {
    name                   = aws_lb.alb-wp.dns_name
    zone_id                = aws_lb.alb-wp.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "alias_aaaa_aws_cloudfront_distribution_cdnWordpress_wp_cloudman_pro" {
  name    = "wp.cloudman.pro"
  zone_id = data.aws_route53_zone.zoneWordpress.zone_id
  type    = "AAAA"
  alias {
    name                   = aws_cloudfront_distribution.cdnWordpress.domain_name
    zone_id                = aws_cloudfront_distribution.cdnWordpress.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route_table" "rt-public-wp" {
  vpc_id = aws_vpc.wordpress-professional.id
  tags = {
    Name           = "rt-public-wp"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route_table" "rtPrivate" {
  vpc_id = aws_vpc.wordpress-professional.id
  tags = {
    Name           = "rtPrivate"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route_table_association" "aws_route_table_association_appA_rtPrivate" {
  route_table_id = aws_route_table.rtPrivate.id
  subnet_id      = aws_subnet.appA.id
}

resource "aws_route_table_association" "aws_route_table_association_appB_rtPrivate" {
  route_table_id = aws_route_table.rtPrivate.id
  subnet_id      = aws_subnet.appB.id
}

resource "aws_route_table_association" "aws_route_table_association_pubA_rt_public_wp" {
  route_table_id = aws_route_table.rt-public-wp.id
  subnet_id      = aws_subnet.pubA.id
}

resource "aws_route_table_association" "aws_route_table_association_pubB_rt_public_wp" {
  route_table_id = aws_route_table.rt-public-wp.id
  subnet_id      = aws_subnet.pubB.id
}

resource "aws_security_group" "alb-cloudfront-wp" {
  name                   = "alb-cloudfront-wp"
  vpc_id                 = aws_vpc.wordpress-professional.id
  description            = "HTTPS from CloudFront origin-facing servers to the WordPress load balancer"
  revoke_rules_on_delete = false
  tags = {
    Name           = "alb-cloudfront-wp"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group" "autoscaling_group_asgWordpress_group" {
  name                   = "autoscaling_group_asgWordpress_group"
  vpc_id                 = aws_vpc.wordpress-professional.id
  revoke_rules_on_delete = false
  tags = {
    Name           = "autoscaling_group_asgWordpress_group"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group" "ecs_task_definition_wordpress_group" {
  name                   = "ecs_task_definition_wordpress_group"
  vpc_id                 = aws_vpc.wordpress-professional.id
  revoke_rules_on_delete = false
  tags = {
    Name           = "ecs_task_definition_wordpress_group"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group" "efs_file_system_wpContent_group" {
  name                   = "efs_file_system_wpContent_group"
  vpc_id                 = aws_vpc.wordpress-professional.id
  revoke_rules_on_delete = false
  tags = {
    Name           = "efs_file_system_wpContent_group"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group" "elasticache_replication_group_wpRedis_group" {
  name                   = "elasticache_replication_group_wpRedis_group"
  vpc_id                 = aws_vpc.wordpress-professional.id
  revoke_rules_on_delete = false
  tags = {
    Name           = "elasticache_replication_group_wpRedis_group"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group" "lb_alb-wp_group" {
  name                   = "lb_alb-wp_group"
  vpc_id                 = aws_vpc.wordpress-professional.id
  revoke_rules_on_delete = false
  tags = {
    Name           = "lb_alb-wp_group"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group" "rds_cluster_wp-aurora_group" {
  name                   = "rds_cluster_wp-aurora_group"
  vpc_id                 = aws_vpc.wordpress-professional.id
  revoke_rules_on_delete = false
  tags = {
    Name           = "rds_cluster_wp-aurora_group"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group" "sg_vpce_vpceLogs" {
  name        = "vpce-sg-vpcelogs"
  vpc_id      = aws_vpc.wordpress-professional.id
  description = "Auto-generated SG for vpceLogs"
  tags = {
    Name           = "vpceLogs"
    DifName        = "sg_vpce_vpceLogs"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group" "sg_vpce_vpceSecrets" {
  name        = "vpce-sg-vpcesecrets"
  vpc_id      = aws_vpc.wordpress-professional.id
  description = "Auto-generated SG for vpceSecrets"
  tags = {
    Name           = "vpceSecrets"
    DifName        = "sg_vpce_vpceSecrets"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group_rule" "rule_alb_cloudfront_wp_cloudfront_tcp_443" {
  security_group_id = aws_security_group.alb-cloudfront-wp.id
  description       = "HTTPS from CloudFront"
  from_port         = 443
  prefix_list_ids   = [data.aws_ec2_managed_prefix_list.cloudfront_origin_facing.id]
  protocol          = "tcp"
  to_port           = 443
  type              = "ingress"
}

resource "aws_security_group_rule" "rule_alb_cloudfront_wp_egress_all_protocols" {
  security_group_id = aws_security_group.alb-cloudfront-wp.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "rule_autoscaling_group_asgWordpress_group_egress_all_protocols" {
  security_group_id = aws_security_group.autoscaling_group_asgWordpress_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "rule_ecs_task_definition_wordpress_group_egress_all_protocols" {
  security_group_id = aws_security_group.ecs_task_definition_wordpress_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "rule_ecs_task_definition_wordpress_group_to_efs_file_system_wpContent_group_tcp_2049" {
  security_group_id        = aws_security_group.efs_file_system_wpContent_group.id
  source_security_group_id = aws_security_group.ecs_task_definition_wordpress_group.id
  description              = "NFS from the WordPress tasks to EFS"
  from_port                = 2049
  protocol                 = "tcp"
  to_port                  = 2049
  type                     = "ingress"
}

resource "aws_security_group_rule" "rule_ecs_task_definition_wordpress_group_to_elasticache_replication_group_wpRedis_group_tcp_6379" {
  security_group_id        = aws_security_group.elasticache_replication_group_wpRedis_group.id
  source_security_group_id = aws_security_group.ecs_task_definition_wordpress_group.id
  description              = "Redis from the WordPress tasks"
  from_port                = 6379
  protocol                 = "tcp"
  to_port                  = 6379
  type                     = "ingress"
}

resource "aws_security_group_rule" "rule_ecs_task_definition_wordpress_group_to_rds_cluster_wp_aurora_group_tcp_3306" {
  security_group_id        = aws_security_group.rds_cluster_wp-aurora_group.id
  source_security_group_id = aws_security_group.ecs_task_definition_wordpress_group.id
  description              = "MySQL from the WordPress tasks"
  from_port                = 3306
  protocol                 = "tcp"
  to_port                  = 3306
  type                     = "ingress"
}

resource "aws_security_group_rule" "rule_efs_file_system_wpContent_group_egress_all_protocols" {
  security_group_id = aws_security_group.efs_file_system_wpContent_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "rule_elasticache_replication_group_wpRedis_group_egress_all_protocols" {
  security_group_id = aws_security_group.elasticache_replication_group_wpRedis_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "rule_lb_alb_wp_group_egress_all_protocols" {
  security_group_id = aws_security_group.lb_alb-wp_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "rule_lb_alb_wp_group_to_ecs_task_definition_wordpress_group_tcp_443" {
  security_group_id        = aws_security_group.ecs_task_definition_wordpress_group.id
  source_security_group_id = aws_security_group.lb_alb-wp_group.id
  description              = "HTTPS from the load balancer to the WordPress tasks"
  from_port                = 443
  protocol                 = "tcp"
  to_port                  = 443
  type                     = "ingress"
}

resource "aws_security_group_rule" "rule_rds_cluster_wp_aurora_group_egress_all_protocols" {
  security_group_id = aws_security_group.rds_cluster_wp-aurora_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "rule_sg_vpce_vpceLogs_egress_all_protocols" {
  security_group_id = aws_security_group.sg_vpce_vpceLogs.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow all outbound traffic"
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "rule_sg_vpce_vpceLogs_ingress_tcp_443" {
  security_group_id = aws_security_group.sg_vpce_vpceLogs.id
  cidr_blocks       = ["10.0.0.0/16"]
  description       = "Allow HTTPS from VPC"
  from_port         = 443
  protocol          = "tcp"
  to_port           = 443
  type              = "ingress"
}

resource "aws_security_group_rule" "rule_sg_vpce_vpceSecrets_egress_all_protocols" {
  security_group_id = aws_security_group.sg_vpce_vpceSecrets.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow all outbound traffic"
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "rule_sg_vpce_vpceSecrets_ingress_tcp_443" {
  security_group_id = aws_security_group.sg_vpce_vpceSecrets.id
  cidr_blocks       = ["10.0.0.0/16"]
  description       = "Allow HTTPS from VPC"
  from_port         = 443
  protocol          = "tcp"
  to_port           = 443
  type              = "ingress"
}

resource "aws_lb" "alb-wp" {
  name                             = "albWordpress"
  drop_invalid_header_fields       = true
  enable_cross_zone_load_balancing = true
  enable_http2                     = true
  idle_timeout                     = 60
  load_balancer_type               = "application"
  preserve_host_header             = true
  security_groups                  = [aws_security_group.alb-cloudfront-wp.id, aws_security_group.lb_alb-wp_group.id]
  subnets                          = [aws_subnet.pubA.id, aws_subnet.pubB.id]
  access_logs {
    bucket  = aws_s3_bucket.albLogs.id
    enabled = true
  }
  tags = {
    Name           = "alb-wp"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_s3_bucket_policy.aws_s3_bucket_policy_albLogs_st_wordpress-professional]
}

resource "aws_lb_listener" "listenerHttps" {
  certificate_arn                      = aws_acm_certificate_validation.Validation_certAlb.certificate_arn
  load_balancer_arn                    = aws_lb.alb-wp.arn
  port                                 = 443
  protocol                             = "HTTPS"
  routing_http_response_server_enabled = true
  ssl_policy                           = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  default_action {
    order = 1
    type  = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Forbidden"
      status_code  = "403"
    }
  }
  tags = {
    Name           = "listenerHttps"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_lb_listener_rule" "ruleFromCloudFront" {
  action {
    order = 1
    type  = "forward"
    forward {
      target_group {
        arn = aws_lb_target_group.tgWordpress.arn
      }
    }
  }
  condition {
    http_header {
      http_header_name = "X-Origin-Verify"
      values           = [random_id.originVerify.hex]
    }
  }
  listener_arn = aws_lb_listener.listenerHttps.arn
  priority     = 1
  tags = {
    Name           = "ruleFromCloudFront"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_lb_target_group" "tgWordpress" {
  name                          = "tgWordpress"
  vpc_id                        = aws_vpc.wordpress-professional.id
  deregistration_delay          = "300"
  ip_address_type               = "ipv4"
  load_balancing_algorithm_type = "round_robin"
  port                          = 443
  protocol                      = "HTTPS"
  slow_start                    = 0
  target_type                   = "ip"
  health_check {
    enabled             = true
    healthy_threshold   = 3
    interval            = 30
    matcher             = "200-399"
    path                = "/"
    port                = 443
    protocol            = "HTTPS"
    timeout             = 5
    unhealthy_threshold = 3
  }
  tags = {
    Name           = "tgWordpress"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_cloudfront_distribution" "cdnWordpress" {
  # ajuste manual · origin[origin_id=originAlb].domain_name — The generator always writes the load balancer's own DNS name as the origin and ignores a typed domain_name. CloudFront validates the origin certificate against this name, and only origin.wp.<zone> is on certAlb, so HTTPS to the load balancer needs it here.
  aliases         = ["wp.cloudman.pro"]
  enabled         = true
  http_version    = "http2and3"
  is_ipv6_enabled = true
  price_class     = "PriceClass_All"
  default_cache_behavior {
    cache_policy_id            = data.aws_cloudfront_cache_policy.policy_cachingdisabled.id
    origin_request_policy_id   = data.aws_cloudfront_origin_request_policy.policy_allviewerexcepthostheader.id
    response_headers_policy_id = data.aws_cloudfront_response_headers_policy.policy_securityheaderspolicy.id
    target_origin_id           = "originAlb"
    allowed_methods            = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods             = ["GET", "HEAD", "OPTIONS"]
    viewer_protocol_policy     = "redirect-to-https"
  }
  ordered_cache_behavior {
    cache_policy_id            = data.aws_cloudfront_cache_policy.policy_cachingdisabled.id
    origin_request_policy_id   = data.aws_cloudfront_origin_request_policy.policy_allviewerexcepthostheader.id
    response_headers_policy_id = data.aws_cloudfront_response_headers_policy.policy_securityheaderspolicy.id
    target_origin_id           = "originAlb"
    allowed_methods            = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods             = ["GET", "HEAD", "OPTIONS"]
    path_pattern               = "/wp-admin/*"
    viewer_protocol_policy     = "redirect-to-https"
  }
  ordered_cache_behavior {
    cache_policy_id            = data.aws_cloudfront_cache_policy.policy_cachingoptimized.id
    response_headers_policy_id = data.aws_cloudfront_response_headers_policy.policy_securityheaderspolicy.id
    target_origin_id           = "originMedia"
    allowed_methods            = ["GET", "HEAD", "OPTIONS"]
    cached_methods             = ["GET", "HEAD", "OPTIONS"]
    path_pattern               = "/wp-content/media/*"
    viewer_protocol_policy     = "redirect-to-https"
  }
  ordered_cache_behavior {
    cache_policy_id            = data.aws_cloudfront_cache_policy.policy_cachingoptimized.id
    response_headers_policy_id = data.aws_cloudfront_response_headers_policy.policy_securityheaderspolicy.id
    target_origin_id           = "originAlb"
    allowed_methods            = ["GET", "HEAD", "OPTIONS"]
    cached_methods             = ["GET", "HEAD", "OPTIONS"]
    path_pattern               = "/wp-content/*"
    viewer_protocol_policy     = "redirect-to-https"
  }
  origin {
    domain_name              = aws_s3_bucket.wpMedia.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.oac_wpmedia.id
    origin_id                = "originMedia"
  }
  origin {
    domain_name = "origin.wp.${data.aws_route53_zone.zoneWordpress.name}"
    origin_id   = "originAlb"
    custom_header {
      name  = "X-Origin-Verify"
      value = random_id.originVerify.hex
    }
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  tags = {
    Name           = "cdnWordpress"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
  viewer_certificate {
    acm_certificate_arn            = aws_acm_certificate_validation.Validation_certWordpress.certificate_arn
    cloudfront_default_certificate = false
    minimum_protocol_version       = "TLSv1.2_2021"
    ssl_support_method             = "sni-only"
  }
}

resource "aws_cloudfront_origin_access_control" "oac_wpmedia" {
  name                              = "oac-wpmedia"
  description                       = "OAC for wpmedia"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}




### CATEGORY: STORAGE ###

resource "aws_s3_bucket" "albLogs" {
  bucket              = "wp-pro-access-logs-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.region}-an"
  bucket_namespace    = "account-regional"
  force_destroy       = false
  object_lock_enabled = false
  tags = {
    Name           = "albLogs"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_s3_bucket" "wpMedia" {
  bucket              = "wp-pro-media-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.region}-an"
  bucket_namespace    = "account-regional"
  force_destroy       = false
  object_lock_enabled = false
  tags = {
    Name           = "wpMedia"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_s3_bucket_ownership_controls" "albLogs_controls" {
  bucket = aws_s3_bucket.albLogs.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_ownership_controls" "wpMedia_controls" {
  bucket = aws_s3_bucket.wpMedia.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

data "aws_iam_policy_document" "aws_s3_bucket_policy_albLogs_st_wordpress-professional_doc" {
  statement {
    sid    = "AllowElbAccessLogs"
    effect = "Allow"
    principals {
      identifiers = ["logdelivery.elasticloadbalancing.amazonaws.com"]
      type        = "Service"
    }
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.albLogs.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]
    condition {
      test     = "ArnLike"
      values   = ["arn:aws:elasticloadbalancing:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:loadbalancer/*"]
      variable = "aws:SourceArn"
    }
  }
}

resource "aws_s3_bucket_policy" "aws_s3_bucket_policy_albLogs_st_wordpress-professional" {
  bucket = aws_s3_bucket.albLogs.id
  policy = data.aws_iam_policy_document.aws_s3_bucket_policy_albLogs_st_wordpress-professional_doc.json
}

data "aws_iam_policy_document" "aws_s3_bucket_policy_wpMedia_st_wordpress-professional_doc" {
  statement {
    sid    = "AllowCloudFrontServicePrincipalReadOnly"
    effect = "Allow"
    principals {
      identifiers = ["cloudfront.amazonaws.com"]
      type        = "Service"
    }
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.wpMedia.arn}/*"]
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = ["arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${aws_cloudfront_distribution.cdnWordpress.id}"]
    }
  }
}

resource "aws_s3_bucket_policy" "aws_s3_bucket_policy_wpMedia_st_wordpress-professional" {
  bucket = aws_s3_bucket.wpMedia.id
  policy = data.aws_iam_policy_document.aws_s3_bucket_policy_wpMedia_st_wordpress-professional_doc.json
}

resource "aws_s3_bucket_public_access_block" "albLogs_block" {
  block_public_acls       = true
  block_public_policy     = true
  bucket                  = aws_s3_bucket.albLogs.id
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "wpMedia_block" {
  block_public_acls       = true
  block_public_policy     = true
  bucket                  = aws_s3_bucket.wpMedia.id
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "albLogs_configuration" {
  bucket = aws_s3_bucket.albLogs.id
  rule {
    bucket_key_enabled = true
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "wpMedia_configuration" {
  bucket = aws_s3_bucket.wpMedia.id
  rule {
    bucket_key_enabled = true
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "albLogs_versioning" {
  bucket = aws_s3_bucket.albLogs.id
  versioning_configuration {
    mfa_delete = "Disabled"
    status     = "Suspended"
  }
}

resource "aws_s3_bucket_versioning" "wpMedia_versioning" {
  bucket = aws_s3_bucket.wpMedia.id
  versioning_configuration {
    mfa_delete = "Disabled"
    status     = "Suspended"
  }
}

resource "aws_efs_access_point" "ap_wordpress_wpContent" {
  file_system_id = aws_efs_file_system.wpContent.id
  posix_user {
    gid = "33"
    uid = "33"
  }
  root_directory {
    path = "/wordpress"
    creation_info {
      owner_gid   = "33"
      owner_uid   = "33"
      permissions = "0755"
    }
  }
  tags = {
    Name           = "ap_wordpress_wpContent"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_efs_file_system" "wpContent" {
  encrypted       = true
  throughput_mode = "elastic"
  tags = {
    Name           = "wpContent"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_efs_mount_target" "mt_wpContent_dataA" {
  file_system_id  = aws_efs_file_system.wpContent.id
  subnet_id       = aws_subnet.dataA.id
  security_groups = [aws_security_group.efs_file_system_wpContent_group.id]
}

resource "aws_efs_mount_target" "mt_wpContent_dataB" {
  file_system_id  = aws_efs_file_system.wpContent.id
  subnet_id       = aws_subnet.dataB.id
  security_groups = [aws_security_group.efs_file_system_wpContent_group.id]
}




### CATEGORY: DATABASE ###

resource "aws_db_subnet_group" "subnet_group_wp-aurora" {
  name       = "wp-aurora-subnet-group"
  subnet_ids = [aws_subnet.dataA.id, aws_subnet.dataB.id]
  tags = {
    Name           = "subnet_group_wp-aurora"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_rds_cluster" "wp-aurora" {
  database_name               = "wordpress"
  db_subnet_group_name        = aws_db_subnet_group.subnet_group_wp-aurora.name
  kms_key_id                  = aws_kms_key.kmsWordpress.arn
  apply_immediately           = true
  backup_retention_period     = 7
  cluster_identifier          = "wp-aurora"
  copy_tags_to_snapshot       = true
  database_insights_mode      = "standard"
  engine                      = "aurora-mysql"
  engine_version              = "8.4.mysql_aurora.8.4.8"
  manage_master_user_password = true
  master_username             = "dbadmin"
  monitoring_interval         = 0
  network_type                = "IPV4"
  port                        = 3306
  skip_final_snapshot         = true
  storage_encrypted           = true
  vpc_security_group_ids      = [aws_security_group.rds_cluster_wp-aurora_group.id]
  serverlessv2_scaling_configuration {
    max_capacity             = 2
    min_capacity             = 0
    seconds_until_auto_pause = 300
  }
  tags = {
    Name           = "wp-aurora"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_rds_cluster_instance" "wp-aurora-reader" {
  cluster_identifier                    = aws_rds_cluster.wp-aurora.id
  copy_tags_to_snapshot                 = true
  engine                                = aws_rds_cluster.wp-aurora.engine
  identifier                            = "wp-aurora-reader"
  instance_class                        = "db.serverless"
  performance_insights_retention_period = 7
  promotion_tier                        = 2
  tags = {
    Name           = "wp-aurora-reader"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_rds_cluster_instance" "wp-aurora-writer" {
  cluster_identifier                    = aws_rds_cluster.wp-aurora.id
  copy_tags_to_snapshot                 = true
  engine                                = aws_rds_cluster.wp-aurora.engine
  identifier                            = "wp-aurora-writer"
  instance_class                        = "db.serverless"
  performance_insights_retention_period = 7
  promotion_tier                        = 1
  tags = {
    Name           = "wp-aurora-writer"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_elasticache_replication_group" "wpRedis" {
  kms_key_id                 = aws_kms_key.kmsWordpress.arn
  replication_group_id       = "wp-object-cache"
  at_rest_encryption_enabled = true
  automatic_failover_enabled = true
  cluster_mode               = "disabled"
  description                = "WordPress object cache for wp_options, postmeta and transients."
  engine_version             = "7.1"
  multi_az_enabled           = true
  node_type                  = "cache.t4g.small"
  num_cache_clusters         = 2
  security_group_ids         = [aws_security_group.elasticache_replication_group_wpRedis_group.id]
  snapshot_retention_limit   = 7
  transit_encryption_enabled = true
  tags = {
    Name           = "wpRedis"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
}




### CATEGORY: COMPUTE ###

data "aws_ami" "AMI_Data_Source_ltWordpress" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-ecs-hvm-2023.*-kernel-6.1-arm64"]
  }
  filter {
    name   = "architecture"
    values = ["arm64"]
  }
}

resource "aws_launch_template" "ltWordpress" {
  image_id               = data.aws_ami.AMI_Data_Source_ltWordpress.id
  name                   = "ltWordpress"
  instance_type          = "t4g.small"
  update_default_version = true
  user_data = base64encode(<<-EOFUData
#!/bin/bash

# --- BEGIN STRUCT8 VARIABLES ---
cat << 'EOFENV' > /etc/struct8_env
ECS_CLUSTER="${aws_ecs_cluster.wp-cluster.name}"
NAME="asgWordpress"
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

# Tasks use awsvpc: keep them away from the instance metadata service and the instance role.
mkdir -p /etc/ecs
echo "ECS_AWSVPC_BLOCK_IMDS=true" >> /etc/ecs/ecs.config

EOFUData
)
  block_device_mappings {
    device_name = "/dev/xvda"
    no_device   = false
    ebs {
      delete_on_termination = true
      encrypted             = true
      iops                  = 3000
      throughput            = 125
      volume_size           = 30
      volume_type           = "gp3"
    }
  }
  credit_specification {
    cpu_credits = "standard"
  }
  enclave_options {
    enabled = false
  }
  hibernation_options {
    configured = false
  }
  iam_instance_profile {
    name = aws_iam_instance_profile.asgWordpress_profile.name
  }
  metadata_options {
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 1
    http_tokens                 = "required"
  }
  monitoring {
    enabled = false
  }
  network_interfaces {
    delete_on_termination = true
    security_groups       = [aws_security_group.autoscaling_group_asgWordpress_group.id]
  }
  placement {
    partition_number = 0
    tenancy          = "default"
  }
  private_dns_name_options {
    enable_resource_name_dns_a_record    = false
    enable_resource_name_dns_aaaa_record = false
    hostname_type                        = "ip-name"
  }
  tag_specifications {
  }
  tag_specifications {
    resource_type = "volume"
    tags = {
    AmazonECSManaged = true
    Name             = "asgWordpress"
    State            = "wordpress-professional"
    Struct8Creator   = "Contato Struct"
  }
  }
  tags = {
    Name           = "ltWordpress"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_autoscaling_group" "asgWordpress" {
  name                    = "asgWordpress"
  default_instance_warmup = 0
  desired_capacity        = 2
  health_check_type       = "EC2"
  max_instance_lifetime   = 0
  max_size                = 6
  metrics_granularity     = "1Minute"
  min_elb_capacity        = 0
  min_size                = 2
  termination_policies    = ["Default"]
  vpc_zone_identifier     = [aws_subnet.appA.id, aws_subnet.appB.id]
  wait_for_elb_capacity   = 0
  instance_maintenance_policy {
    max_healthy_percentage = 100
    min_healthy_percentage = 90
  }
  instance_refresh {
    strategy = "Rolling"
  }
  launch_template {
    version = aws_launch_template.ltWordpress.latest_version
    id      = aws_launch_template.ltWordpress.id
  }
  tag {
    key                 = "AmazonECSManaged"
    propagate_at_launch = true
    value               = true
  }
  tag {
    key                 = "Name"
    propagate_at_launch = true
    value               = "asgWordpress"
  }
  tag {
    key                 = "State"
    propagate_at_launch = true
    value               = "wordpress-professional"
  }
  tag {
    key                 = "Struct8Creator"
    propagate_at_launch = true
    value               = "Contato Struct"
  }
}




### CATEGORY: CONTAINERS ###

resource "aws_ecs_capacity_provider" "wp-capacity" {
  name = "wp-capacity"
  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.asgWordpress.arn
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
    Name           = "wp-capacity"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_ecs_cluster" "wp-cluster" {
  name = "wp-cluster"
  tags = {
    Name           = "wp-cluster"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_ecs_cluster_capacity_providers" "assoc_cp_to_wp-cluster" {
  cluster_name       = aws_ecs_cluster.wp-cluster.name
  capacity_providers = [aws_ecs_capacity_provider.wp-capacity.name]
}

resource "aws_ecs_service" "wordpress_service" {
  name                              = "wordpress_service"
  cluster                           = aws_ecs_cluster.wp-cluster.id
  desired_count                     = 2
  enable_ecs_managed_tags           = true
  force_delete                      = true
  health_check_grace_period_seconds = 300
  scheduling_strategy               = "REPLICA"
  task_definition                   = "${aws_ecs_task_definition.wordpress.family}:${aws_ecs_task_definition.wordpress.revision}"
  capacity_provider_strategy {
    base              = 0
    capacity_provider = aws_ecs_capacity_provider.wp-capacity.name
    weight            = 1
  }
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }
  load_balancer {
    container_name   = "wordpress"
    container_port   = 443
    target_group_arn = aws_lb_target_group.tgWordpress.arn
  }
  network_configuration {
    assign_public_ip = false
    security_groups  = [aws_security_group.autoscaling_group_asgWordpress_group.id, aws_security_group.ecs_task_definition_wordpress_group.id]
    subnets          = [aws_subnet.appA.id, aws_subnet.appB.id]
  }
  ordered_placement_strategy {
    field = "attribute:ecs.availability-zone"
    type  = "spread"
  }
  tags = {
    Name           = "wordpress_service"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_lb_listener_rule.ruleFromCloudFront]
}

locals {
  container_def_wordpress_wordpress_1 = {
    name              = "wordpress"
    image             = "public.ecr.aws/docker/library/wordpress:7.1.2-php8.4-apache"
    essential         = true
    cpu               = 512
    memory            = 768
    memoryReservation = 512
    stopTimeout       = 30
    portMappings = [
      {
        protocol      = "tcp"
        containerPort = 443
        hostPort      = 443
      }
    ]
    environment = [
      {
        name  = "WORDPRESS_DB_HOST"
        value = tostring(aws_rds_cluster.wp-aurora.endpoint)
      },
      {
        name  = "WORDPRESS_DB_NAME"
        value = tostring(aws_rds_cluster.wp-aurora.database_name)
      },
      {
        name  = "WORDPRESS_DB_USER"
        value = "wordpress"
      },
      {
        name  = "WORDPRESS_CONFIG_EXTRA"
        value = "define('WP_HOME', 'https://wp.${data.aws_route53_zone.zoneWordpress.name}'); define('WP_SITEURL', 'https://wp.${data.aws_route53_zone.zoneWordpress.name}'); $_SERVER['HTTP_HOST'] = 'wp.${data.aws_route53_zone.zoneWordpress.name}'; define('FORCE_SSL_ADMIN', true); define('DISALLOW_FILE_EDIT', true); define('MYSQL_CLIENT_FLAGS', MYSQLI_CLIENT_SSL | MYSQLI_CLIENT_SSL_DONT_VERIFY_SERVER_CERT); define('WP_REDIS_HOST', '${aws_elasticache_replication_group.wpRedis.primary_endpoint_address}'); define('WP_REDIS_PORT', 6379); define('WP_REDIS_SCHEME', 'tls'); define('AS3CF_SETTINGS', serialize(array('provider' => 'aws', 'use-server-roles' => true, 'bucket' => '${aws_s3_bucket.wpMedia.bucket}', 'region' => '${data.aws_region.current.region}', 'copy-to-s3' => true, 'enable-object-prefix' => true, 'object-prefix' => 'wp-content/media/', 'use-yearmonth-folders' => true, 'object-versioning' => true, 'delivery-provider' => 'aws', 'serve-from-s3' => true, 'enable-delivery-domain' => true, 'delivery-domain' => 'wp.${data.aws_route53_zone.zoneWordpress.name}', 'force-https' => true, 'remove-local-file' => false)));"
      },
      {
        name  = "WP_DB_BOOTSTRAP"
        value = "<?php mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT); $q = chr(39); $b = chr(96); $user = getenv('WORDPRESS_DB_USER'); $m = null; for ($i = 1; $i <= 20 && $m === null; $i++) { try { $c = mysqli_init(); $c->real_connect(getenv('WORDPRESS_DB_HOST'), getenv('DB_ADMIN_USER'), getenv('DB_ADMIN_PASSWORD'), '', 3306, null, MYSQLI_CLIENT_SSL | MYSQLI_CLIENT_SSL_DONT_VERIFY_SERVER_CERT); $m = $c; } catch (mysqli_sql_exception $e) { fwrite(STDERR, 'db-bootstrap: attempt ' . $i . ': ' . $e->getMessage() . PHP_EOL); sleep(10); } } if ($m === null) { exit(1); } $account = $q . $m->real_escape_string($user) . $q . '@' . $q . '%' . $q; $password = $q . $m->real_escape_string(getenv('WORDPRESS_DB_PASSWORD')) . $q; $m->query('CREATE USER IF NOT EXISTS ' . $account . ' IDENTIFIED BY ' . $password . ' REQUIRE SSL'); $m->query('ALTER USER ' . $account . ' IDENTIFIED BY ' . $password . ' REQUIRE SSL'); $m->query('GRANT ALL PRIVILEGES ON ' . $b . str_replace($b, $b . $b, getenv('WORDPRESS_DB_NAME')) . $b . '.* TO ' . $account); echo 'db-bootstrap: database user ' . $user . ' is ready' . PHP_EOL;"
      },
      {
        name  = "NAME"
        value = "wordpress"
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
        name  = "AWS_ECS_CAPACITY_PROVIDER_NAME_0"
        value = "wp-capacity"
      },
      {
        name  = "AWS_EFS_FILE_SYSTEM_ID_0"
        value = tostring(aws_efs_file_system.wpContent.id)
      },
      {
        name  = "AWS_ELASTICACHE_REPLICATION_GROUP_ENDPOINT_0"
        value = tostring(aws_elasticache_replication_group.wpRedis.primary_endpoint_address)
      },
      {
        name  = "AWS_ELASTICACHE_REPLICATION_GROUP_READER_ENDPOINT_0"
        value = tostring(aws_elasticache_replication_group.wpRedis.reader_endpoint_address)
      },
      {
        name  = "AWS_RDS_CLUSTER_NAME_0"
        value = tostring(aws_rds_cluster.wp-aurora.cluster_identifier)
      },
      {
        name  = "AWS_RDS_CLUSTER_ENGINE_0"
        value = tostring(aws_rds_cluster.wp-aurora.engine)
      },
      {
        name  = "AWS_RDS_CLUSTER_ENDPOINT_0"
        value = tostring(aws_rds_cluster.wp-aurora.endpoint)
      },
      {
        name  = "AWS_RDS_CLUSTER_PORT_0"
        value = tostring(aws_rds_cluster.wp-aurora.port)
      },
      {
        name  = "AWS_RDS_CLUSTER_DB_NAME_0"
        value = tostring(aws_rds_cluster.wp-aurora.database_name)
      },
      {
        name  = "AWS_RDS_CLUSTER_SECRET_ARN_0"
        value = tostring(one(aws_rds_cluster.wp-aurora.master_user_secret[*].secret_arn))
      },
      {
        name  = "AWS_S3_BUCKET_NAME_0"
        value = "wp-pro-media-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.region}-an"
      }
    ]
    secrets = [
      {
        name      = "WORDPRESS_DB_PASSWORD"
        valueFrom = aws_secretsmanager_secret.wpSecrets.arn
      },
      {
        name      = "DB_ADMIN_USER"
        valueFrom = "${aws_rds_cluster.wp-aurora.master_user_secret[0].secret_arn}:username::"
      },
      {
        name      = "DB_ADMIN_PASSWORD"
        valueFrom = "${aws_rds_cluster.wp-aurora.master_user_secret[0].secret_arn}:password::"
      }
    ]
    mountPoints = [
      {
        sourceVolume  = "wpContent"
        containerPath = "/var/www/html"
        readOnly      = false
      }
    ]
    systemControls         = []
    volumesFrom            = []
    command                = ["sh", "-c", "set -e; mkdir -p /etc/ssl/private; openssl req -x509 -nodes -newkey rsa:2048 -days 3650 -subj /CN=wordpress -addext basicConstraints=critical,CA:FALSE -keyout /etc/ssl/private/ssl-cert-snakeoil.key -out /etc/ssl/certs/ssl-cert-snakeoil.pem; a2enmod ssl; a2ensite default-ssl; printenv WP_DB_BOOTSTRAP > /tmp/db-bootstrap.php; php /tmp/db-bootstrap.php; rm -f /tmp/db-bootstrap.php; unset WP_DB_BOOTSTRAP DB_ADMIN_USER DB_ADMIN_PASSWORD; exec docker-entrypoint.sh apache2-foreground"]
    privileged             = false
    readonlyRootFilesystem = false
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.logsWordpress.name
        awslogs-region        = "us-west-2"
        awslogs-stream-prefix = "wordpress"
      }
    }
  }
}

resource "aws_ecs_task_definition" "wordpress" {
  container_definitions    = jsonencode([local.container_def_wordpress_wordpress_1])
  cpu                      = "512"
  execution_role_arn       = aws_iam_role.execution_role_ecs_wordpress.arn
  family                   = "wordpress"
  memory                   = "768"
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  task_role_arn            = aws_iam_role.task_role_ecs_wordpress.arn
  tags = {
    Name           = "wordpress"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
  volume {
    name = "wpContent"
    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.wpContent.id
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.ap_wordpress_wpContent.id
        iam             = "ENABLED"
      }
    }
  }
  depends_on = [aws_iam_role_policy_attachment.ecs_task_definition_wordpress_st_wordpress-professional_attach, aws_iam_role_policy_attachment.ecs_task_definition_wordpress_execution_st_wordpress-professional_attach]
}




### CATEGORY: INTEGRATION ###

resource "aws_sns_topic" "alarmsWordpress" {
  name = "alarmsWordpress"
  tags = {
    Name           = "alarmsWordpress"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_sns_topic_subscription" "Subscription1" {
  endpoint  = "rbpmconsulting@gmail.com"
  protocol  = "email"
  topic_arn = aws_sns_topic.alarmsWordpress.arn
}




### CATEGORY: MONITORING ###

resource "aws_cloudwatch_log_group" "logsWordpress" {
  name              = "/ecs/wordpress"
  log_group_class   = "STANDARD"
  retention_in_days = 30
  skip_destroy      = false
  tags = {
    Name           = "logsWordpress"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_cloudwatch_metric_alarm" "alarmDbCapacity" {
  alarm_name          = "alarmDbCapacity"
  metric_name         = "ServerlessDatabaseCapacity"
  alarm_actions       = [aws_sns_topic.alarmsWordpress.arn]
  alarm_description   = "Aurora has run at its maximum capacity (2 ACUs) for 15 minutes. If this repeats, raise the maximum capacity of the wp-aurora cluster and this threshold with it."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  datapoints_to_alarm = 3
  evaluation_periods  = 3
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 2
  treat_missing_data  = "notBreaching"
  dimensions = {
    DBClusterIdentifier = aws_rds_cluster.wp-aurora.cluster_identifier
  }
  tags = {
    Name           = "alarmDbCapacity"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_cloudwatch_metric_alarm" "alarmSite5xx" {
  alarm_name          = "alarmSite5xx"
  metric_name         = "HTTPCode_ELB_5XX_Count"
  alarm_actions       = [aws_sns_topic.alarmsWordpress.arn]
  alarm_description   = "The load balancer itself answered 5xx (502, 503 or 504) at least 10 times in 5 minutes: no healthy WordPress task, or tasks not answering."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  datapoints_to_alarm = 1
  evaluation_periods  = 1
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  treat_missing_data  = "notBreaching"
  dimensions = {
    LoadBalancer = aws_lb.alb-wp.arn_suffix
  }
  tags = {
    Name           = "alarmSite5xx"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_cloudwatch_metric_alarm" "alarmTasksCpu" {
  alarm_name          = "alarmTasksCpu"
  metric_name         = "CPUUtilization"
  alarm_actions       = [aws_sns_topic.alarmsWordpress.arn]
  alarm_description   = "Average CPU of the WordPress service above 80% for 15 minutes."
  comparison_operator = "GreaterThanThreshold"
  datapoints_to_alarm = 3
  evaluation_periods  = 3
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  dimensions = {
    ClusterName = aws_ecs_cluster.wp-cluster.name
    ServiceName = aws_ecs_service.wordpress_service.name
  }
  tags = {
    Name           = "alarmTasksCpu"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_cloudwatch_metric_alarm" "alarmTasksMemory" {
  alarm_name          = "alarmTasksMemory"
  metric_name         = "MemoryUtilization"
  alarm_actions       = [aws_sns_topic.alarmsWordpress.arn]
  alarm_description   = "Average memory of the WordPress service above 85% of the task memory for 15 minutes."
  comparison_operator = "GreaterThanThreshold"
  datapoints_to_alarm = 3
  evaluation_periods  = 3
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 85
  dimensions = {
    ClusterName = aws_ecs_cluster.wp-cluster.name
    ServiceName = aws_ecs_service.wordpress_service.name
  }
  tags = {
    Name           = "alarmTasksMemory"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
}




### CATEGORY: MISC ###

resource "null_resource" "cleanup_wp-cluster" {
  triggers = {
    cluster_name = aws_ecs_cluster.wp-cluster.name
  }
  depends_on = [aws_ecs_cluster.wp-cluster, aws_autoscaling_group.asgWordpress, aws_ecs_capacity_provider.wp-capacity]
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
        ASGS="asgWordpress"
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

resource "random_id" "originVerify" {
  byte_length = 8
}

resource "random_password" "wpDbPassword" {
  length  = 16
  special = true
}


