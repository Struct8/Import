terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
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
    sid       = "AllowWriteLogs"
    effect    = "Allow"
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.logsWordpress.arn}:*"]
  }
  statement {
    sid       = "AllowEFSBasicAccess"
    effect    = "Allow"
    actions   = ["elasticfilesystem:ClientMount", "elasticfilesystem:ClientRootAccess", "elasticfilesystem:ClientWrite"]
    resources = ["${aws_efs_file_system.wpContent.arn}:*"]
  }
  statement {
    sid       = "AllowKMSAccess"
    effect    = "Allow"
    actions   = ["kms:Decrypt", "kms:DescribeKey", "kms:Encrypt", "kms:GenerateDataKey"]
    resources = [aws_kms_key.kmsWordpress.arn]
  }
  statement {
    sid       = "AllowRDSSecretAccesswpAurora"
    effect    = "Allow"
    actions   = ["secretsmanager:DescribeSecret", "secretsmanager:GetSecretValue"]
    resources = [aws_rds_cluster.wpAurora.master_user_secret[0].secret_arn]
  }
  statement {
    sid       = "AllowSecretAccess"
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [aws_secretsmanager_secret.wpSecrets.arn]
  }
}

resource "aws_iam_policy" "autoscaling_group_asgWordpress_st_wordpress-professional" {
  name        = "autoscaling_group_asgWordpress_st_wordpress-professional"
  description = "Access Policy for asgWordpress"
  policy      = data.aws_iam_policy_document.autoscaling_group_asgWordpress_st_wordpress-professional_doc.json
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

resource "aws_iam_role_policy_attachment" "autoscaling_group_asgWordpress_st_wordpress-professional_attach" {
  policy_arn = aws_iam_policy.autoscaling_group_asgWordpress_st_wordpress-professional.arn
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
  description             = "WordPress authentication keys and salts. Database credentials are not stored here - Aurora writes those to its own managed secret."
  recovery_window_in_days = 0
  tags = {
    Name           = "wpSecrets"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_secretsmanager_secret_version" "wpSecrets_version" {
  secret_id      = aws_secretsmanager_secret.wpSecrets.id
  secret_string  = " "
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
  route_table_ids   = [aws_route_table.rt-public-wp.id]
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

resource "aws_vpc_endpoint" "vpceLogs_EC2" {
  service_name        = "com.amazonaws.${data.aws_region.current.region}.ec2"
  vpc_id              = aws_vpc.wordpress-professional.id
  ip_address_type     = "ipv4"
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.sg_vpce_vpceLogs.id]
  subnet_ids          = [aws_subnet.appA.id]
  vpc_endpoint_type   = "Interface"
  tags = {
    Name           = "vpceLogs"
    DifName        = "vpceLogs_EC2"
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
  subnet_ids          = [aws_subnet.appA.id]
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

resource "aws_route_table_association" "aws_route_table_association_dataA_rtPrivate" {
  route_table_id = aws_route_table.rtPrivate.id
  subnet_id      = aws_subnet.dataA.id
}

resource "aws_route_table_association" "aws_route_table_association_dataB_rtPrivate" {
  route_table_id = aws_route_table.rtPrivate.id
  subnet_id      = aws_subnet.dataB.id
}

resource "aws_route_table_association" "aws_route_table_association_pubA_rt_public_wp" {
  route_table_id = aws_route_table.rt-public-wp.id
  subnet_id      = aws_subnet.pubA.id
}

resource "aws_route_table_association" "aws_route_table_association_pubB_rt_public_wp" {
  route_table_id = aws_route_table.rt-public-wp.id
  subnet_id      = aws_subnet.pubB.id
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

resource "aws_security_group" "rds_cluster_wpAurora_group" {
  name                   = "rds_cluster_wpAurora_group"
  vpc_id                 = aws_vpc.wordpress-professional.id
  revoke_rules_on_delete = false
  tags = {
    Name           = "rds_cluster_wpAurora_group"
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

resource "aws_security_group_rule" "rule_autoscaling_group_asgWordpress_group_egress_all_protocols" {
  security_group_id = aws_security_group.autoscaling_group_asgWordpress_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "rule_autoscaling_group_asgWordpress_group_to_efs_file_system_wpContent_group_tcp_2049" {
  security_group_id        = aws_security_group.efs_file_system_wpContent_group.id
  source_security_group_id = aws_security_group.autoscaling_group_asgWordpress_group.id
  description              = "NFS from the WordPress instances to EFS"
  from_port                = 2049
  protocol                 = "tcp"
  to_port                  = 2049
  type                     = "ingress"
}

resource "aws_security_group_rule" "rule_autoscaling_group_asgWordpress_group_to_elasticache_replication_group_wpRedis_group_tcp_6379" {
  security_group_id        = aws_security_group.elasticache_replication_group_wpRedis_group.id
  source_security_group_id = aws_security_group.autoscaling_group_asgWordpress_group.id
  description              = "Redis from the WordPress instances"
  from_port                = 6379
  protocol                 = "tcp"
  to_port                  = 6379
  type                     = "ingress"
}

resource "aws_security_group_rule" "rule_autoscaling_group_asgWordpress_group_to_rds_cluster_wpAurora_group_tcp_3306" {
  security_group_id        = aws_security_group.rds_cluster_wpAurora_group.id
  source_security_group_id = aws_security_group.autoscaling_group_asgWordpress_group.id
  description              = "MySQL from the WordPress instances"
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

resource "aws_security_group_rule" "rule_lb_alb_wp_group_ingress_tcp_443" {
  security_group_id = aws_security_group.lb_alb-wp_group.id
  description       = "HTTPS from CloudFront edge locations only"
  from_port         = 443
  prefix_list_ids   = ["pl-82a045eb"]
  protocol          = "tcp"
  to_port           = 443
  type              = "ingress"
}

resource "aws_security_group_rule" "rule_lb_alb_wp_group_to_autoscaling_group_asgWordpress_group_tcp_443" {
  security_group_id        = aws_security_group.autoscaling_group_asgWordpress_group.id
  source_security_group_id = aws_security_group.lb_alb-wp_group.id
  description              = "HTTPS from the load balancer to the WordPress instances"
  from_port                = 443
  protocol                 = "tcp"
  to_port                  = 443
  type                     = "ingress"
}

resource "aws_security_group_rule" "rule_rds_cluster_wpAurora_group_egress_all_protocols" {
  security_group_id = aws_security_group.rds_cluster_wpAurora_group.id
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
  security_groups                  = [aws_security_group.lb_alb-wp_group.id]
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
  certificate_arn                      = aws_acm_certificate.certAlb.arn
  load_balancer_arn                    = aws_lb.alb-wp.arn
  port                                 = 443
  protocol                             = "HTTPS"
  routing_http_response_server_enabled = true
  ssl_policy                           = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  default_action {
    order            = 1
    target_group_arn = aws_lb_target_group.tgWordpress.arn
    type             = "forward"
    forward {
      target_group {
        arn = aws_lb_target_group.tgWordpress.arn
      }
    }
  }
  tags = {
    Name           = "listenerHttps"
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
  target_type                   = "instance"
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
    target_origin_id           = "originAlb"
    allowed_methods            = ["GET", "HEAD", "OPTIONS"]
    cached_methods             = ["GET", "HEAD", "OPTIONS"]
    path_pattern               = "/wp-content/*"
    viewer_protocol_policy     = "redirect-to-https"
  }
  origin {
    domain_name = "origin.wp.${data.aws_route53_zone.zoneWordpress.name}"
    origin_id   = "originAlb"
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
    acm_certificate_arn            = aws_acm_certificate.certWordpress.arn
    cloudfront_default_certificate = false
    minimum_protocol_version       = "TLSv1.2_2021"
    ssl_support_method             = "sni-only"
  }
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

resource "aws_s3_bucket_ownership_controls" "albLogs_controls" {
  bucket = aws_s3_bucket.albLogs.id
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

resource "aws_s3_bucket_public_access_block" "albLogs_block" {
  block_public_acls       = true
  block_public_policy     = true
  bucket                  = aws_s3_bucket.albLogs.id
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "albLogs_configuration" {
  bucket = aws_s3_bucket.albLogs.id
  rule {
    bucket_key_enabled = true
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.kmsWordpress.arn
      sse_algorithm     = "aws:kms"
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

resource "aws_efs_access_point" "ap_asgWordpress_wpContent" {
  file_system_id = aws_efs_file_system.wpContent.id
  posix_user {
    gid = "48"
    uid = "48"
  }
  root_directory {
    path = "/wp-content-uploads"
    creation_info {
      owner_gid   = "48"
      owner_uid   = "48"
      permissions = "0755"
    }
  }
  tags = {
    Name           = "ap_asgWordpress_wpContent"
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

resource "aws_db_subnet_group" "subnet_group_wpAurora" {
  name       = "wpaurora-subnet-group"
  subnet_ids = [aws_subnet.dataA.id, aws_subnet.dataB.id]
  tags = {
    Name           = "subnet_group_wpAurora"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_rds_cluster" "wpAurora" {
  database_name               = "wordpress"
  db_subnet_group_name        = aws_db_subnet_group.subnet_group_wpAurora.name
  kms_key_id                  = aws_kms_key.kmsWordpress.arn
  apply_immediately           = true
  backup_retention_period     = 7
  cluster_identifier          = "wpAurora"
  copy_tags_to_snapshot       = true
  database_insights_mode      = "standard"
  engine                      = "aurora-mysql"
  engine_version              = "8.0.mysql_aurora.3.13.0"
  manage_master_user_password = true
  master_username             = "dbadmin"
  monitoring_interval         = 0
  network_type                = "IPV4"
  port                        = 3306
  skip_final_snapshot         = true
  storage_encrypted           = true
  vpc_security_group_ids      = [aws_security_group.rds_cluster_wpAurora_group.id]
  serverlessv2_scaling_configuration {
    max_capacity             = 2
    min_capacity             = 0
    seconds_until_auto_pause = 300
  }
  tags = {
    Name           = "wpAurora"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_rds_cluster_instance" "wpAuroraReader" {
  cluster_identifier                    = aws_rds_cluster.wpAurora.id
  copy_tags_to_snapshot                 = true
  engine                                = aws_rds_cluster.wpAurora.engine
  identifier                            = "wpAuroraReader"
  instance_class                        = "db.serverless"
  performance_insights_retention_period = 7
  promotion_tier                        = 2
  tags = {
    Name           = "wpAuroraReader"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_rds_cluster_instance" "wpAuroraWriter" {
  cluster_identifier                    = aws_rds_cluster.wpAurora.id
  copy_tags_to_snapshot                 = true
  engine                                = aws_rds_cluster.wpAurora.engine
  identifier                            = "wpAuroraWriter"
  instance_class                        = "db.serverless"
  performance_insights_retention_period = 7
  promotion_tier                        = 1
  tags = {
    Name           = "wpAuroraWriter"
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
    values = ["al2023-ami-2023.*-kernel-6.1-arm64"]
  }
  filter {
    name   = "architecture"
    values = ["arm64"]
  }
}

resource "aws_launch_template" "ltWordpress" {
  image_id               = data.aws_ami.AMI_Data_Source_ltWordpress.id
  name                   = "ltWordpress"
  instance_type          = "t4g.micro"
  update_default_version = true
  user_data = base64encode(<<-EOFUData
#!/bin/bash

# --- BEGIN STRUCT8 VARIABLES ---
cat << 'EOFENV' > /etc/struct8_env
NAME="asgWordpress"
REGION="${data.aws_region.current.region}"
ACCOUNT="${data.aws_caller_identity.current.account_id}"
AWS_ELASTICACHE_REPLICATION_GROUP_ENDPOINT_0="${aws_elasticache_replication_group.wpRedis.primary_endpoint_address}"
AWS_ELASTICACHE_REPLICATION_GROUP_READER_ENDPOINT_0="${aws_elasticache_replication_group.wpRedis.reader_endpoint_address}"
AWS_EFS_FILE_SYSTEM_ID_0="${aws_efs_file_system.wpContent.id}"
AWS_SECRETSMANAGER_SECRET_NAME_0="wpSecrets"
AWS_KMS_KEY_NAME_0="kmsWordpress"
AWS_RDS_CLUSTER_NAME_0="${aws_rds_cluster.wpAurora.cluster_identifier}"
AWS_RDS_CLUSTER_ENGINE_0="${aws_rds_cluster.wpAurora.engine}"
AWS_RDS_CLUSTER_ENDPOINT_0="${aws_rds_cluster.wpAurora.endpoint}"
AWS_RDS_CLUSTER_PORT_0="${aws_rds_cluster.wpAurora.port}"
AWS_RDS_CLUSTER_DB_NAME_0="${aws_rds_cluster.wpAurora.database_name}"
AWS_RDS_CLUSTER_SECRET_ARN_0="${one(aws_rds_cluster.wpAurora.master_user_secret[*].secret_arn)}"
EOFENV
cat /etc/struct8_env >> /etc/environment
sed 's/^/export /' /etc/struct8_env > /etc/profile.d/struct8_vars.sh
chmod +x /etc/profile.d/struct8_vars.sh
chmod 644 /etc/struct8_env
# --- END STRUCT8 VARIABLES ---

# --- BEGIN STRUCT8 EFS ---
command -v mount.efs >/dev/null 2>&1 || yum install -y amazon-efs-utils >/dev/null 2>&1 || dnf install -y amazon-efs-utils >/dev/null 2>&1 || apt-get install -y amazon-efs-utils >/dev/null 2>&1 || true
mkdir -p /mnt/efs
mount -t efs -o tls,accesspoint=${aws_efs_access_point.ap_asgWordpress_wpContent.id} ${aws_efs_access_point.ap_asgWordpress_wpContent.file_system_id}:/ /mnt/efs
grep -q " /mnt/efs efs " /etc/fstab || echo "${aws_efs_access_point.ap_asgWordpress_wpContent.file_system_id}:/ /mnt/efs efs _netdev,tls,accesspoint=${aws_efs_access_point.ap_asgWordpress_wpContent.id} 0 0" >> /etc/fstab
# --- END STRUCT8 EFS ---


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
      volume_size           = 20
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
    Name           = "asgWordpress"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
  }
  tags = {
    Name           = "ltWordpress"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_autoscaling_group" "asgWordpress" {
  name                      = "asgWordpress"
  default_instance_warmup   = 0
  desired_capacity          = 2
  health_check_grace_period = 600
  health_check_type         = "ELB"
  max_instance_lifetime     = 0
  max_size                  = 6
  metrics_granularity       = "1Minute"
  min_elb_capacity          = 0
  min_size                  = 2
  target_group_arns         = [aws_lb_target_group.tgWordpress.arn]
  termination_policies      = ["Default"]
  vpc_zone_identifier       = [aws_subnet.appA.id, aws_subnet.appB.id]
  wait_for_elb_capacity     = 0
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




### CATEGORY: INTEGRATION ###

resource "aws_sns_topic" "alarmsWordpress" {
  name = "alarmsWordpress"
  tags = {
    Name           = "alarmsWordpress"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
}




### CATEGORY: MONITORING ###

resource "aws_cloudwatch_log_group" "logsWordpress" {
  name              = "/aws/autoscaling/asgWordpress"
  log_group_class   = "STANDARD"
  retention_in_days = 30
  skip_destroy      = false
  tags = {
    Name           = "logsWordpress"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
}


