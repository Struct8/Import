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

data "aws_ec2_managed_prefix_list" "cloudfront_origin_facing_ipv6" {
  name = "com.amazonaws.global.ipv6.cloudfront.origin-facing"
}




### EXTERNAL REFERENCES ###

data "aws_kms_key" "kmsWordpress" {
  key_id = "alias/kmsWordpress-xnA-aVKz"
}

data "aws_secretsmanager_secret" "wpSecrets" {
  name = "wpSecrets"
}

data "aws_ssm_parameter" "wpAdminPassword" {
  name            = "wpAdminPassword"
  with_decryption = false
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

resource "aws_iam_instance_profile" "nat-instance_profile" {
  name = "nat-instance_profile"
  role = aws_iam_role.nat-instance_role.name
  tags = {
    Name           = "nat-instance_profile"
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
    resources = [data.aws_kms_key.kmsWordpress.arn]
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
    resources = [data.aws_secretsmanager_secret.wpSecrets.arn]
  }
  statement {
    sid       = "AllowReadParam"
    effect    = "Allow"
    actions   = ["ssm:GetParameter", "ssm:GetParameters"]
    resources = [data.aws_ssm_parameter.wpAdminPassword.arn]
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
  statement {
    sid       = "AllowSesSendFromIdentity"
    effect    = "Allow"
    actions   = ["ses:SendEmail", "ses:SendRawEmail"]
    resources = [aws_sesv2_email_identity.wpMail.arn]
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
  force_detach_policies = false
  max_session_duration  = 3600
  path                  = "/"
  tags = {
    Name           = "execution_role_ecs_wordpress"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "nat-instance_role" {
  name = "nat-instance_role"
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
    Name           = "nat-instance_role"
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
  force_detach_policies = false
  max_session_duration  = 3600
  path                  = "/"
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
  assign_generated_ipv6_cidr_block = true
  cidr_block                       = "10.0.0.0/16"
  enable_dns_hostnames             = true
  enable_dns_support               = true
  instance_tenancy                 = "default"
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

resource "aws_subnet" "appA" {
  vpc_id                          = aws_vpc.wordpress-professional.id
  assign_ipv6_address_on_creation = true
  availability_zone               = "us-west-2a"
  cidr_block                      = "10.0.11.0/24"
  ipv6_cidr_block                 = cidrsubnet(aws_vpc.wordpress-professional.ipv6_cidr_block, 8, 11)
  map_public_ip_on_launch         = false
  tags = {
    Name           = "appA"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "appB" {
  vpc_id                          = aws_vpc.wordpress-professional.id
  assign_ipv6_address_on_creation = true
  availability_zone               = "us-west-2b"
  cidr_block                      = "10.0.12.0/24"
  ipv6_cidr_block                 = cidrsubnet(aws_vpc.wordpress-professional.ipv6_cidr_block, 8, 12)
  map_public_ip_on_launch         = false
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
  ipv6_cidr_block         = cidrsubnet(aws_vpc.wordpress-professional.ipv6_cidr_block, 8, 1)
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
  ipv6_cidr_block         = cidrsubnet(aws_vpc.wordpress-professional.ipv6_cidr_block, 8, 2)
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

resource "aws_egress_only_internet_gateway" "eigw-wp" {
  vpc_id = aws_vpc.wordpress-professional.id
  tags = {
    Name           = "eigw-wp"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route" "route_rt-public-wp_to_igw-wp_ipv4" {
  gateway_id             = aws_internet_gateway.igw-wp.id
  route_table_id         = aws_route_table.rt-public-wp.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route" "route_rt-public-wp_to_igw-wp_ipv6" {
  gateway_id                  = aws_internet_gateway.igw-wp.id
  route_table_id              = aws_route_table.rt-public-wp.id
  destination_ipv6_cidr_block = "::/0"
}

resource "aws_route" "route_rtPrivate_to_eigw-wp_ipv6" {
  egress_only_gateway_id      = aws_egress_only_internet_gateway.eigw-wp.id
  route_table_id              = aws_route_table.rtPrivate.id
  destination_ipv6_cidr_block = "::/0"
}

resource "aws_route" "route_rtPrivate_to_nat-instance_ipv4" {
  network_interface_id   = aws_instance.nat-instance.primary_network_interface_id
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

resource "aws_route53_record" "alias_aaaa_aws_lb_alb-wp_origin_wp_cloudman_pro" {
  name    = "origin.wp.cloudman.pro"
  zone_id = data.aws_route53_zone.zoneWordpress.zone_id
  type    = "AAAA"
  alias {
    name                   = aws_lb.alb-wp.dns_name
    zone_id                = aws_lb.alb-wp.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "dkim_wpMail_wp_cloudman_pro" {
  for_each = {
    for i in range(3) : tostring(i) => {
      name  = "${aws_sesv2_email_identity.wpMail.dkim_signing_attributes[0].tokens[i]}._domainkey.wp.cloudman.pro."
      value = "${aws_sesv2_email_identity.wpMail.dkim_signing_attributes[0].tokens[i]}.dkim.amazonses.com."
    }
  }
  name            = each.value.name
  zone_id         = data.aws_route53_zone.zoneWordpress.zone_id
  allow_overwrite = true
  records         = [each.value.value]
  ttl             = 300
  type            = "CNAME"
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

resource "aws_security_group" "instance_nat-instance_group" {
  name                   = "instance_nat-instance_group"
  vpc_id                 = aws_vpc.wordpress-professional.id
  revoke_rules_on_delete = false
  tags = {
    Name           = "instance_nat-instance_group"
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

resource "aws_security_group_rule" "rule_alb_cloudfront_wp_cloudfront_ipv6_tcp_443" {
  security_group_id = aws_security_group.alb-cloudfront-wp.id
  description       = "HTTPS from CloudFront over IPv6"
  from_port         = 443
  prefix_list_ids   = [data.aws_ec2_managed_prefix_list.cloudfront_origin_facing_ipv6.id]
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
  ipv6_cidr_blocks  = ["::/0"]
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "rule_ecs_task_definition_wordpress_group_egress_all_protocols" {
  security_group_id = aws_security_group.ecs_task_definition_wordpress_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  ipv6_cidr_blocks  = ["::/0"]
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

resource "aws_security_group_rule" "rule_instance_nat_instance_group_egress_all_protocols" {
  security_group_id = aws_security_group.instance_nat-instance_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "rule_instance_nat_instance_group_ingress_all_protocols" {
  security_group_id = aws_security_group.instance_nat-instance_group.id
  cidr_blocks       = ["10.0.11.0/24", "10.0.12.0/24"]
  description       = "NAT: all traffic from the private app subnets to be routed out"
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "ingress"
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

resource "aws_lb" "alb-wp" {
  name                             = "albWordpress"
  drop_invalid_header_fields       = true
  enable_cross_zone_load_balancing = true
  enable_http2                     = true
  idle_timeout                     = 60
  ip_address_type                  = "dualstack-without-public-ipv4"
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
    domain_name = "origin.wp.cloudman.pro"
    origin_id   = "originAlb"
    custom_header {
      name  = "X-Origin-Verify"
      value = random_id.originVerify.hex
    }
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      ip_address_type        = "ipv6"
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
  force_destroy       = true
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
  force_destroy       = true
  object_lock_enabled = false
  tags = {
    "Struct8:Backup:wpDailyBackup-uZbC08JN" = true
    Name                                    = "wpMedia"
    State                                   = "wordpress-professional"
    Struct8Creator                          = "Contato Struct"
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
    status     = "Enabled"
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
    "Struct8:Backup:wpDailyBackup-uZbC08JN" = true
    Name                                    = "wpContent"
    State                                   = "wordpress-professional"
    Struct8Creator                          = "Contato Struct"
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
  kms_key_id                  = data.aws_kms_key.kmsWordpress.arn
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
    "Struct8:Backup:wpDailyBackup-uZbC08JN" = true
    Name                                    = "wp-aurora"
    State                                   = "wordpress-professional"
    Struct8Creator                          = "Contato Struct"
  }
}

resource "aws_rds_cluster_instance" "wp-aurora-writer" {
  cluster_identifier    = aws_rds_cluster.wp-aurora.id
  copy_tags_to_snapshot = true
  engine                = aws_rds_cluster.wp-aurora.engine
  identifier            = "wp-aurora-writer"
  instance_class        = "db.serverless"
  promotion_tier        = 1
  tags = {
    Name           = "wp-aurora-writer"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_elasticache_replication_group" "wpRedis" {
  kms_key_id                 = data.aws_kms_key.kmsWordpress.arn
  replication_group_id       = "wp-object-cache"
  subnet_group_name          = aws_elasticache_subnet_group.subnet_group_wpRedis.name
  at_rest_encryption_enabled = true
  automatic_failover_enabled = true
  cluster_mode               = "disabled"
  description                = "WordPress object cache for wp_options, postmeta and transients."
  engine_version             = "7.1"
  node_type                  = "cache.t4g.micro"
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

resource "aws_elasticache_subnet_group" "subnet_group_wpRedis" {
  name       = "wpredis-subnet-group"
  subnet_ids = [aws_subnet.dataA.id, aws_subnet.dataB.id]
  tags = {
    Name           = "subnet_group_wpRedis"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
}




### CATEGORY: COMPUTE ###

data "local_file" "UserData_nat-instance" {
  filename = "${path.module}/.external_modules/struct8-templates/templates/ec2-nat-private/v1/user_data/Nat.sh"
}

data "aws_ami" "AMI_Data_Source_nat-instance" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-kernel-6.1-arm64"]
  }
}

resource "aws_instance" "nat-instance" {
  subnet_id                   = aws_subnet.pubA.id
  ami                         = data.aws_ami.AMI_Data_Source_nat-instance.id
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.nat-instance_profile.name
  instance_type               = "t4g.nano"
  source_dest_check           = false
  user_data_base64 = base64encode(<<-EOFUData
#!/bin/bash

${data.local_file.UserData_nat-instance.content}
EOFUData
)
  vpc_security_group_ids = [aws_security_group.instance_nat-instance_group.id]
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
    Name           = "nat-instance"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
}

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
  desired_capacity        = 1
  enabled_metrics         = ["GroupDesiredCapacity", "GroupInServiceInstances", "GroupMaxSize", "GroupMinSize", "GroupPendingInstances", "GroupStandbyInstances", "GroupTerminatingInstances", "GroupTotalInstances"]
  health_check_type       = "EC2"
  max_instance_lifetime   = 0
  max_size                = 6
  metrics_granularity     = "1Minute"
  min_elb_capacity        = 0
  min_size                = 1
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

resource "aws_appautoscaling_policy" "scalingWordpress-cpu" {
  name               = "scalingWordpress-cpu"
  resource_id        = aws_appautoscaling_target.scalingWordpress.resource_id
  policy_type        = "TargetTrackingScaling"
  scalable_dimension = aws_appautoscaling_target.scalingWordpress.scalable_dimension
  service_namespace  = aws_appautoscaling_target.scalingWordpress.service_namespace
  target_tracking_scaling_policy_configuration {
    disable_scale_in   = false
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
    target_value       = 60
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}

resource "aws_appautoscaling_target" "scalingWordpress" {
  resource_id        = "service/${aws_ecs_cluster.wp-cluster.name}/${aws_ecs_service.wordpress_service.name}"
  max_capacity       = 12
  min_capacity       = 2
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
  tags = {
    Name           = "scalingWordpress"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
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
  health_check_grace_period_seconds = 600
  propagate_tags                    = "TASK_DEFINITION"
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
  lifecycle {
    ignore_changes = [desired_count]
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
    image             = "public.ecr.aws/docker/library/wordpress:latest"
    essential         = true
    cpu               = 512
    memory            = 640
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
        value = "define('WP_HOME', 'https://wp.${data.aws_route53_zone.zoneWordpress.name}'); define('WP_SITEURL', 'https://wp.${data.aws_route53_zone.zoneWordpress.name}'); $_SERVER['HTTP_HOST'] = 'wp.${data.aws_route53_zone.zoneWordpress.name}'; define('FORCE_SSL_ADMIN', true); define('DISALLOW_FILE_EDIT', true); define('MYSQL_CLIENT_FLAGS', MYSQLI_CLIENT_SSL | MYSQLI_CLIENT_SSL_DONT_VERIFY_SERVER_CERT); define('WP_REDIS_HOST', '${aws_elasticache_replication_group.wpRedis.primary_endpoint_address}'); define('WP_REDIS_PORT', 6379); define('WP_REDIS_SCHEME', 'tls'); define('AS3CF_SETTINGS', serialize(array('provider' => 'aws', 'use-server-roles' => true, 'bucket' => '${aws_s3_bucket.wpMedia.bucket}', 'region' => '${data.aws_region.current.region}', 'copy-to-s3' => true, 'enable-object-prefix' => true, 'object-prefix' => 'wp-content/media/', 'use-yearmonth-folders' => true, 'object-versioning' => true, 'delivery-provider' => 'aws', 'serve-from-s3' => true, 'enable-delivery-domain' => true, 'delivery-domain' => 'wp.${data.aws_route53_zone.zoneWordpress.name}', 'force-https' => true, 'remove-local-file' => false))); define('WPOSES_AWS_USE_EC2_IAM_ROLE', true); define('WPOSES_SETTINGS', serialize(array('region' => '${data.aws_region.current.region}', 'send-via-ses' => true, 'completed-setup' => true, 'enable-open-tracking' => false, 'enable-click-tracking' => false, 'enable-health-report' => false, 'log-duration' => 30)));"
      },
      {
        name  = "WP_DB_BOOTSTRAP"
        value = "<?php mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT); $q = chr(39); $b = chr(96); $user = getenv('WORDPRESS_DB_USER'); $m = null; for ($i = 1; $i <= 20 && $m === null; $i++) { try { $c = mysqli_init(); $c->real_connect(getenv('WORDPRESS_DB_HOST'), getenv('DB_ADMIN_USER'), getenv('DB_ADMIN_PASSWORD'), '', 3306, null, MYSQLI_CLIENT_SSL | MYSQLI_CLIENT_SSL_DONT_VERIFY_SERVER_CERT); $m = $c; } catch (mysqli_sql_exception $e) { fwrite(STDERR, 'db-bootstrap: attempt ' . $i . ': ' . $e->getMessage() . PHP_EOL); sleep(10); } } if ($m === null) { exit(1); } $account = $q . $m->real_escape_string($user) . $q . '@' . $q . '%' . $q; $password = $q . $m->real_escape_string(getenv('WORDPRESS_DB_PASSWORD')) . $q; $m->query('CREATE USER IF NOT EXISTS ' . $account . ' IDENTIFIED BY ' . $password . ' REQUIRE SSL'); $m->query('ALTER USER ' . $account . ' IDENTIFIED BY ' . $password . ' REQUIRE SSL'); $m->query('GRANT ALL PRIVILEGES ON ' . $b . str_replace($b, $b . $b, getenv('WORDPRESS_DB_NAME')) . $b . '.* TO ' . $account); echo 'db-bootstrap: database user ' . $user . ' is ready' . PHP_EOL;"
      },
      {
        name  = "WP_AUTO_SETUP"
        value = "true"
      },
      {
        name  = "WP_DEMO_CONTENT"
        value = "true"
      },
      {
        name  = "WP_SITE_URL"
        value = "https://wp.${data.aws_route53_zone.zoneWordpress.name}"
      },
      {
        name  = "WP_SITE_TITLE"
        value = "My WordPress site"
      },
      {
        name  = "WP_ADMIN_USER"
        value = "wpadmin"
      },
      {
        name  = "WP_ADMIN_EMAIL"
        value = "admin@${data.aws_route53_zone.zoneWordpress.name}"
      },
      {
        name  = "WP_LOCALE"
        value = "en_US"
      },
      {
        name  = "WP_TIMEZONE"
        value = "UTC"
      },
      {
        name = "WP_AUTO_SETUP_SCRIPT"
        value = <<EOF
#!/bin/bash
# First start of the WordPress Professional template.
#
# The task runs this on every start, before Apache, and it works once per site:
# it installs WordPress, the language, the plugins this template configures in
# WORDPRESS_CONFIG_EXTRA (Redis Object Cache, WP Offload Media Lite and WP Offload
# SES Lite), Two Factor, a must-use plugin with the site's hardening and, with
# WP_DEMO_CONTENT=true, a sample site with photos and a contact form whose
# messages are also kept in the administration panel. A marker on the EFS volume
# ends every later start in under a second.
#
# WP_AUTO_SETUP=false turns it off, and the site starts on the WordPress
# installation screen. A site somebody installed before this ran is left alone.

log() { echo "wp-setup: $*"; }

case "$WP_AUTO_SETUP" in
  false|False|FALSE|0|no|off) log "WP_AUTO_SETUP is off: nothing to do"; exit 0 ;;
esac

SITE=/var/www/html
DONE=$SITE/.struct8-setup-done
STARTED=$SITE/.struct8-setup-started
LOCK=$SITE/.struct8-setup-lock
WPCLI=/tmp/wp-cli.phar

if [ -e "$DONE" ]; then log "site already set up"; exit 0; fi

# Two tasks start together on a new site and share the volume. mkdir is atomic
# there, so one of them installs and the other waits for the marker.
waited=0
until mkdir "$LOCK" 2>/dev/null; do
  if [ -e "$DONE" ]; then log "set up by another task"; exit 0; fi
  if [ "$waited" -ge 480 ]; then
    log "the setup lock is 8 minutes old: taking it over"
    rmdir "$LOCK" 2>/dev/null
    waited=0
  else
    sleep 5
    waited=$((waited + 5))
  fi
done
trap 'rmdir "$LOCK" 2>/dev/null' EXIT
if [ -e "$DONE" ]; then log "set up by another task"; exit 0; fi

cd "$SITE" || exit 1
if ! command -v docker-ensure-installed.sh >/dev/null 2>&1; then
  log "this image has no docker-ensure-installed.sh: finish the installation at /wp-admin/install.php"
  exit 0
fi
# Copies WordPress to the volume and writes wp-config.php from the WORDPRESS_*
# variables without starting Apache, so the installation screen is never served.
docker-ensure-installed.sh true || exit 1

retry() {
  n=1
  until "$@"; do
    if [ "$n" -ge 12 ]; then return 1; fi
    log "attempt $n of 12 failed: trying again in 10 seconds"
    n=$((n + 1))
    sleep 10
  done
}

retry curl -fsSL -o "$WPCLI" https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar || { log "could not download WP-CLI"; exit 1; }
wp() { php "$WPCLI" --allow-root --path="$SITE" "$@"; }

if wp core is-installed >/dev/null 2>&1; then
  if [ ! -e "$STARTED" ]; then
    log "WordPress was installed before this setup ran: leaving the site as it is"
    touch "$DONE"
    exit 0
  fi
else
  if [ -z "$WP_ADMIN_PASSWORD" ]; then log "WP_ADMIN_PASSWORD is empty"; exit 1; fi
  touch "$STARTED"
  wp core install --url="$WP_SITE_URL" --title="$WP_SITE_TITLE" --admin_user="$WP_ADMIN_USER" \
    --admin_password="$WP_ADMIN_PASSWORD" --admin_email="$WP_ADMIN_EMAIL" --skip-email || exit 1
  log "WordPress installed: the administrator is $WP_ADMIN_USER"
  # Posts and the REST API show the author's public name and address slug, and
  # both start as the login name. Different from it, they do not tell a visitor
  # which user name to try.
  wp user update "$WP_ADMIN_USER" --user_nicename=editor --display_name=Editor --nickname=Editor \
    || log "the administrator's public name was not changed"
fi

if [ -n "$WP_LOCALE" ] && [ "$WP_LOCALE" != "en_US" ]; then
  retry wp language core install "$WP_LOCALE" --activate || log "language $WP_LOCALE was not installed"
fi
if [ -n "$WP_TIMEZONE" ]; then
  wp option update timezone_string "$WP_TIMEZONE" || log "time zone $WP_TIMEZONE was refused"
fi
wp rewrite structure '/%postname%/' || log "permalinks were not set"

# Two Factor is installed and left for each user to turn on in their profile.
# Turned on here it would send the login code by email, and an email that does
# not arrive (SES sandbox, an unverified address) would lock the administrator out.
PLUGINS="redis-cache amazon-s3-and-cloudfront wp-ses two-factor"
for plugin in $PLUGINS; do
  retry wp plugin install "$plugin" --activate || log "plugin $plugin was not installed"
done
wp plugin auto-updates enable $PLUGINS || log "plugin auto-updates were not turned on"
wp redis enable || log "the Redis object cache was not enabled"
# WP Offload SES creates its tables the first time an administration page
# loads, and until then every message fails. A new site can need one before
# that: a password reset, a message from the contact form.
wp eval 'global $wp_offload_ses; if (!isset($wp_offload_ses)) exit(1); $wp_offload_ses->upgrade_routines();' \
  || log "the tables of WP Offload SES were not created"

# A must-use plugin: no theme or plugin update removes it.
mkdir -p "$SITE/wp-content/mu-plugins"
cat > "$SITE/wp-content/mu-plugins/struct8-site.php" <<'MU'
<?php
// Site settings of the WordPress Professional template, written on its first start.

// XML-RPC is where password guessing goes, and nothing on this site uses it: the
// block editor and the WordPress apps use the REST API.
if (defined('XMLRPC_REQUEST') && XMLRPC_REQUEST) {
  http_response_code(403);
  exit;
}
add_filter('xmlrpc_enabled', '__return_false');

// Visitors who are not logged in do not get the list of users.
add_filter('rest_endpoints', function ($endpoints) {
  if (!is_user_logged_in()) {
    unset($endpoints['/wp/v2/users'], $endpoints['/wp/v2/users/(?P<id>[\d]+)']);
  }
  return $endpoints;
});

// Messages from the site go out under its title instead of "WordPress".
add_filter('wp_mail_from_name', function ($name) {
  return $name === 'WordPress' ? wp_specialchars_decode(get_bloginfo('name'), ENT_QUOTES) : $name;
});
MU


case "$WP_DEMO_CONTENT" in
  true|True|TRUE|1|yes|on) demo=yes ;;
  *) demo=no ;;
esac
if [ "$demo" = yes ] && ! wp option get struct8_demo_content >/dev/null 2>&1; then
  # The Contact page holds its form. Activating the plugin creates the form,
  # and its messages go to the site's administration email address. Contact
  # Form 7 keeps no copy, and the visitor is told the message was sent before
  # the email goes out: Flamingo keeps every message under Flamingo > Inbound
  # Messages, so one whose email never arrives is still there.
  for plugin in contact-form-7 flamingo; do
    retry wp plugin install "$plugin" --activate || log "plugin $plugin was not installed"
  done
  wp plugin auto-updates enable contact-form-7 flamingo || log "plugin auto-updates were not turned on"
  # Pages, posts and photos of the active theme, built in one PHP run: every wp
  # command starts WordPress again, and the first start has a time limit.
  cat > /tmp/struct8-demo.php <<'PHP'
<?php
// Sample site of the WordPress Professional template, run by wp-auto-setup.sh.
//
// The photos are the ones the active theme ships in assets/images (Twenty
// Twenty-Five has about 30). They are imported into the media library, so Offload
// Media sends them to S3. A photo the theme does not have is left out and the
// block that shows it goes with it: a theme without photos gets text only pages.

kses_remove_filters();
require_once ABSPATH . 'wp-admin/includes/file.php';
require_once ABSPATH . 'wp-admin/includes/media.php';
require_once ABSPATH . 'wp-admin/includes/image.php';

global $photos;
$photos = array();

function demo_photo($key, $name, $alt) {
  global $photos;
  $files = glob(get_template_directory() . '/assets/images/' . $name . '.*');
  if (!$files) return;
  $tmp = wp_tempnam($files[0]);
  if (!$tmp || !copy($files[0], $tmp)) return;
  $id = media_handle_sideload(array('name' => basename($files[0]), 'tmp_name' => $tmp), 0, $alt);
  if (is_wp_error($id)) {
    @unlink($tmp);
    fwrite(STDERR, 'wp-setup: photo ' . $name . ' was not imported: ' . $id->get_error_message() . PHP_EOL);
    return;
  }
  update_post_meta($id, '_wp_attachment_image_alt', $alt);
  $photos[$key] = array('id' => $id, 'url' => get_post_field('guid', $id), 'alt' => $alt);
}

function demo_p($text, $center = false) {
  if ($center) return "<!-- wp:paragraph {\"align\":\"center\"} -->\n<p class=\"has-text-align-center\">" . $text . "</p>\n<!-- /wp:paragraph -->\n\n";
  return "<!-- wp:paragraph -->\n<p>" . $text . "</p>\n<!-- /wp:paragraph -->\n\n";
}

function demo_h($text, $level = 2, $center = false) {
  $attrs = array();
  if ($center) $attrs['textAlign'] = 'center';
  if ($level != 2) $attrs['level'] = $level;
  $json = $attrs ? ' ' . wp_json_encode($attrs) : '';
  $class = 'wp-block-heading' . ($center ? ' has-text-align-center' : '');
  return '<!-- wp:heading' . $json . " -->\n<h" . $level . ' class="' . $class . '">' . $text . '</h' . $level . ">\n<!-- /wp:heading -->\n\n";
}

function demo_image($key, $ratio = '') {
  global $photos;
  if (!isset($photos[$key])) return '';
  $f = $photos[$key];
  $attrs = array('id' => $f['id']);
  $style = '';
  if ($ratio !== '') {
    $attrs['aspectRatio'] = $ratio;
    $attrs['scale'] = 'cover';
    $style = ' style="aspect-ratio:' . $ratio . ';object-fit:cover"';
  }
  $attrs['sizeSlug'] = 'large';
  $attrs['linkDestination'] = 'none';
  return '<!-- wp:image ' . wp_json_encode($attrs) . " -->\n" .
    '<figure class="wp-block-image size-large"><img src="' . esc_url($f['url']) . '" alt="' . esc_attr($f['alt']) . '" class="wp-image-' . $f['id'] . '"' . $style . '/></figure>' . "\n" .
    "<!-- /wp:image -->\n\n";
}

function demo_buttons($items, $center = false) {
  $json = $center ? ' {"layout":{"type":"flex","justifyContent":"center"}}' : '';
  $out = '<!-- wp:buttons' . $json . " -->\n<div class=\"wp-block-buttons\">";
  foreach ($items as $label => $url) {
    $out .= "<!-- wp:button -->\n<div class=\"wp-block-button\"><a class=\"wp-block-button__link wp-element-button\" href=\"" . esc_url($url) . "\">" . $label . "</a></div>\n<!-- /wp:button -->";
  }
  return $out . "</div>\n<!-- /wp:buttons -->\n\n";
}

function demo_cover($key, $inner) {
  global $photos;
  if (!isset($photos[$key])) return $inner;
  $f = $photos[$key];
  $attrs = wp_json_encode(array('url' => $f['url'], 'id' => $f['id'], 'dimRatio' => 40, 'minHeight' => 420, 'align' => 'full'));
  return '<!-- wp:cover ' . $attrs . " -->\n" .
    '<div class="wp-block-cover alignfull" style="min-height:420px"><span aria-hidden="true" class="wp-block-cover__background has-background-dim-40 has-background-dim"></span><img class="wp-block-cover__image-background wp-image-' . $f['id'] . '" alt="' . esc_attr($f['alt']) . '" src="' . esc_url($f['url']) . '" data-object-fit="cover"/><div class="wp-block-cover__inner-container">' . "\n" . $inner . '</div></div>' . "\n" .
    "<!-- /wp:cover -->\n\n";
}

function demo_columns($cells) {
  $out = "<!-- wp:columns {\"align\":\"wide\"} -->\n<div class=\"wp-block-columns alignwide\">";
  foreach ($cells as $cell) {
    $out .= "<!-- wp:column -->\n<div class=\"wp-block-column\">" . $cell . "</div>\n<!-- /wp:column -->";
  }
  return $out . "</div>\n<!-- /wp:columns -->\n\n";
}

function demo_gallery($keys) {
  $inner = '';
  foreach ($keys as $key) $inner .= demo_image($key);
  if ($inner === '') return '';
  return "<!-- wp:gallery {\"columns\":4,\"linkTo\":\"none\",\"align\":\"wide\"} -->\n<figure class=\"wp-block-gallery alignwide has-nested-images columns-4 is-cropped\">" . $inner . "</figure>\n<!-- /wp:gallery -->\n\n";
}

function demo_post($type, $title, $content, $order = 0, $thumbnail = '') {
  global $photos;
  $id = wp_insert_post(array(
    'post_type' => $type,
    'post_status' => 'publish',
    'post_title' => $title,
    'post_content' => $content,
    'menu_order' => $order,
  ), true);
  if (is_wp_error($id)) {
    fwrite(STDERR, 'wp-setup: ' . $title . ' was not created: ' . $id->get_error_message() . PHP_EOL);
    return 0;
  }
  if ($thumbnail !== '' && isset($photos[$thumbnail])) set_post_thumbnail($id, $photos[$thumbnail]['id']);
  return $id;
}

demo_photo('hero', 'coming-soon-bg-image', 'A meadow of wildflowers with a lone tree');
demo_photo('bloom', 'botany-flowers-closeup', 'White flowers with long green leaves');
demo_photo('hibiscus', 'red-hibiscus-closeup', 'A red hibiscus flower');
demo_photo('meadow', 'flower-meadow-square', 'A meadow of yellow and red flowers');
demo_photo('birds', 'marshland-birds-square', 'Two birds standing in shallow water at sunset');
demo_photo('coral', 'coral-square', 'Coral growing under the sea');
demo_photo('creek', 'dallas-creek-square', 'A flower with orange petals against a dark background');
demo_photo('purple', 'malibu-plantlife', 'A purple flower');

// The "Hello world!" post and the "Sample Page" of a new installation.
$hello = get_page_by_path('hello-world', OBJECT, 'post');
if ($hello) wp_delete_post($hello->ID, true);
$sample = get_page_by_path('sample-page');
if ($sample) wp_delete_post($sample->ID, true);

$home = demo_post('page', 'Home',
  demo_cover('hero',
    demo_h('Welcome', 1, true) .
    demo_p('A WordPress site that runs on AWS, ready for you to edit.', true) .
    demo_buttons(array('Read the blog' => home_url('/blog/'), 'Get in touch' => home_url('/contact/')), true)
  ) .
  demo_columns(array(
    demo_image('bloom', '4/3') . demo_h('Write', 3) . demo_p('Add posts and pages with the block editor. Everything on this site is sample content that you can edit or delete.'),
    demo_image('hibiscus', '4/3') . demo_h('Show', 3) . demo_p('Upload photos to the media library. They are copied to Amazon S3 and delivered by CloudFront.'),
    demo_image('birds', '4/3') . demo_h('Run', 3) . demo_p('Amazon ECS serves the site, Aurora keeps the data and ElastiCache holds the object cache.'),
  )) .
  demo_h('Latest posts', 2, true) .
  '<!-- wp:latest-posts {"postsToShow":3,"displayPostDate":true,"displayFeaturedImage":true,"featuredImageSizeSlug":"medium","postLayout":"grid","columns":3,"align":"wide"} /-->' . "\n\n",
  1
);
demo_post('page', 'About',
  demo_columns(array(
    demo_image('meadow'),
    demo_h('About this site') . demo_p('Tell your visitors who you are and what this site is for.'),
  )),
  2
);
demo_post('page', 'Gallery',
  demo_p('The photos on this page come with the theme and live in the media library.') .
  demo_gallery(array('hero', 'bloom', 'hibiscus', 'meadow', 'birds', 'coral', 'creek', 'purple')),
  3
);
$blog = demo_post('page', 'Blog', '', 4);
// The form Contact Form 7 creates when it is activated. Without the plugin the
// page keeps a line of text.
$forms = get_posts(array('post_type' => 'wpcf7_contact_form', 'numberposts' => 1, 'orderby' => 'ID', 'order' => 'ASC'));
if ($forms) {
  $contact = demo_p('Send a message with the form below. It goes to the email address of the site administrator.') .
    "<!-- wp:shortcode -->\n[contact-form-7 id=\"" . $forms[0]->ID . "\" title=\"" . esc_attr($forms[0]->post_title) . "\"]\n<!-- /wp:shortcode -->\n\n";
} else {
  $contact = demo_p('Replace this text with the ways to reach you.');
}
demo_post('page', 'Contact', $contact, 5);

// The featured image is the post's photo: the theme shows it on the Blog page and
// above the post, so the content holds no second copy of it. The three are square,
// so the latest posts grid of the home page has cells of one size.
demo_post('post', 'Welcome to your new site',
  demo_p('This is a sample post. Posts appear on the Blog page and in the latest posts list of the home page.'),
  0, 'creek');
demo_post('post', 'Your photos are served from Amazon S3',
  demo_p('Photos uploaded to the media library are copied to an S3 bucket by WP Offload Media Lite and delivered by CloudFront under /wp-content/media/.'),
  0, 'meadow');
$next = demo_p('Change the site title and the theme under Appearance, replace the sample pages with your own, and turn on two-factor authentication in your profile after the first login.');
if ($forms && defined('FLAMINGO_VERSION')) {
  $next .= demo_p('Messages sent from the Contact page arrive by email and are also kept under Flamingo, Inbound Messages.');
}
demo_post('post', 'Next steps', $next, 0, 'coral');

if ($home && wp_is_block_theme() && file_exists(get_template_directory() . '/templates/page-no-title.html')) {
  update_post_meta($home, '_wp_page_template', 'page-no-title');
}
if ($home && $blog) {
  update_option('show_on_front', 'page');
  update_option('page_on_front', $home);
  update_option('page_for_posts', $blog);
}
update_option('blogdescription', 'A WordPress site on AWS');

// The footer of Twenty Twenty-Five links to pages that do not exist. A footer of
// the site's own pages replaces it, in the database, so a theme update keeps it.
if (wp_is_block_theme()) {
  $footer = '<!-- wp:group {"align":"full","style":{"spacing":{"padding":{"top":"var:preset|spacing|60","bottom":"var:preset|spacing|60"}}},"layout":{"type":"constrained"}} -->' . "\n" .
    '<div class="wp-block-group alignfull" style="padding-top:var(--wp--preset--spacing--60);padding-bottom:var(--wp--preset--spacing--60)">' .
    '<!-- wp:group {"align":"wide","layout":{"type":"flex","flexWrap":"wrap","justifyContent":"space-between"}} -->' . "\n" .
    '<div class="wp-block-group alignwide"><!-- wp:site-title {"level":0} /-->' . "\n" .
    '<!-- wp:navigation {"overlayMenu":"never","layout":{"type":"flex","setCascadingProperties":true,"justifyContent":"right"}} -->' . "\n" .
    '<!-- wp:page-list /-->' . "\n" .
    '<!-- /wp:navigation --></div>' . "\n" .
    '<!-- /wp:group -->' . "\n\n" .
    '<!-- wp:group {"align":"wide"} -->' . "\n" .
    '<div class="wp-block-group alignwide"><!-- wp:paragraph -->' . "\n" . '<p>Built with WordPress on AWS.</p>' . "\n" . '<!-- /wp:paragraph --></div>' . "\n" .
    '<!-- /wp:group --></div>' . "\n" .
    '<!-- /wp:group -->';
  $part = wp_insert_post(array(
    'post_type' => 'wp_template_part',
    'post_status' => 'publish',
    'post_name' => 'footer',
    'post_title' => 'Footer',
    'post_content' => $footer,
  ), true);
  if (!is_wp_error($part)) {
    wp_set_object_terms($part, get_stylesheet(), 'wp_theme');
    wp_set_object_terms($part, 'footer', 'wp_template_part_area');
  }
}

add_option('struct8_demo_content', 1);
echo 'wp-setup: ' . count($photos) . ' photos imported' . PHP_EOL;
PHP
  if wp eval-file /tmp/struct8-demo.php; then log "demo content created"; else log "demo content was not created"; fi
  rm -f /tmp/struct8-demo.php
fi

chown -R www-data:www-data "$SITE/wp-content" 2>/dev/null
touch "$DONE"
rm -f "$STARTED" "$WPCLI"
log "done"
        EOF
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
      },
      {
        name  = "AWS_SESV2_EMAIL_IDENTITY_NAME_0"
        value = "wpMail"
      }
    ]
    secrets = [
      {
        name      = "WORDPRESS_DB_PASSWORD"
        valueFrom = data.aws_secretsmanager_secret.wpSecrets.arn
      },
      {
        name      = "DB_ADMIN_USER"
        valueFrom = "${aws_rds_cluster.wp-aurora.master_user_secret[0].secret_arn}:username::"
      },
      {
        name      = "DB_ADMIN_PASSWORD"
        valueFrom = "${aws_rds_cluster.wp-aurora.master_user_secret[0].secret_arn}:password::"
      },
      {
        name      = "WP_ADMIN_PASSWORD"
        valueFrom = data.aws_ssm_parameter.wpAdminPassword.arn
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
    command                = ["sh", "-c", "set -e; mkdir -p /etc/ssl/private; openssl req -x509 -nodes -newkey rsa:2048 -days 3650 -subj /CN=wordpress -addext basicConstraints=critical,CA:FALSE -keyout /etc/ssl/private/ssl-cert-snakeoil.key -out /etc/ssl/certs/ssl-cert-snakeoil.pem; a2enmod ssl; a2ensite default-ssl; printenv WP_DB_BOOTSTRAP > /tmp/db-bootstrap.php; php /tmp/db-bootstrap.php; rm -f /tmp/db-bootstrap.php; if printenv WP_AUTO_SETUP_SCRIPT > /tmp/wp-auto-setup.sh; then bash /tmp/wp-auto-setup.sh; fi; rm -f /tmp/wp-auto-setup.sh; unset WP_DB_BOOTSTRAP WP_AUTO_SETUP_SCRIPT WP_ADMIN_PASSWORD DB_ADMIN_USER DB_ADMIN_PASSWORD; exec docker-entrypoint.sh apache2-foreground"]
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
  memory                   = "640"
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

resource "aws_sesv2_email_identity" "wpMail" {
  email_identity = "wp.cloudman.pro"
  tags = {
    Name           = "wpMail"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
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


