terraform {
  required_providers {
    archive = {
      source = "hashicorp/archive"
    }
    aws = {
      source = "hashicorp/aws"
    }
    time = {
      source = "hashicorp/time"
    }
  }

  backend "s3" {
    bucket  = "struct8-import"
    key     = "952133486861/products-search-state/main.tfstate"
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

data "aws_route53_zone" "cloudman-zone" {
  name = "cloudman.pro"
}

data "aws_cloudfront_origin_request_policy" "policy_cors_s3origin" {
  name = "Managed-CORS-S3Origin"
}

data "aws_cloudfront_cache_policy" "policy_cachingoptimized" {
  name = "Managed-CachingOptimized"
}

data "aws_cloudfront_origin_request_policy" "policy_allviewerexcepthostheader" {
  name = "Managed-AllViewerExceptHostHeader"
}

data "aws_cloudfront_cache_policy" "policy_cachingdisabled" {
  name = "Managed-CachingDisabled"
}




### CATEGORY: IAM ###

data "aws_iam_policy_document" "lambda_function_lambda-ingestion_st_products-search-state_doc" {
  statement {
    sid       = "AllowWriteLogs"
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.ingestion-logs.arn}:*"]
  }
  statement {
    sid       = "DataApi"
    effect    = "Allow"
    actions   = ["rds-data:BatchExecuteStatement", "rds-data:BeginTransaction", "rds-data:CommitTransaction", "rds-data:ExecuteStatement", "rds-data:RollbackTransaction"]
    resources = [aws_rds_cluster.products-aurora.arn]
  }
  statement {
    sid       = "AllowRDSSecretAccessproductsaurora"
    effect    = "Allow"
    actions   = ["secretsmanager:DescribeSecret", "secretsmanager:GetSecretValue"]
    resources = [aws_rds_cluster.products-aurora.master_user_secret[0].secret_arn]
  }
  statement {
    sid       = "AllowEventSourceRead"
    effect    = "Allow"
    actions   = ["sqs:DeleteMessage", "sqs:GetQueueAttributes", "sqs:ReceiveMessage"]
    resources = [aws_sqs_queue.ingestion-queue.arn]
  }
}

resource "aws_iam_policy" "lambda_function_lambda-ingestion_st_products-search-state" {
  name        = "lambda_function_lambda-ingestion_st_products-search-state"
  description = "Access Policy for lambda-ingestion"
  policy      = data.aws_iam_policy_document.lambda_function_lambda-ingestion_st_products-search-state_doc.json
}

data "aws_iam_policy_document" "lambda_function_lambda-init-db_st_products-search-state_doc" {
  statement {
    sid       = "AllowWriteLogs"
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.init-db-logs.arn}:*"]
  }
  statement {
    sid       = "DataApi"
    effect    = "Allow"
    actions   = ["rds-data:BatchExecuteStatement", "rds-data:BeginTransaction", "rds-data:CommitTransaction", "rds-data:ExecuteStatement", "rds-data:RollbackTransaction"]
    resources = [aws_rds_cluster.products-aurora.arn]
  }
  statement {
    sid       = "AllowRDSSecretAccessproductsaurora"
    effect    = "Allow"
    actions   = ["secretsmanager:DescribeSecret", "secretsmanager:GetSecretValue"]
    resources = [aws_rds_cluster.products-aurora.master_user_secret[0].secret_arn]
  }
}

resource "aws_iam_policy" "lambda_function_lambda-init-db_st_products-search-state" {
  name        = "lambda_function_lambda-init-db_st_products-search-state"
  description = "Access Policy for lambda-init-db"
  policy      = data.aws_iam_policy_document.lambda_function_lambda-init-db_st_products-search-state_doc.json
}

data "aws_iam_policy_document" "lambda_function_lambda-presign_st_products-search-state_doc" {
  statement {
    sid       = "AllowWriteLogs"
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.presign-logs.arn}:*"]
  }
  statement {
    sid       = "AllowImagePut"
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.static-site.arn}/img/*"]
  }
}

resource "aws_iam_policy" "lambda_function_lambda-presign_st_products-search-state" {
  name        = "lambda_function_lambda-presign_st_products-search-state"
  description = "Access Policy for lambda-presign"
  policy      = data.aws_iam_policy_document.lambda_function_lambda-presign_st_products-search-state_doc.json
}

data "aws_iam_policy_document" "lambda_function_lambda-publisher_st_products-search-state_doc" {
  statement {
    sid       = "AllowWriteLogs"
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.publisher-logs.arn}:*"]
  }
  statement {
    sid       = "AllowSQSActions"
    effect    = "Allow"
    actions   = ["sqs:DeleteMessage", "sqs:GetQueueAttributes", "sqs:ReceiveMessage", "sqs:SendMessage"]
    resources = [aws_sqs_queue.ingestion-queue.arn]
  }
}

resource "aws_iam_policy" "lambda_function_lambda-publisher_st_products-search-state" {
  name        = "lambda_function_lambda-publisher_st_products-search-state"
  description = "Access Policy for lambda-publisher"
  policy      = data.aws_iam_policy_document.lambda_function_lambda-publisher_st_products-search-state_doc.json
}

data "aws_iam_policy_document" "lambda_function_lambda-search_st_products-search-state_doc" {
  statement {
    sid       = "AllowWriteLogs"
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.search-logs.arn}:*"]
  }
  statement {
    sid       = "DataApi"
    effect    = "Allow"
    actions   = ["rds-data:BatchExecuteStatement", "rds-data:BeginTransaction", "rds-data:CommitTransaction", "rds-data:ExecuteStatement", "rds-data:RollbackTransaction"]
    resources = [aws_rds_cluster.products-aurora.arn]
  }
  statement {
    sid       = "AllowRDSSecretAccessproductsaurora"
    effect    = "Allow"
    actions   = ["secretsmanager:DescribeSecret", "secretsmanager:GetSecretValue"]
    resources = [aws_rds_cluster.products-aurora.master_user_secret[0].secret_arn]
  }
}

resource "aws_iam_policy" "lambda_function_lambda-search_st_products-search-state" {
  name        = "lambda_function_lambda-search_st_products-search-state"
  description = "Access Policy for lambda-search"
  policy      = data.aws_iam_policy_document.lambda_function_lambda-search_st_products-search-state_doc.json
}

resource "aws_iam_role" "lambda-ingestion_role" {
  name = "lambda-ingestion_role"
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
    Name           = "lambda-ingestion_role"
    State          = "products-search-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "lambda-init-db_role" {
  name = "lambda-init-db_role"
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
    Name           = "lambda-init-db_role"
    State          = "products-search-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "lambda-presign_role" {
  name = "lambda-presign_role"
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
    Name           = "lambda-presign_role"
    State          = "products-search-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "lambda-publisher_role" {
  name = "lambda-publisher_role"
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
    Name           = "lambda-publisher_role"
    State          = "products-search-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "lambda-search_role" {
  name = "lambda-search_role"
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
    Name           = "lambda-search_role"
    State          = "products-search-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role_policy_attachment" "lambda_function_lambda-ingestion_st_products-search-state_attach" {
  policy_arn = aws_iam_policy.lambda_function_lambda-ingestion_st_products-search-state.arn
  role       = aws_iam_role.lambda-ingestion_role.name
}

resource "aws_iam_role_policy_attachment" "lambda_function_lambda-init-db_st_products-search-state_attach" {
  policy_arn = aws_iam_policy.lambda_function_lambda-init-db_st_products-search-state.arn
  role       = aws_iam_role.lambda-init-db_role.name
}

resource "aws_iam_role_policy_attachment" "lambda_function_lambda-presign_st_products-search-state_attach" {
  policy_arn = aws_iam_policy.lambda_function_lambda-presign_st_products-search-state.arn
  role       = aws_iam_role.lambda-presign_role.name
}

resource "aws_iam_role_policy_attachment" "lambda_function_lambda-publisher_st_products-search-state_attach" {
  policy_arn = aws_iam_policy.lambda_function_lambda-publisher_st_products-search-state.arn
  role       = aws_iam_role.lambda-publisher_role.name
}

resource "aws_iam_role_policy_attachment" "lambda_function_lambda-search_st_products-search-state_attach" {
  policy_arn = aws_iam_policy.lambda_function_lambda-search_st_products-search-state.arn
  role       = aws_iam_role.lambda-search_role.name
}

resource "aws_acm_certificate" "hardstore-cert" {
  domain_name       = "hardstore.cloudman.pro"
  key_algorithm     = "RSA_2048"
  region            = "us-east-1"
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
  options {
    certificate_transparency_logging_preference = "ENABLED"
  }
  tags = {
    Name           = "hardstore-cert"
    State          = "products-search-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_acm_certificate_validation" "Validation_hardstore-cert" {
  certificate_arn         = aws_acm_certificate.hardstore-cert.arn
  region                  = "us-east-1"
  validation_record_fqdns = [for record in aws_route53_record.Route53_Record_hardstore-cert_hardstore_cloudman_pro : record.fqdn]
}




### CATEGORY: NETWORK ###

resource "aws_vpc" "products-vpc" {
  cidr_block           = "10.7.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default"
  tags = {
    Name           = "products-vpc"
    State          = "products-search-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "private-a" {
  vpc_id                  = aws_vpc.products-vpc.id
  availability_zone       = "us-west-2a"
  cidr_block              = "10.7.0.0/24"
  map_public_ip_on_launch = false
  tags = {
    Name           = "private-a"
    State          = "products-search-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "private-b" {
  vpc_id                  = aws_vpc.products-vpc.id
  availability_zone       = "us-west-2b"
  cidr_block              = "10.7.1.0/24"
  map_public_ip_on_launch = false
  tags = {
    Name           = "private-b"
    State          = "products-search-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route53_record" "Route53_Record_hardstore-cert_hardstore_cloudman_pro" {
  for_each = {
    for dvo in aws_acm_certificate.hardstore-cert.domain_validation_options : dvo.domain_name => dvo
    if dvo.domain_name == "hardstore.cloudman.pro"
  }
  name            = each.value.resource_record_name
  zone_id         = data.aws_route53_zone.cloudman-zone.zone_id
  allow_overwrite = true
  records         = [each.value.resource_record_value]
  ttl             = 300
  type            = each.value.resource_record_type
}

resource "aws_route53_record" "alias_a_aws_cloudfront_distribution_site-cdn_hardstore_cloudman_pro" {
  name    = "hardstore.cloudman.pro"
  zone_id = data.aws_route53_zone.cloudman-zone.zone_id
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.site-cdn.domain_name
    zone_id                = aws_cloudfront_distribution.site-cdn.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "alias_aaaa_aws_cloudfront_distribution_site-cdn_hardstore_cloudman_pro" {
  name    = "hardstore.cloudman.pro"
  zone_id = data.aws_route53_zone.cloudman-zone.zone_id
  type    = "AAAA"
  alias {
    name                   = aws_cloudfront_distribution.site-cdn.domain_name
    zone_id                = aws_cloudfront_distribution.site-cdn.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_security_group" "rds_cluster_products-aurora_group" {
  name                   = "rds_cluster_products-aurora_group"
  vpc_id                 = aws_vpc.products-vpc.id
  revoke_rules_on_delete = false
  tags = {
    Name           = "rds_cluster_products-aurora_group"
    State          = "products-search-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group_rule" "rule_rds_cluster_products_aurora_group_egress_all_protocols" {
  security_group_id = aws_security_group.rds_cluster_products-aurora_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}

resource "aws_apigatewayv2_api" "products-http-api" {
  name          = "products-http-api"
  description   = "HTTP API de busca e detalhe de produtos"
  protocol_type = "HTTP"
  cors_configuration {
    allow_headers = ["content-type"]
    allow_methods = ["GET", "POST", "OPTIONS"]
    allow_origins = ["*"]
  }
  tags = {
    Name           = "products-http-api"
    State          = "products-search-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_apigatewayv2_integration" "products-integration" {
  api_id                 = aws_apigatewayv2_api.products-http-api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.lambda-publisher.invoke_arn
  payload_format_version = "2.0"
  timeout_milliseconds   = 10000
  depends_on             = [aws_lambda_permission.perm_aws_apigatewayv2_api_products-http-api_to_lambda-publisher]
}

resource "aws_apigatewayv2_integration" "search-integration" {
  api_id                 = aws_apigatewayv2_api.products-http-api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.lambda-search.invoke_arn
  payload_format_version = "2.0"
  timeout_milliseconds   = 29000
  depends_on             = [aws_lambda_permission.perm_aws_apigatewayv2_api_products-http-api_to_lambda-search]
}

resource "aws_apigatewayv2_integration" "upload-integration" {
  api_id                 = aws_apigatewayv2_api.products-http-api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.lambda-presign.invoke_arn
  payload_format_version = "2.0"
  timeout_milliseconds   = 10000
  depends_on             = [aws_lambda_permission.perm_aws_apigatewayv2_api_products-http-api_to_lambda-presign]
}

resource "aws_apigatewayv2_route" "products-route" {
  api_id    = aws_apigatewayv2_api.products-http-api.id
  route_key = "POST /produtos"
  target    = "integrations/${aws_apigatewayv2_integration.products-integration.id}"
}

resource "aws_apigatewayv2_route" "search-route" {
  api_id    = aws_apigatewayv2_api.products-http-api.id
  route_key = "GET /busca"
  target    = "integrations/${aws_apigatewayv2_integration.search-integration.id}"
}

resource "aws_apigatewayv2_route" "upload-route" {
  api_id    = aws_apigatewayv2_api.products-http-api.id
  route_key = "GET /upload-url"
  target    = "integrations/${aws_apigatewayv2_integration.upload-integration.id}"
}

resource "aws_apigatewayv2_stage" "default-stage" {
  api_id      = aws_apigatewayv2_api.products-http-api.id
  name        = "$default"
  auto_deploy = true
  tags = {
    Name           = "default-stage"
    State          = "products-search-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_cloudfront_distribution" "site-cdn" {
  aliases             = ["hardstore.cloudman.pro"]
  comment             = "CDN do site de busca de produtos"
  default_root_object = "index.html"
  enabled             = true
  http_version        = "http2and3"
  is_ipv6_enabled     = true
  price_class         = "PriceClass_All"
  default_cache_behavior {
    cache_policy_id          = data.aws_cloudfront_cache_policy.policy_cachingoptimized.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.policy_cors_s3origin.id
    target_origin_id         = "site-origin"
    allowed_methods          = ["GET", "HEAD", "OPTIONS"]
    cached_methods           = ["GET", "HEAD", "OPTIONS"]
    viewer_protocol_policy   = "redirect-to-https"
  }
  ordered_cache_behavior {
    cache_policy_id          = data.aws_cloudfront_cache_policy.policy_cachingdisabled.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.policy_allviewerexcepthostheader.id
    target_origin_id         = "api-origin"
    allowed_methods          = ["GET", "HEAD", "OPTIONS"]
    cached_methods           = ["GET", "HEAD"]
    path_pattern             = "/busca*"
    viewer_protocol_policy   = "redirect-to-https"
  }
  ordered_cache_behavior {
    cache_policy_id          = data.aws_cloudfront_cache_policy.policy_cachingdisabled.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.policy_allviewerexcepthostheader.id
    target_origin_id         = "api-origin"
    allowed_methods          = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods           = ["GET", "HEAD"]
    path_pattern             = "/produtos*"
    viewer_protocol_policy   = "redirect-to-https"
  }
  ordered_cache_behavior {
    cache_policy_id          = data.aws_cloudfront_cache_policy.policy_cachingdisabled.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.policy_allviewerexcepthostheader.id
    target_origin_id         = "api-origin"
    allowed_methods          = ["GET", "HEAD", "OPTIONS"]
    cached_methods           = ["GET", "HEAD"]
    path_pattern             = "/upload-url*"
    viewer_protocol_policy   = "redirect-to-https"
  }
  origin {
    domain_name                 = aws_s3_bucket.static-site.bucket_regional_domain_name
    origin_access_control_id    = aws_cloudfront_origin_access_control.oac_static-site.id
    origin_id                   = "site-origin"
    response_completion_timeout = 0
  }
  origin {
    domain_name                 = "${aws_apigatewayv2_api.products-http-api.id}.execute-api.${data.aws_region.current.region}.amazonaws.com"
    origin_id                   = "api-origin"
    response_completion_timeout = 0
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
    Name           = "site-cdn"
    State          = "products-search-state"
    Struct8Creator = "Contato Struct"
  }
  viewer_certificate {
    acm_certificate_arn            = aws_acm_certificate_validation.Validation_hardstore-cert.certificate_arn
    cloudfront_default_certificate = false
    minimum_protocol_version       = "TLSv1.2_2021"
    ssl_support_method             = "sni-only"
  }
}

resource "aws_cloudfront_origin_access_control" "oac_static-site" {
  name                              = "oac-static-site"
  description                       = "OAC for static-site"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}




### CATEGORY: STORAGE ###

resource "aws_s3_bucket" "static-site" {
  bucket              = "static-site-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.region}-an"
  bucket_namespace    = "account-regional"
  force_destroy       = true
  object_lock_enabled = false
  tags = {
    Name           = "static-site"
    State          = "products-search-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_s3_bucket_cors_configuration" "static-site_cors" {
  bucket = aws_s3_bucket.static-site.id
  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["PUT", "GET"]
    allowed_origins = ["https://hardstore.cloudman.pro"]
    max_age_seconds = 3000
  }
}

resource "aws_s3_bucket_ownership_controls" "static-site_controls" {
  bucket = aws_s3_bucket.static-site.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

data "aws_iam_policy_document" "aws_s3_bucket_policy_static-site_st_products-search-state_doc" {
  statement {
    sid    = "AllowCloudFrontServicePrincipalReadOnly"
    effect = "Allow"
    principals {
      identifiers = ["cloudfront.amazonaws.com"]
      type        = "Service"
    }
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.static-site.arn}/*"]
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = ["arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${aws_cloudfront_distribution.site-cdn.id}"]
    }
  }
}

resource "aws_s3_bucket_policy" "aws_s3_bucket_policy_static-site_st_products-search-state" {
  bucket = aws_s3_bucket.static-site.id
  policy = data.aws_iam_policy_document.aws_s3_bucket_policy_static-site_st_products-search-state_doc.json
}

resource "aws_s3_bucket_public_access_block" "static-site_block" {
  block_public_acls       = true
  block_public_policy     = true
  bucket                  = aws_s3_bucket.static-site.id
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "static-site_configuration" {
  bucket = aws_s3_bucket.static-site.id
  rule {
    bucket_key_enabled = true
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "static-site_versioning" {
  bucket = aws_s3_bucket.static-site.id
  versioning_configuration {
    mfa_delete = "Disabled"
    status     = "Suspended"
  }
}

resource "aws_s3_object" "site-files" {
  for_each     = fileset("${path.module}/.external_modules/CloudMan/LambdaFiles/produtos-search/site", "**")
  source       = "${path.module}/.external_modules/CloudMan/LambdaFiles/produtos-search/site/${each.value}"
  bucket       = aws_s3_bucket.static-site.bucket
  content_type = lookup({ "html" = "text/html; charset=utf-8", "js" = "text/javascript; charset=utf-8", "css" = "text/css; charset=utf-8", "json" = "application/json", "svg" = "image/svg+xml" }, lower(regex("[^.]*$", each.value)), "application/octet-stream")
  etag         = filemd5("${path.module}/.external_modules/CloudMan/LambdaFiles/produtos-search/site/${each.value}")
  key          = each.value
  tags = {
    Name           = "site-files"
    State          = "products-search-state"
    Struct8Creator = "Contato Struct"
  }
}




### CATEGORY: DATABASE ###

resource "aws_db_subnet_group" "subnet_group_products-aurora" {
  name       = "products-aurora-subnet-group"
  subnet_ids = [aws_subnet.private-a.id, aws_subnet.private-b.id]
  tags = {
    Name           = "subnet_group_products-aurora"
    State          = "products-search-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_rds_cluster" "products-aurora" {
  database_name               = "produtos"
  db_subnet_group_name        = aws_db_subnet_group.subnet_group_products-aurora.name
  apply_immediately           = true
  backup_retention_period     = 7
  cluster_identifier          = "products-aurora"
  copy_tags_to_snapshot       = true
  database_insights_mode      = "standard"
  enable_http_endpoint        = true
  engine                      = "aurora-postgresql"
  manage_master_user_password = true
  master_username             = "dbadmin"
  monitoring_interval         = 0
  network_type                = "IPV4"
  port                        = 5432
  skip_final_snapshot         = true
  storage_encrypted           = true
  vpc_security_group_ids      = [aws_security_group.rds_cluster_products-aurora_group.id]
  serverlessv2_scaling_configuration {
    max_capacity             = 4
    min_capacity             = 0
    seconds_until_auto_pause = 300
  }
  tags = {
    Name           = "products-aurora"
    State          = "products-search-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_rds_cluster_instance" "products-aurora-instance" {
  cluster_identifier    = aws_rds_cluster.products-aurora.id
  copy_tags_to_snapshot = true
  engine                = aws_rds_cluster.products-aurora.engine
  identifier            = "products-aurora-instance"
  instance_class        = "db.serverless"
  promotion_tier        = 1
  tags = {
    Name           = "products-aurora-instance"
    State          = "products-search-state"
    Struct8Creator = "Contato Struct"
  }
}




### CATEGORY: COMPUTE ###

resource "aws_lambda_event_source_mapping" "ingestion-esm" {
  function_name                      = aws_lambda_function.lambda-ingestion.arn
  batch_size                         = 10
  event_source_arn                   = aws_sqs_queue.ingestion-queue.arn
  function_response_types            = ["ReportBatchItemFailures"]
  maximum_batching_window_in_seconds = 5
  tags = {
    Name           = "ingestion-esm"
    State          = "products-search-state"
    Struct8Creator = "Contato Struct"
  }
}

data "archive_file" "archive_CloudMan_lambda-ingestion" {
  output_path = "${path.module}/CloudMan_lambda-ingestion.zip"
  source_dir  = "${path.module}/.external_modules/CloudMan/LambdaFiles/produtos-search/ingestao"
  type        = "zip"
}

resource "aws_lambda_function" "lambda-ingestion" {
  function_name                  = "lambda-ingestion"
  architectures                  = ["arm64"]
  description                    = "Worker de ingestao: grava produto e indexa (tsvector/embeddings) no Aurora via RDS Proxy"
  filename                       = data.archive_file.archive_CloudMan_lambda-ingestion.output_path
  handler                        = "index.handler"
  memory_size                    = 1024
  publish                        = false
  reserved_concurrent_executions = -1
  role                           = aws_iam_role.lambda-ingestion_role.arn
  runtime                        = "nodejs22.x"
  source_code_hash               = data.archive_file.archive_CloudMan_lambda-ingestion.output_base64sha256
  timeout                        = 60
  environment {
    variables = {
    NAME                         = "lambda-ingestion"
    REGION                       = data.aws_region.current.region
    ACCOUNT                      = data.aws_caller_identity.current.account_id
    AWS_RDS_CLUSTER_NAME_0       = aws_rds_cluster.products-aurora.cluster_identifier
    AWS_RDS_CLUSTER_ENGINE_0     = aws_rds_cluster.products-aurora.engine
    AWS_RDS_CLUSTER_ENDPOINT_0   = aws_rds_cluster.products-aurora.endpoint
    AWS_RDS_CLUSTER_PORT_0       = aws_rds_cluster.products-aurora.port
    AWS_RDS_CLUSTER_DB_NAME_0    = coalesce(aws_rds_cluster.products-aurora.database_name, "postgres")
    AWS_RDS_CLUSTER_SECRET_ARN_0 = one(aws_rds_cluster.products-aurora.master_user_secret[*].secret_arn)
    AWS_RDS_CLUSTER_ARN_0        = aws_rds_cluster.products-aurora.arn
    AWS_RDS_CLUSTER_DATA_API_0   = true
  }
  }
  tags = {
    Name           = "lambda-ingestion"
    State          = "products-search-state"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_iam_role_policy_attachment.lambda_function_lambda-ingestion_st_products-search-state_attach]
}

data "archive_file" "archive_CloudMan_lambda-init-db" {
  output_path = "${path.module}/CloudMan_lambda-init-db.zip"
  source_dir  = "${path.module}/.external_modules/CloudMan/LambdaFiles/produtos-search/init-db"
  type        = "zip"
}

resource "aws_lambda_function" "lambda-init-db" {
  function_name                  = "lambda-init-db"
  architectures                  = ["arm64"]
  description                    = "Inicializa o schema e popula produtos de exemplo apos o apply"
  filename                       = data.archive_file.archive_CloudMan_lambda-init-db.output_path
  handler                        = "index.handler"
  memory_size                    = 256
  publish                        = false
  reserved_concurrent_executions = -1
  role                           = aws_iam_role.lambda-init-db_role.arn
  runtime                        = "nodejs22.x"
  source_code_hash               = data.archive_file.archive_CloudMan_lambda-init-db.output_base64sha256
  timeout                        = 60
  environment {
    variables = {
    NAME                         = "lambda-init-db"
    REGION                       = data.aws_region.current.region
    ACCOUNT                      = data.aws_caller_identity.current.account_id
    AWS_RDS_CLUSTER_NAME_0       = aws_rds_cluster.products-aurora.cluster_identifier
    AWS_RDS_CLUSTER_ENGINE_0     = aws_rds_cluster.products-aurora.engine
    AWS_RDS_CLUSTER_ENDPOINT_0   = aws_rds_cluster.products-aurora.endpoint
    AWS_RDS_CLUSTER_PORT_0       = aws_rds_cluster.products-aurora.port
    AWS_RDS_CLUSTER_DB_NAME_0    = coalesce(aws_rds_cluster.products-aurora.database_name, "postgres")
    AWS_RDS_CLUSTER_SECRET_ARN_0 = one(aws_rds_cluster.products-aurora.master_user_secret[*].secret_arn)
    AWS_RDS_CLUSTER_ARN_0        = aws_rds_cluster.products-aurora.arn
    AWS_RDS_CLUSTER_DATA_API_0   = true
  }
  }
  tags = {
    Name           = "lambda-init-db"
    State          = "products-search-state"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_iam_role_policy_attachment.lambda_function_lambda-init-db_st_products-search-state_attach]
}

data "archive_file" "archive_CloudMan_lambda-presign" {
  output_path = "${path.module}/CloudMan_lambda-presign.zip"
  source_dir  = "${path.module}/.external_modules/CloudMan/LambdaFiles/produtos-search/presign"
  type        = "zip"
}

resource "aws_lambda_function" "lambda-presign" {
  function_name                  = "lambda-presign"
  architectures                  = ["arm64"]
  description                    = "Gera presigned PUT para upload de imagem direto no S3"
  filename                       = data.archive_file.archive_CloudMan_lambda-presign.output_path
  handler                        = "index.handler"
  memory_size                    = 256
  publish                        = false
  reserved_concurrent_executions = -1
  role                           = aws_iam_role.lambda-presign_role.arn
  runtime                        = "nodejs22.x"
  source_code_hash               = data.archive_file.archive_CloudMan_lambda-presign.output_base64sha256
  timeout                        = 10
  environment {
    variables = {
    NAME                 = "lambda-presign"
    REGION               = data.aws_region.current.region
    ACCOUNT              = data.aws_caller_identity.current.account_id
    AWS_S3_BUCKET_NAME_0 = "static-site-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.region}-an"
  }
  }
  tags = {
    Name           = "lambda-presign"
    State          = "products-search-state"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_iam_role_policy_attachment.lambda_function_lambda-presign_st_products-search-state_attach]
}

data "archive_file" "archive_CloudMan_lambda-publisher" {
  output_path = "${path.module}/CloudMan_lambda-publisher.zip"
  source_dir  = "${path.module}/.external_modules/CloudMan/LambdaFiles/produtos-search/publisher"
  type        = "zip"
}

resource "aws_lambda_function" "lambda-publisher" {
  function_name                  = "lambda-publisher"
  architectures                  = ["arm64"]
  description                    = "Recebe POST /produtos e publica na SQS para ingestao assincrona"
  filename                       = data.archive_file.archive_CloudMan_lambda-publisher.output_path
  handler                        = "index.handler"
  memory_size                    = 256
  publish                        = false
  reserved_concurrent_executions = -1
  role                           = aws_iam_role.lambda-publisher_role.arn
  runtime                        = "nodejs22.x"
  source_code_hash               = data.archive_file.archive_CloudMan_lambda-publisher.output_base64sha256
  timeout                        = 10
  environment {
    variables = {
    NAME                 = "lambda-publisher"
    REGION               = data.aws_region.current.region
    ACCOUNT              = data.aws_caller_identity.current.account_id
    AWS_SQS_QUEUE_NAME_0 = "ingestion-queue"
  }
  }
  tags = {
    Name           = "lambda-publisher"
    State          = "products-search-state"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_iam_role_policy_attachment.lambda_function_lambda-publisher_st_products-search-state_attach]
}

data "archive_file" "archive_CloudMan_lambda-search" {
  output_path = "${path.module}/CloudMan_lambda-search.zip"
  source_dir  = "${path.module}/.external_modules/CloudMan/LambdaFiles/produtos-search/busca"
  type        = "zip"
}

resource "aws_lambda_function" "lambda-search" {
  function_name                  = "lambda-search"
  architectures                  = ["arm64"]
  description                    = "Endpoint de busca: FTS + pg_trgm no Aurora via RDS Data API"
  filename                       = data.archive_file.archive_CloudMan_lambda-search.output_path
  handler                        = "index.handler"
  memory_size                    = 512
  publish                        = false
  reserved_concurrent_executions = -1
  role                           = aws_iam_role.lambda-search_role.arn
  runtime                        = "nodejs22.x"
  source_code_hash               = data.archive_file.archive_CloudMan_lambda-search.output_base64sha256
  timeout                        = 15
  environment {
    variables = {
    NAME                         = "lambda-search"
    REGION                       = data.aws_region.current.region
    ACCOUNT                      = data.aws_caller_identity.current.account_id
    AWS_RDS_CLUSTER_NAME_0       = aws_rds_cluster.products-aurora.cluster_identifier
    AWS_RDS_CLUSTER_ENGINE_0     = aws_rds_cluster.products-aurora.engine
    AWS_RDS_CLUSTER_ENDPOINT_0   = aws_rds_cluster.products-aurora.endpoint
    AWS_RDS_CLUSTER_PORT_0       = aws_rds_cluster.products-aurora.port
    AWS_RDS_CLUSTER_DB_NAME_0    = coalesce(aws_rds_cluster.products-aurora.database_name, "postgres")
    AWS_RDS_CLUSTER_SECRET_ARN_0 = one(aws_rds_cluster.products-aurora.master_user_secret[*].secret_arn)
    AWS_RDS_CLUSTER_ARN_0        = aws_rds_cluster.products-aurora.arn
    AWS_RDS_CLUSTER_DATA_API_0   = true
  }
  }
  tags = {
    Name           = "lambda-search"
    State          = "products-search-state"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_iam_role_policy_attachment.lambda_function_lambda-search_st_products-search-state_attach]
}

resource "aws_lambda_invocation" "init-db-invocation" {
  function_name = aws_lambda_function.lambda-init-db.function_name
  input         = "{}"
  triggers = {
    rds_cluster = aws_rds_cluster.products-aurora.id
  }
  depends_on = [time_sleep.init-db-invocation_role_propagation]
}

resource "aws_lambda_permission" "perm_aws_apigatewayv2_api_products-http-api_to_lambda-presign" {
  function_name = aws_lambda_function.lambda-presign.function_name
  statement_id  = "perm_aws_apigatewayv2_api_products-http-api_to_lambda-presign"
  principal     = "apigateway.amazonaws.com"
  action        = "lambda:InvokeFunction"
  source_arn    = "${aws_apigatewayv2_api.products-http-api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "perm_aws_apigatewayv2_api_products-http-api_to_lambda-publisher" {
  function_name = aws_lambda_function.lambda-publisher.function_name
  statement_id  = "perm_aws_apigatewayv2_api_products-http-api_to_lambda-publisher"
  principal     = "apigateway.amazonaws.com"
  action        = "lambda:InvokeFunction"
  source_arn    = "${aws_apigatewayv2_api.products-http-api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "perm_aws_apigatewayv2_api_products-http-api_to_lambda-search" {
  function_name = aws_lambda_function.lambda-search.function_name
  statement_id  = "perm_aws_apigatewayv2_api_products-http-api_to_lambda-search"
  principal     = "apigateway.amazonaws.com"
  action        = "lambda:InvokeFunction"
  source_arn    = "${aws_apigatewayv2_api.products-http-api.execution_arn}/*/*"
}




### CATEGORY: INTEGRATION ###

resource "aws_sqs_queue" "ingestion-queue" {
  name                              = "ingestion-queue"
  delay_seconds                     = 0
  fifo_queue                        = false
  kms_data_key_reuse_period_seconds = 300
  max_message_size                  = 262144
  message_retention_seconds         = 1209600
  receive_wait_time_seconds         = 0
  sqs_managed_sse_enabled           = true
  visibility_timeout_seconds        = 360
  tags = {
    Name           = "ingestion-queue"
    State          = "products-search-state"
    Struct8Creator = "Contato Struct"
  }
}




### CATEGORY: MONITORING ###

resource "aws_cloudwatch_log_group" "ingestion-logs" {
  name              = "/aws/lambda/lambda-ingestion"
  log_group_class   = "STANDARD"
  retention_in_days = 14
  skip_destroy      = false
  tags = {
    Name           = "ingestion-logs"
    State          = "products-search-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_cloudwatch_log_group" "init-db-logs" {
  name              = "/aws/lambda/lambda-init-db"
  log_group_class   = "STANDARD"
  retention_in_days = 14
  skip_destroy      = false
  tags = {
    Name           = "init-db-logs"
    State          = "products-search-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_cloudwatch_log_group" "presign-logs" {
  name              = "/aws/lambda/lambda-presign"
  log_group_class   = "STANDARD"
  retention_in_days = 14
  skip_destroy      = false
  tags = {
    Name           = "presign-logs"
    State          = "products-search-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_cloudwatch_log_group" "publisher-logs" {
  name              = "/aws/lambda/lambda-publisher"
  log_group_class   = "STANDARD"
  retention_in_days = 14
  skip_destroy      = false
  tags = {
    Name           = "publisher-logs"
    State          = "products-search-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_cloudwatch_log_group" "search-logs" {
  name              = "/aws/lambda/lambda-search"
  log_group_class   = "STANDARD"
  retention_in_days = 14
  skip_destroy      = false
  tags = {
    Name           = "search-logs"
    State          = "products-search-state"
    Struct8Creator = "Contato Struct"
  }
}




### CATEGORY: MISC ###

resource "time_sleep" "init-db-invocation_role_propagation" {
  create_duration = "30s"
  triggers = {
    policy_attachment = aws_iam_role_policy_attachment.lambda_function_lambda-init-db_st_products-search-state_attach.id
    policy            = aws_iam_policy.lambda_function_lambda-init-db_st_products-search-state.policy
  }
}


