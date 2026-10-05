terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  backend "s3" {
    bucket  = "struct8-import"
    key     = "952133486861/Platform-mon/main.tfstate"
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

### ALTERNATE REGION PROVIDERS ###

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

provider "aws" {
  alias  = "us_east_2"
  region = "us-east-2"
}




### SYSTEM DATA SOURCES ###

data "aws_route53_zone" "Cloudman" {
  name = "cloudman.pro"
}




### EXTERNAL REFERENCES ###

data "aws_s3_bucket" "flowlogs-bucket" {
  bucket   = "flowlogs-bucket-${data.aws_caller_identity.current.account_id}-us-east-1-an"
  provider = aws.us_east_1
}

data "aws_s3_bucket" "grafanalabs-cf-templates" {
  bucket   = "grafanalabs-cf-templates"
  provider = aws.us_east_2
}




### CATEGORY: IAM ###

resource "aws_iam_instance_profile" "ec2-loadgen-mon_profile" {
  name = "ec2-loadgen-mon_profile"
  role = aws_iam_role.ec2-loadgen-mon_role.name
  tags = {
    Name           = "ec2-loadgen-mon_profile"
    State          = "Platform-mon"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_instance_profile" "nat-a1_profile" {
  name = "nat-a1_profile"
  path = "/"
  role = aws_iam_role.nat-a1_role.name
  tags = {
    Name           = "nat-a1_profile"
    State          = "Platform-mon"
    Struct8Creator = "Contato Struct"
  }
}

data "aws_iam_policy_document" "loadgen-mon_debug_permissions" {
  statement {
    sid       = "SendToTaggedInstancesOnly"
    effect    = "Allow"
    actions   = ["ssm:SendCommand"]
    resources = ["arn:aws:ec2:*:*:instance/*"]
    condition {
      test     = "StringEquals"
      values   = ["rnfvftw1G6oN_45VxIfOe"]
      variable = "aws:ResourceTag/Struct8Debug"
    }
  }
  statement {
    sid       = "PinnedDocumentOnly"
    effect    = "Allow"
    actions   = ["ssm:SendCommand"]
    resources = ["arn:aws:ssm:*::document/AWS-RunShellScript"]
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
      values   = ["rnfvftw1G6oN_45VxIfOe"]
      variable = "aws:ResourceTag/Struct8Debug"
    }
  }
  statement {
    sid       = "RunShellScriptDocument"
    effect    = "Allow"
    actions   = ["ssm:SendCommand"]
    resources = ["arn:aws:ssm:*::document/AWS-RunShellScript"]
  }
}

data "aws_iam_policy_document" "loadgen-mon_debug_trust" {
  statement {
    effect = "Allow"
    principals {
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/CrossAccountStruct8"]
      type        = "AWS"
    }
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "nat-mon_debug_permissions" {
  statement {
    sid       = "SendToTaggedInstancesOnly"
    effect    = "Allow"
    actions   = ["ssm:SendCommand"]
    resources = ["arn:aws:ec2:*:*:instance/*"]
    condition {
      test     = "StringEquals"
      values   = ["pdhvQPpUXFTwmrU_D1L5h"]
      variable = "aws:ResourceTag/Struct8Debug"
    }
  }
  statement {
    sid       = "PinnedDocumentOnly"
    effect    = "Allow"
    actions   = ["ssm:SendCommand"]
    resources = ["arn:aws:ssm:*::document/AWS-RunShellScript"]
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
      values   = ["pdhvQPpUXFTwmrU_D1L5h"]
      variable = "aws:ResourceTag/Struct8Debug"
    }
  }
  statement {
    sid       = "RunShellScriptDocument"
    effect    = "Allow"
    actions   = ["ssm:SendCommand"]
    resources = ["arn:aws:ssm:*::document/AWS-RunShellScript"]
  }
}

data "aws_iam_policy_document" "nat-mon_debug_trust" {
  statement {
    effect = "Allow"
    principals {
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/CrossAccountStruct8"]
      type        = "AWS"
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "Struct8Debug-loadgen-mon" {
  name                 = "Struct8Debug-rnfvftw1G6oN_45VxIfOe"
  assume_role_policy   = data.aws_iam_policy_document.loadgen-mon_debug_trust.json
  max_session_duration = 3600
}

resource "aws_iam_role" "Struct8Debug-nat-mon" {
  name                 = "Struct8Debug-pdhvQPpUXFTwmrU_D1L5h"
  assume_role_policy   = data.aws_iam_policy_document.nat-mon_debug_trust.json
  max_session_duration = 3600
}

resource "aws_iam_role" "ec2-loadgen-mon_role" {
  name = "ec2-loadgen-mon_role"
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
    Name           = "ec2-loadgen-mon_role"
    State          = "Platform-mon"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "nat-a1_role" {
  name                  = "nat-a1_role"
  assume_role_policy    = "{\"Statement\":[{\"Action\":\"sts:AssumeRole\",\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"ec2.amazonaws.com\"}}],\"Version\":\"2012-10-17\"}"
  force_detach_policies = false
  max_session_duration  = 3600
  path                  = "/"
  tags = {
    Name           = "nat-a1_role"
    State          = "Platform-mon"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role_policy" "Struct8Debug-loadgen-mon_policy" {
  name   = "Struct8Debug-rnfvftw1G6oN_45VxIfOe-policy"
  policy = data.aws_iam_policy_document.loadgen-mon_debug_permissions.json
  role   = aws_iam_role.Struct8Debug-loadgen-mon.id
}

resource "aws_iam_role_policy" "Struct8Debug-nat-mon_policy" {
  name   = "Struct8Debug-pdhvQPpUXFTwmrU_D1L5h-policy"
  policy = data.aws_iam_policy_document.nat-mon_debug_permissions.json
  role   = aws_iam_role.Struct8Debug-nat-mon.id
}

resource "aws_iam_role_policy_attachment" "AmazonSSMManagedInstanceCore_to_ec2-loadgen-mon_attach" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.ec2-loadgen-mon_role.name
}

resource "aws_iam_role_policy_attachment" "AmazonSSMManagedInstanceCore_to_ec2-nat-grafana-mon_attach" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.nat-a1_role.name
}

resource "aws_acm_certificate" "grafana-cloudman-pro-cert-mon" {
  domain_name               = "grafana.cloudman.pro"
  key_algorithm             = "RSA_2048"
  subject_alternative_names = ["otel.cloudman.pro"]
  validation_method         = "DNS"
  lifecycle {
    create_before_destroy = true
  }
  options {
    certificate_transparency_logging_preference = "ENABLED"
  }
  tags = {
    Name           = "grafana-cloudman-pro-cert-mon"
    State          = "Platform-mon"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_acm_certificate_validation" "Validation_grafana-cloudman-pro-cert-mon" {
  certificate_arn = aws_acm_certificate.grafana-cloudman-pro-cert-mon.arn
  validation_record_fqdns = concat(
    [for record in aws_route53_record.Route53_Record_grafana-cloudman-pro-cert-mon_grafana_cloudman_pro : record.fqdn],
    [for record in aws_route53_record.Route53_Record_grafana-cloudman-pro-cert-mon_otel_cloudman_pro : record.fqdn],
  )
}




### CATEGORY: NETWORK ###

resource "aws_vpc" "vpc-grafana-lgtm-mon" {
  cidr_block           = "10.4.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default"
  tags = {
    Name           = "vpc-grafana-lgtm-mon"
    State          = "Platform-mon"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "snet-public-1a-mon" {
  vpc_id                  = aws_vpc.vpc-grafana-lgtm-mon.id
  availability_zone       = "us-west-2a"
  cidr_block              = "10.4.0.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name           = "snet-public-1a-mon"
    State          = "Platform-mon"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "snet-public-1b-mon" {
  vpc_id                  = aws_vpc.vpc-grafana-lgtm-mon.id
  availability_zone       = "us-west-2b"
  cidr_block              = "10.4.1.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name           = "snet-public-1b-mon"
    State          = "Platform-mon"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_internet_gateway" "igw-grafana-lgtm-mon" {
  vpc_id = aws_vpc.vpc-grafana-lgtm-mon.id
  tags = {
    Name           = "igw-grafana-lgtm-mon"
    State          = "Platform-mon"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route" "route_rtb-public-mon_to_igw-grafana-lgtm-mon_ipv4" {
  gateway_id             = aws_internet_gateway.igw-grafana-lgtm-mon.id
  route_table_id         = aws_route_table.rtb-public-mon.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route53_record" "Route53_Record_grafana-cloudman-pro-cert-mon_grafana_cloudman_pro" {
  for_each = {
    for dvo in aws_acm_certificate.grafana-cloudman-pro-cert-mon.domain_validation_options : dvo.domain_name => dvo
    if dvo.domain_name == "grafana.cloudman.pro"
  }
  name            = each.value.resource_record_name
  zone_id         = data.aws_route53_zone.Cloudman.zone_id
  allow_overwrite = true
  records         = [each.value.resource_record_value]
  ttl             = 300
  type            = each.value.resource_record_type
}

resource "aws_route53_record" "Route53_Record_grafana-cloudman-pro-cert-mon_otel_cloudman_pro" {
  for_each = {
    for dvo in aws_acm_certificate.grafana-cloudman-pro-cert-mon.domain_validation_options : dvo.domain_name => dvo
    if dvo.domain_name == "otel.cloudman.pro"
  }
  name            = each.value.resource_record_name
  zone_id         = data.aws_route53_zone.Cloudman.zone_id
  allow_overwrite = true
  records         = [each.value.resource_record_value]
  ttl             = 300
  type            = each.value.resource_record_type
}

resource "aws_route53_record" "alias_a_aws_lb_alb-grafana-mon_grafana_cloudman_pro" {
  name    = "grafana.cloudman.pro"
  zone_id = data.aws_route53_zone.Cloudman.zone_id
  type    = "A"
  alias {
    name                   = aws_lb.alb-grafana-mon.dns_name
    zone_id                = aws_lb.alb-grafana-mon.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "alias_a_aws_lb_alb-grafana-mon_otel_cloudman_pro" {
  name    = "otel.cloudman.pro"
  zone_id = data.aws_route53_zone.Cloudman.zone_id
  type    = "A"
  alias {
    name                   = aws_lb.alb-grafana-mon.dns_name
    zone_id                = aws_lb.alb-grafana-mon.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route_table" "rtb-public-mon" {
  vpc_id = aws_vpc.vpc-grafana-lgtm-mon.id
  tags = {
    Name           = "rtb-public-mon"
    State          = "Platform-mon"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route_table_association" "aws_route_table_association_snet_public_1a_mon_rtb_public_mon" {
  route_table_id = aws_route_table.rtb-public-mon.id
  subnet_id      = aws_subnet.snet-public-1a-mon.id
}

resource "aws_route_table_association" "aws_route_table_association_snet_public_1b_mon_rtb_public_mon" {
  route_table_id = aws_route_table.rtb-public-mon.id
  subnet_id      = aws_subnet.snet-public-1b-mon.id
}

resource "aws_security_group" "instance_ec2-loadgen-mon_group" {
  name                   = "instance_ec2-loadgen-mon_group"
  vpc_id                 = aws_vpc.vpc-grafana-lgtm-mon.id
  description            = "SG for the OTLP load generator. Ingress 80 for the web control panel (protected by OTEL_PANEL_TOKEN); egress open so it can reach the OTLP gateway over the internet and pull the Docker image."
  revoke_rules_on_delete = false
}

resource "aws_security_group" "instance_nat-a1_group" {
  name                   = "instance_nat-a1_group"
  vpc_id                 = aws_vpc.vpc-grafana-lgtm-mon.id
  description            = "NAT instance SG. Accepts all traffic from the VPC CIDR (ingress -1 from 10.4.0.0/16) so it can MASQUERADE private subnet egress to the internet. Egress open."
  revoke_rules_on_delete = false
  tags = {
    Name           = "instance_nat-a1_group"
    State          = "Platform-mon"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group" "lb_alb-grafana-mon_group" {
  name                   = "lb_alb-grafana-mon_group"
  vpc_id                 = aws_vpc.vpc-grafana-lgtm-mon.id
  revoke_rules_on_delete = false
  tags = {
    Name           = "lb_alb-grafana-mon_group"
    State          = "Platform-mon"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group_rule" "rule_instance_ec2_loadgen_mon_group_egress_all_protocols" {
  security_group_id = aws_security_group.instance_ec2-loadgen-mon_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "rule_instance_ec2_loadgen_mon_group_ingress_tcp_80" {
  security_group_id = aws_security_group.instance_ec2-loadgen-mon_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "web control panel (token-protected)"
  from_port         = 80
  protocol          = "tcp"
  to_port           = 80
  type              = "ingress"
}

resource "aws_security_group_rule" "rule_instance_nat_a1_group_egress_all_protocols" {
  security_group_id = aws_security_group.instance_nat-a1_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "rule_instance_nat_a1_group_ingress_all_protocols" {
  security_group_id = aws_security_group.instance_nat-a1_group.id
  cidr_blocks       = ["10.4.0.0/16"]
  description       = "NAT: all traffic from the VPC to be routed out"
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "ingress"
}

resource "aws_security_group_rule" "rule_lb_alb_grafana_mon_group_egress_all_protocols" {
  security_group_id = aws_security_group.lb_alb-grafana-mon_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "rule_lb_alb_grafana_mon_group_ingress_tcp_443" {
  security_group_id = aws_security_group.lb_alb-grafana-mon_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 443
  protocol          = "tcp"
  to_port           = 443
  type              = "ingress"
}

resource "aws_security_group_rule" "rule_lb_alb_grafana_mon_group_ingress_tcp_80" {
  security_group_id = aws_security_group.lb_alb-grafana-mon_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 80
  protocol          = "tcp"
  to_port           = 80
  type              = "ingress"
}

resource "aws_flow_log" "grafana-flowlogs-mon" {
  vpc_id               = aws_vpc.vpc-grafana-lgtm-mon.id
  log_destination      = data.aws_s3_bucket.flowlogs-bucket.arn
  log_destination_type = "s3"
  log_format           = "$${version} $${vpc-id} $${subnet-id} $${interface-id} $${instance-id} $${srcaddr} $${dstaddr} $${pkt-srcaddr} $${pkt-dstaddr} $${srcport} $${dstport} $${protocol} $${packets} $${bytes} $${start} $${end} $${action} $${log-status} $${flow-direction} $${traffic-path} $${pkt-src-aws-service} $${pkt-dst-aws-service} $${interface-type}"
  traffic_type         = "ALL"
  tags = {
    Name           = "grafana-flowlogs-mon"
    State          = "Platform-mon"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_lb" "alb-grafana-mon" {
  name                             = "alb-grafana-mon"
  enable_cross_zone_load_balancing = true
  enable_http2                     = true
  idle_timeout                     = 60
  load_balancer_type               = "application"
  security_groups                  = [aws_security_group.lb_alb-grafana-mon_group.id]
  subnets                          = [aws_subnet.snet-public-1a-mon.id, aws_subnet.snet-public-1b-mon.id]
  access_logs {
    bucket  = aws_s3_bucket.alb-access-logs-mon.id
    enabled = true
  }
  tags = {
    Name           = "alb-grafana-mon"
    State          = "Platform-mon"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_s3_bucket_policy.aws_s3_bucket_policy_alb-access-logs-mon_st_Platform-mon]
}

resource "aws_lb_listener" "listener-http-redirect-mon" {
  load_balancer_arn                    = aws_lb.alb-grafana-mon.arn
  port                                 = 80
  protocol                             = "HTTP"
  routing_http_response_server_enabled = true
  default_action {
    order = 1
    type  = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
  tags = {
    Name           = "listener-http-redirect-mon"
    State          = "Platform-mon"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_lb_listener" "listener-https1-mon" {
  certificate_arn                      = aws_acm_certificate.grafana-cloudman-pro-cert-mon.arn
  load_balancer_arn                    = aws_lb.alb-grafana-mon.arn
  port                                 = 443
  protocol                             = "HTTPS"
  routing_http_response_server_enabled = true
  ssl_policy                           = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  default_action {
    order = 1
    type  = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "404 - no route matched"
      status_code  = "404"
    }
  }
  tags = {
    Name           = "listener-https1-mon"
    State          = "Platform-mon"
    Struct8Creator = "Contato Struct"
  }
}




### CATEGORY: STORAGE ###

resource "aws_s3_bucket" "alb-access-logs-mon" {
  bucket              = "alb-access-logs-mon-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.region}-an"
  bucket_namespace    = "account-regional"
  force_destroy       = true
  object_lock_enabled = false
  tags = {
    Name           = "alb-access-logs-mon"
    State          = "Platform-mon"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_s3_bucket" "bucket-source-promptail-mon" {
  bucket              = "bucket-source-promptail-mon-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.region}-an"
  bucket_namespace    = "account-regional"
  force_destroy       = false
  object_lock_enabled = false
  tags = {
    Name           = "bucket-source-promptail-mon"
    State          = "Platform-mon"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "alb-access-logs-mon_lifecycle" {
  bucket = aws_s3_bucket.alb-access-logs-mon.id
  rule {
    id     = "expire-alb-logs-7d"
    status = "Enabled"
    expiration {
      days                         = 7
      expired_object_delete_marker = false
    }
  }
}

resource "aws_s3_bucket_ownership_controls" "alb-access-logs-mon_controls" {
  bucket = aws_s3_bucket.alb-access-logs-mon.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_ownership_controls" "bucket-source-promptail-mon_controls" {
  bucket = aws_s3_bucket.bucket-source-promptail-mon.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

data "aws_iam_policy_document" "aws_s3_bucket_policy_alb-access-logs-mon_st_Platform-mon_doc" {
  statement {
    sid    = "AllowElbAccessLogs"
    effect = "Allow"
    principals {
      identifiers = ["logdelivery.elasticloadbalancing.amazonaws.com"]
      type        = "Service"
    }
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.alb-access-logs-mon.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]
    condition {
      test     = "ArnLike"
      values   = ["arn:aws:elasticloadbalancing:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:loadbalancer/*"]
      variable = "aws:SourceArn"
    }
  }
}

resource "aws_s3_bucket_policy" "aws_s3_bucket_policy_alb-access-logs-mon_st_Platform-mon" {
  bucket = aws_s3_bucket.alb-access-logs-mon.id
  policy = data.aws_iam_policy_document.aws_s3_bucket_policy_alb-access-logs-mon_st_Platform-mon_doc.json
}

resource "aws_s3_bucket_public_access_block" "alb-access-logs-mon_block" {
  block_public_acls       = true
  block_public_policy     = true
  bucket                  = aws_s3_bucket.alb-access-logs-mon.id
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "bucket-source-promptail-mon_block" {
  block_public_acls       = true
  block_public_policy     = true
  bucket                  = aws_s3_bucket.bucket-source-promptail-mon.id
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "alb-access-logs-mon_configuration" {
  bucket = aws_s3_bucket.alb-access-logs-mon.id
  rule {
    bucket_key_enabled = true
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "bucket-source-promptail-mon_configuration" {
  bucket = aws_s3_bucket.bucket-source-promptail-mon.id
  rule {
    bucket_key_enabled = true
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "alb-access-logs-mon_versioning" {
  bucket = aws_s3_bucket.alb-access-logs-mon.id
  versioning_configuration {
    mfa_delete = "Disabled"
    status     = "Suspended"
  }
}

resource "aws_s3_bucket_versioning" "bucket-source-promptail-mon_versioning" {
  bucket = aws_s3_bucket.bucket-source-promptail-mon.id
  versioning_configuration {
    mfa_delete = "Disabled"
    status     = "Suspended"
  }
}

resource "aws_s3_object_copy" "ObjectCopy-mon" {
  source             = "${data.aws_s3_bucket.grafanalabs-cf-templates.bucket}/lambda-promtail/lambda-promtail-v1.0.1.zip"
  bucket             = aws_s3_bucket.bucket-source-promptail-mon.bucket
  key                = "lambda-promtail/lambda-promtail-v1.0.1.zip"
  metadata_directive = "COPY"
  tagging_directive  = "REPLACE"
  tags = {
    Name           = "ObjectCopy-mon"
    State          = "Platform-mon"
    Struct8Creator = "Contato Struct"
  }
}




### CATEGORY: COMPUTE ###

data "local_file" "UserData_ec2-loadgen-mon" {
  filename = "${path.module}/.external_modules/struct8-templates/templates/vpc-otel-load-generator/v1/user_data/otel-loadgen-bootstrap.sh"
}

data "aws_ami" "AMI_Data_Source_ec2-loadgen-mon" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-minimal-2023.*-kernel-6.1-arm64"]
  }
}

resource "aws_instance" "ec2-loadgen-mon" {
  subnet_id                   = aws_subnet.snet-public-1b-mon.id
  ami                         = data.aws_ami.AMI_Data_Source_ec2-loadgen-mon.id
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.ec2-loadgen-mon_profile.name
  instance_type               = "t4g.small"
  user_data_base64 = base64encode(<<-EOFUData
#!/bin/bash

# --- BEGIN STRUCT8 VARIABLES ---
cat << 'EOFENV' > /etc/struct8_env
OTLP_ENDPOINT="otel.cloudman.pro:443"
OTLP_PROTOCOL="http"
OTLP_INSECURE="false"
OTEL_PANEL="on"
OTEL_PANEL_TOKEN="nXtcLKE19mP5MxoVaObypeSU3l70GfWZ"
OTEL_PANEL_MAX_WORKERS="20"
OTEL_PANEL_MAX_DURATION="3600"
NAME="ec2-loadgen-mon"
REGION="${data.aws_region.current.region}"
ACCOUNT="${data.aws_caller_identity.current.account_id}"
EOFENV
cat /etc/struct8_env >> /etc/environment
sed 's/^/export /' /etc/struct8_env > /etc/profile.d/struct8_vars.sh
chmod +x /etc/profile.d/struct8_vars.sh
chmod 644 /etc/struct8_env
# --- END STRUCT8 VARIABLES ---

${data.local_file.UserData_ec2-loadgen-mon.content}
EOFUData
)
  vpc_security_group_ids = [aws_security_group.instance_ec2-loadgen-mon_group.id]
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
    Struct8Debug   = "rnfvftw1G6oN_45VxIfOe"
    Name           = "ec2-loadgen-mon"
    State          = "Platform-mon"
    Struct8Creator = "Contato Struct"
  }
}

data "local_file" "UserData_ec2-nat-grafana-mon" {
  filename = "${path.module}/.external_modules/struct8-templates/templates/ec2-nat-private/v1/user_data/Nat.sh"
}

data "aws_ami" "AMI_Data_Source_ec2-nat-grafana-mon" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-minimal-2023.*-kernel-6.1-arm64"]
  }
}

resource "aws_instance" "ec2-nat-grafana-mon" {
  subnet_id                   = aws_subnet.snet-public-1b-mon.id
  ami                         = data.aws_ami.AMI_Data_Source_ec2-nat-grafana-mon.id
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.nat-a1_profile.name
  instance_type               = "t4g.nano"
  source_dest_check           = false
  user_data_base64 = base64encode(<<-EOFUData
#!/bin/bash

${data.local_file.UserData_ec2-nat-grafana-mon.content}
EOFUData
)
  vpc_security_group_ids = [aws_security_group.instance_nat-a1_group.id]
  credit_specification {
    cpu_credits = "unlimited"
  }
  enclave_options {
    enabled = false
  }
  lifecycle {
    create_before_destroy = false
    prevent_destroy       = false
  }
  metadata_options {
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 2
    http_tokens                 = "required"
  }
  private_dns_name_options {
    enable_resource_name_dns_a_record    = false
    enable_resource_name_dns_aaaa_record = false
    hostname_type                        = "ip-name"
  }
  root_block_device {
    encrypted   = true
    iops        = 3000
    throughput  = 125
    volume_size = 8
    volume_type = "gp3"
  }
  tags = {
    Struct8Debug   = "pdhvQPpUXFTwmrU_D1L5h"
    Name           = "ec2-nat-grafana-mon"
    State          = "Platform-mon"
    Struct8Creator = "Contato Struct"
  }
}


