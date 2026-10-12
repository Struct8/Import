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
    key     = "952133486861/produtos-search-state/main.tfstate"
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

data "aws_iam_policy_document" "lambda_function_lambda-busca_st_produtos-search-state_doc" {
  statement {
    sid       = "AllowWriteLogs"
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.busca-logs.arn}:*"]
  }
  statement {
    sid       = "DataApi"
    effect    = "Allow"
    actions   = ["rds-data:BatchExecuteStatement", "rds-data:BeginTransaction", "rds-data:CommitTransaction", "rds-data:ExecuteStatement", "rds-data:RollbackTransaction"]
    resources = [aws_rds_cluster.produtos-aurora.arn]
  }
  statement {
    sid       = "AllowRDSSecretAccessprodutosaurora"
    effect    = "Allow"
    actions   = ["secretsmanager:DescribeSecret", "secretsmanager:GetSecretValue"]
    resources = [aws_rds_cluster.produtos-aurora.master_user_secret[0].secret_arn]
  }
}

resource "aws_iam_policy" "lambda_function_lambda-busca_st_produtos-search-state" {
  name        = "lambda_function_lambda-busca_st_produtos-search-state"
  description = "Access Policy for lambda-busca"
  policy      = data.aws_iam_policy_document.lambda_function_lambda-busca_st_produtos-search-state_doc.json
}

data "aws_iam_policy_document" "lambda_function_lambda-ingestao_st_produtos-search-state_doc" {
  statement {
    sid       = "AllowWriteLogs"
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.ingestao-logs.arn}:*"]
  }
  statement {
    sid       = "DataApi"
    effect    = "Allow"
    actions   = ["rds-data:BatchExecuteStatement", "rds-data:BeginTransaction", "rds-data:CommitTransaction", "rds-data:ExecuteStatement", "rds-data:RollbackTransaction"]
    resources = [aws_rds_cluster.produtos-aurora.arn]
  }
  statement {
    sid       = "AllowRDSSecretAccessprodutosaurora"
    effect    = "Allow"
    actions   = ["secretsmanager:DescribeSecret", "secretsmanager:GetSecretValue"]
    resources = [aws_rds_cluster.produtos-aurora.master_user_secret[0].secret_arn]
  }
  statement {
    sid       = "AllowEventSourceRead"
    effect    = "Allow"
    actions   = ["sqs:DeleteMessage", "sqs:GetQueueAttributes", "sqs:ReceiveMessage", "sqs:SendMessage"]
    resources = [aws_sqs_queue.fila-ingestao.arn]
  }
}

resource "aws_iam_policy" "lambda_function_lambda-ingestao_st_produtos-search-state" {
  name        = "lambda_function_lambda-ingestao_st_produtos-search-state"
  description = "Access Policy for lambda-ingestao"
  policy      = data.aws_iam_policy_document.lambda_function_lambda-ingestao_st_produtos-search-state_doc.json
}

data "aws_iam_policy_document" "lambda_function_lambda-publisher_st_produtos-search-state_doc" {
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
    resources = [aws_sqs_queue.fila-ingestao.arn]
  }
}

resource "aws_iam_policy" "lambda_function_lambda-publisher_st_produtos-search-state" {
  name        = "lambda_function_lambda-publisher_st_produtos-search-state"
  description = "Access Policy for lambda-publisher"
  policy      = data.aws_iam_policy_document.lambda_function_lambda-publisher_st_produtos-search-state_doc.json
}

resource "aws_iam_role" "lambda-busca_role" {
  name = "lambda-busca_role"
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
    Name           = "lambda-busca_role"
    State          = "produtos-search-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "lambda-ingestao_role" {
  name = "lambda-ingestao_role"
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
    Name           = "lambda-ingestao_role"
    State          = "produtos-search-state"
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
    State          = "produtos-search-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role_policy_attachment" "lambda_function_lambda-busca_st_produtos-search-state_attach" {
  policy_arn = aws_iam_policy.lambda_function_lambda-busca_st_produtos-search-state.arn
  role       = aws_iam_role.lambda-busca_role.name
}

resource "aws_iam_role_policy_attachment" "lambda_function_lambda-ingestao_st_produtos-search-state_attach" {
  policy_arn = aws_iam_policy.lambda_function_lambda-ingestao_st_produtos-search-state.arn
  role       = aws_iam_role.lambda-ingestao_role.name
}

resource "aws_iam_role_policy_attachment" "lambda_function_lambda-publisher_st_produtos-search-state_attach" {
  policy_arn = aws_iam_policy.lambda_function_lambda-publisher_st_produtos-search-state.arn
  role       = aws_iam_role.lambda-publisher_role.name
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
    State          = "produtos-search-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_acm_certificate_validation" "Validation_hardstore-cert" {
  certificate_arn         = aws_acm_certificate.hardstore-cert.arn
  region                  = "us-east-1"
  validation_record_fqdns = [for record in aws_route53_record.Route53_Record_hardstore-cert_hardstore_cloudman_pro : record.fqdn]
}




### CATEGORY: NETWORK ###

resource "aws_vpc" "produtos-vpc" {
  cidr_block           = "10.7.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default"
  tags = {
    Name           = "produtos-vpc"
    State          = "produtos-search-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "privada-a" {
  vpc_id                  = aws_vpc.produtos-vpc.id
  availability_zone       = "us-west-2a"
  cidr_block              = "10.7.0.0/24"
  map_public_ip_on_launch = false
  tags = {
    Name           = "privada-a"
    State          = "produtos-search-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "privada-b" {
  vpc_id                  = aws_vpc.produtos-vpc.id
  availability_zone       = "us-west-2b"
  cidr_block              = "10.7.1.0/24"
  map_public_ip_on_launch = false
  tags = {
    Name           = "privada-b"
    State          = "produtos-search-state"
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

resource "aws_security_group" "rds_cluster_produtos-aurora_group" {
  name                   = "rds_cluster_produtos-aurora_group"
  vpc_id                 = aws_vpc.produtos-vpc.id
  revoke_rules_on_delete = false
  tags = {
    Name           = "rds_cluster_produtos-aurora_group"
    State          = "produtos-search-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group_rule" "rule_rds_cluster_produtos_aurora_group_egress_all_protocols" {
  security_group_id = aws_security_group.rds_cluster_produtos-aurora_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}

resource "aws_apigatewayv2_api" "produtos-http-api" {
  name          = "produtos-http-api"
  description   = "HTTP API de busca e detalhe de produtos"
  protocol_type = "HTTP"
  cors_configuration {
    allow_headers = ["content-type"]
    allow_methods = ["GET", "POST", "OPTIONS"]
    allow_origins = ["*"]
  }
  tags = {
    Name           = "produtos-http-api"
    State          = "produtos-search-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_apigatewayv2_integration" "busca-integration" {
  api_id                 = aws_apigatewayv2_api.produtos-http-api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.lambda-busca.invoke_arn
  payload_format_version = "2.0"
  timeout_milliseconds   = 29000
  depends_on             = [aws_lambda_permission.perm_aws_apigatewayv2_api_produtos-http-api_to_lambda-busca]
}

resource "aws_apigatewayv2_integration" "produtos-integration" {
  api_id                 = aws_apigatewayv2_api.produtos-http-api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.lambda-publisher.invoke_arn
  payload_format_version = "2.0"
  timeout_milliseconds   = 10000
  depends_on             = [aws_lambda_permission.perm_aws_apigatewayv2_api_produtos-http-api_to_lambda-publisher]
}

resource "aws_apigatewayv2_route" "busca-route" {
  api_id    = aws_apigatewayv2_api.produtos-http-api.id
  route_key = "GET /busca"
  target    = "integrations/${aws_apigatewayv2_integration.busca-integration.id}"
}

resource "aws_apigatewayv2_route" "produtos-route" {
  api_id    = aws_apigatewayv2_api.produtos-http-api.id
  route_key = "POST /produtos"
  target    = "integrations/${aws_apigatewayv2_integration.produtos-integration.id}"
}

resource "aws_apigatewayv2_stage" "default-stage" {
  api_id      = aws_apigatewayv2_api.produtos-http-api.id
  name        = "$default"
  auto_deploy = true
  tags = {
    Name           = "default-stage"
    State          = "produtos-search-state"
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
  origin {
    domain_name                 = aws_s3_bucket.site-estatico.bucket_regional_domain_name
    origin_access_control_id    = aws_cloudfront_origin_access_control.oac_site-estatico.id
    origin_id                   = "site-origin"
    response_completion_timeout = 0
  }
  origin {
    domain_name                 = "${aws_apigatewayv2_api.produtos-http-api.id}.execute-api.${data.aws_region.current.region}.amazonaws.com"
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
    State          = "produtos-search-state"
    Struct8Creator = "Contato Struct"
  }
  viewer_certificate {
    acm_certificate_arn            = aws_acm_certificate_validation.Validation_hardstore-cert.certificate_arn
    cloudfront_default_certificate = false
    minimum_protocol_version       = "TLSv1.2_2021"
    ssl_support_method             = "sni-only"
  }
}

resource "aws_cloudfront_origin_access_control" "oac_site-estatico" {
  name                              = "oac-site-estatico"
  description                       = "OAC for site-estatico"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}




### CATEGORY: STORAGE ###

resource "aws_s3_bucket" "site-estatico" {
  bucket              = "site-estatico-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.region}-an"
  bucket_namespace    = "account-regional"
  force_destroy       = true
  object_lock_enabled = false
  tags = {
    Name           = "site-estatico"
    State          = "produtos-search-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_s3_bucket_ownership_controls" "site-estatico_controls" {
  bucket = aws_s3_bucket.site-estatico.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

data "aws_iam_policy_document" "aws_s3_bucket_policy_site-estatico_st_produtos-search-state_doc" {
  statement {
    sid    = "AllowCloudFrontServicePrincipalReadOnly"
    effect = "Allow"
    principals {
      identifiers = ["cloudfront.amazonaws.com"]
      type        = "Service"
    }
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.site-estatico.arn}/*"]
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = ["arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${aws_cloudfront_distribution.site-cdn.id}"]
    }
  }
}

resource "aws_s3_bucket_policy" "aws_s3_bucket_policy_site-estatico_st_produtos-search-state" {
  bucket = aws_s3_bucket.site-estatico.id
  policy = data.aws_iam_policy_document.aws_s3_bucket_policy_site-estatico_st_produtos-search-state_doc.json
}

resource "aws_s3_bucket_public_access_block" "site-estatico_block" {
  block_public_acls       = true
  block_public_policy     = true
  bucket                  = aws_s3_bucket.site-estatico.id
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "site-estatico_configuration" {
  bucket = aws_s3_bucket.site-estatico.id
  rule {
    bucket_key_enabled = true
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "site-estatico_versioning" {
  bucket = aws_s3_bucket.site-estatico.id
  versioning_configuration {
    mfa_delete = "Disabled"
    status     = "Suspended"
  }
}

resource "aws_s3_object" "site-files" {
  for_each     = fileset("${path.module}/.external_modules/CloudMan/LambdaFiles/produtos-search/site", "**")
  source       = "${path.module}/.external_modules/CloudMan/LambdaFiles/produtos-search/site/${each.value}"
  bucket       = aws_s3_bucket.site-estatico.bucket
  content_type = lookup({ "html" = "text/html; charset=utf-8", "js" = "text/javascript; charset=utf-8", "css" = "text/css; charset=utf-8", "json" = "application/json", "svg" = "image/svg+xml" }, lower(regex("[^.]*$", each.value)), "application/octet-stream")
  etag         = filemd5("${path.module}/.external_modules/CloudMan/LambdaFiles/produtos-search/site/${each.value}")
  key          = each.value
  tags = {
    Name           = "site-files"
    State          = "produtos-search-state"
    Struct8Creator = "Contato Struct"
  }
}




### CATEGORY: DATABASE ###

resource "aws_db_subnet_group" "subnet_group_produtos-aurora" {
  name       = "produtos-aurora-subnet-group"
  subnet_ids = [aws_subnet.privada-a.id, aws_subnet.privada-b.id]
  tags = {
    Name           = "subnet_group_produtos-aurora"
    State          = "produtos-search-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_rds_cluster" "produtos-aurora" {
  database_name               = "produtos"
  db_subnet_group_name        = aws_db_subnet_group.subnet_group_produtos-aurora.name
  apply_immediately           = true
  backup_retention_period     = 7
  cluster_identifier          = "produtos-aurora"
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
  vpc_security_group_ids      = [aws_security_group.rds_cluster_produtos-aurora_group.id]
  serverlessv2_scaling_configuration {
    max_capacity             = 4
    min_capacity             = 0
    seconds_until_auto_pause = 300
  }
  tags = {
    Name           = "produtos-aurora"
    State          = "produtos-search-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_rds_cluster_instance" "produtos-aurora-instance" {
  cluster_identifier    = aws_rds_cluster.produtos-aurora.id
  copy_tags_to_snapshot = true
  engine                = aws_rds_cluster.produtos-aurora.engine
  identifier            = "produtos-aurora-instance"
  instance_class        = "db.serverless"
  promotion_tier        = 1
  tags = {
    Name           = "produtos-aurora-instance"
    State          = "produtos-search-state"
    Struct8Creator = "Contato Struct"
  }
}




### CATEGORY: COMPUTE ###

resource "aws_lambda_event_source_mapping" "ingestao-esm" {
  function_name                      = aws_lambda_function.lambda-ingestao.arn
  batch_size                         = 10
  event_source_arn                   = aws_sqs_queue.fila-ingestao.arn
  function_response_types            = ["ReportBatchItemFailures"]
  maximum_batching_window_in_seconds = 5
  tags = {
    Name           = "ingestao-esm"
    State          = "produtos-search-state"
    Struct8Creator = "Contato Struct"
  }
}

data "archive_file" "archive_CloudMan_lambda-busca" {
  output_path = "${path.module}/CloudMan_lambda-busca.zip"
  source_dir  = "${path.module}/.external_modules/CloudMan/LambdaFiles/produtos-search/busca"
  type        = "zip"
}

resource "aws_lambda_function" "lambda-busca" {
  function_name                  = "lambda-busca"
  architectures                  = ["arm64"]
  description                    = "Endpoint de busca: FTS + pg_trgm no Aurora via RDS Data API"
  filename                       = data.archive_file.archive_CloudMan_lambda-busca.output_path
  handler                        = "index.handler"
  memory_size                    = 512
  publish                        = false
  reserved_concurrent_executions = -1
  role                           = aws_iam_role.lambda-busca_role.arn
  runtime                        = "nodejs22.x"
  source_code_hash               = data.archive_file.archive_CloudMan_lambda-busca.output_base64sha256
  timeout                        = 15
  environment {
    variables = {
    NAME                         = "lambda-busca"
    REGION                       = data.aws_region.current.region
    ACCOUNT                      = data.aws_caller_identity.current.account_id
    AWS_RDS_CLUSTER_NAME_0       = aws_rds_cluster.produtos-aurora.cluster_identifier
    AWS_RDS_CLUSTER_ENGINE_0     = aws_rds_cluster.produtos-aurora.engine
    AWS_RDS_CLUSTER_ENDPOINT_0   = aws_rds_cluster.produtos-aurora.endpoint
    AWS_RDS_CLUSTER_PORT_0       = aws_rds_cluster.produtos-aurora.port
    AWS_RDS_CLUSTER_DB_NAME_0    = coalesce(aws_rds_cluster.produtos-aurora.database_name, "postgres")
    AWS_RDS_CLUSTER_SECRET_ARN_0 = one(aws_rds_cluster.produtos-aurora.master_user_secret[*].secret_arn)
    AWS_RDS_CLUSTER_ARN_0        = aws_rds_cluster.produtos-aurora.arn
    AWS_RDS_CLUSTER_DATA_API_0   = true
  }
  }
  tags = {
    Name           = "lambda-busca"
    State          = "produtos-search-state"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_iam_role_policy_attachment.lambda_function_lambda-busca_st_produtos-search-state_attach]
}

data "archive_file" "archive_CloudMan_lambda-ingestao" {
  output_path = "${path.module}/CloudMan_lambda-ingestao.zip"
  source_dir  = "${path.module}/.external_modules/CloudMan/LambdaFiles/produtos-search/ingestao"
  type        = "zip"
}

resource "aws_lambda_function" "lambda-ingestao" {
  function_name                  = "lambda-ingestao"
  architectures                  = ["arm64"]
  description                    = "Worker de ingestao: grava produto e indexa (tsvector/embeddings) no Aurora via RDS Proxy"
  filename                       = data.archive_file.archive_CloudMan_lambda-ingestao.output_path
  handler                        = "index.handler"
  memory_size                    = 1024
  publish                        = false
  reserved_concurrent_executions = -1
  role                           = aws_iam_role.lambda-ingestao_role.arn
  runtime                        = "nodejs22.x"
  source_code_hash               = data.archive_file.archive_CloudMan_lambda-ingestao.output_base64sha256
  timeout                        = 60
  environment {
    variables = {
    NAME                         = "lambda-ingestao"
    REGION                       = data.aws_region.current.region
    ACCOUNT                      = data.aws_caller_identity.current.account_id
    AWS_SQS_QUEUE_NAME_0         = "fila-ingestao"
    AWS_RDS_CLUSTER_NAME_0       = aws_rds_cluster.produtos-aurora.cluster_identifier
    AWS_RDS_CLUSTER_ENGINE_0     = aws_rds_cluster.produtos-aurora.engine
    AWS_RDS_CLUSTER_ENDPOINT_0   = aws_rds_cluster.produtos-aurora.endpoint
    AWS_RDS_CLUSTER_PORT_0       = aws_rds_cluster.produtos-aurora.port
    AWS_RDS_CLUSTER_DB_NAME_0    = coalesce(aws_rds_cluster.produtos-aurora.database_name, "postgres")
    AWS_RDS_CLUSTER_SECRET_ARN_0 = one(aws_rds_cluster.produtos-aurora.master_user_secret[*].secret_arn)
    AWS_RDS_CLUSTER_ARN_0        = aws_rds_cluster.produtos-aurora.arn
    AWS_RDS_CLUSTER_DATA_API_0   = true
  }
  }
  tags = {
    Name           = "lambda-ingestao"
    State          = "produtos-search-state"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_iam_role_policy_attachment.lambda_function_lambda-ingestao_st_produtos-search-state_attach]
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
    AWS_SQS_QUEUE_NAME_0 = "fila-ingestao"
  }
  }
  tags = {
    Name           = "lambda-publisher"
    State          = "produtos-search-state"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_iam_role_policy_attachment.lambda_function_lambda-publisher_st_produtos-search-state_attach]
}

resource "aws_lambda_permission" "perm_aws_apigatewayv2_api_produtos-http-api_to_lambda-busca" {
  function_name = aws_lambda_function.lambda-busca.function_name
  statement_id  = "perm_aws_apigatewayv2_api_produtos-http-api_to_lambda-busca"
  principal     = "apigateway.amazonaws.com"
  action        = "lambda:InvokeFunction"
  source_arn    = "${aws_apigatewayv2_api.produtos-http-api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "perm_aws_apigatewayv2_api_produtos-http-api_to_lambda-publisher" {
  function_name = aws_lambda_function.lambda-publisher.function_name
  statement_id  = "perm_aws_apigatewayv2_api_produtos-http-api_to_lambda-publisher"
  principal     = "apigateway.amazonaws.com"
  action        = "lambda:InvokeFunction"
  source_arn    = "${aws_apigatewayv2_api.produtos-http-api.execution_arn}/*/*"
}




### CATEGORY: INTEGRATION ###

resource "aws_sqs_queue" "fila-ingestao" {
  name                              = "fila-ingestao"
  delay_seconds                     = 0
  fifo_queue                        = false
  kms_data_key_reuse_period_seconds = 300
  max_message_size                  = 262144
  message_retention_seconds         = 1209600
  receive_wait_time_seconds         = 0
  sqs_managed_sse_enabled           = true
  visibility_timeout_seconds        = 360
  tags = {
    Name           = "fila-ingestao"
    State          = "produtos-search-state"
    Struct8Creator = "Contato Struct"
  }
}




### CATEGORY: MONITORING ###

resource "aws_cloudwatch_log_group" "busca-logs" {
  name              = "/aws/lambda/lambda-busca"
  log_group_class   = "STANDARD"
  retention_in_days = 14
  skip_destroy      = false
  tags = {
    Name           = "busca-logs"
    State          = "produtos-search-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_cloudwatch_log_group" "ingestao-logs" {
  name              = "/aws/lambda/lambda-ingestao"
  log_group_class   = "STANDARD"
  retention_in_days = 14
  skip_destroy      = false
  tags = {
    Name           = "ingestao-logs"
    State          = "produtos-search-state"
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
    State          = "produtos-search-state"
    Struct8Creator = "Contato Struct"
  }
}


