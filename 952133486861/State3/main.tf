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
    key     = "952133486861/State3/main.tfstate"
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

data "aws_cloudfront_cache_policy" "policy_cachingoptimized" {
  name = "Managed-CachingOptimized"
}

data "aws_cloudfront_cache_policy" "policy_cachingdisabled" {
  name = "Managed-CachingDisabled"
}




### RENAMES ###

moved {
  from = aws_ssm_parameter.CloudFrontOutputs
  to   = aws_ssm_parameter.CloudFrontOutputs1
}

moved {
  from = aws_lambda_function.api-regular-nonedge
  to   = aws_lambda_function.api-regular-nonedge1
}

moved {
  from = aws_cloudfrontkeyvaluestore_key.banner
  to   = aws_cloudfrontkeyvaluestore_key.banner1
}

moved {
  from = aws_cloudfront_cache_policy.cache-validation
  to   = aws_cloudfront_cache_policy.cache-validation1
}

moved {
  from = aws_cloudfront_field_level_encryption_config.card-encryption
  to   = aws_cloudfront_field_level_encryption_config.card-encryption1
}

moved {
  from = aws_cloudfront_field_level_encryption_profile.card-profile
  to   = aws_cloudfront_field_level_encryption_profile.card-profile1
}

moved {
  from = aws_cloudfront_distribution.cdn-open
  to   = aws_cloudfront_distribution.cdn-open1
}

moved {
  from = aws_cloudfront_distribution.cdn-protected
  to   = aws_cloudfront_distribution.cdn-protected1
}

moved {
  from = aws_ssm_parameter.cf-signing-private-key
  to   = aws_ssm_parameter.cf-signing-private-key1
}

moved {
  from = aws_lambda_function.edge-abtest-viewer-response
  to   = aws_lambda_function.edge-abtest-viewer-response1
}

moved {
  from = aws_lambda_function.edge-auth-viewer-request
  to   = aws_lambda_function.edge-auth-viewer-request1
}

moved {
  from = aws_lambda_function.edge-rewrite-origin-request
  to   = aws_lambda_function.edge-rewrite-origin-request1
}

moved {
  from = aws_lambda_function.edge-security-headers-origin-response
  to   = aws_lambda_function.edge-security-headers-origin-response1
}

moved {
  from = aws_cloudfront_response_headers_policy.headers-validation
  to   = aws_cloudfront_response_headers_policy.headers-validation1
}

moved {
  from = aws_apigatewayv2_api.http-api-regular
  to   = aws_apigatewayv2_api.http-api-regular1
}

moved {
  from = aws_s3_object.img-private-1
  to   = aws_s3_object.img-private-2
}

moved {
  from = aws_s3_object.img-public-1
  to   = aws_s3_object.img-public-2
}

moved {
  from = aws_s3_object.index-html1
  to   = aws_s3_object.index-html2
}

moved {
  from = aws_apigatewayv2_integration.integration-lambda-regular
  to   = aws_apigatewayv2_integration.integration-lambda-regular1
}

moved {
  from = aws_cloudfront_key_value_store.kvs-validation
  to   = aws_cloudfront_key_value_store.kvs-validation1
}

moved {
  from = aws_s3_object.lab-app-js
  to   = aws_s3_object.lab-app-js1
}

moved {
  from = aws_s3_object.lab-index-html
  to   = aws_s3_object.lab-index-html1
}

moved {
  from = aws_s3_object.lab-styles-css
  to   = aws_s3_object.lab-styles-css1
}

moved {
  from = aws_cloudwatch_log_group.log-api-regular
  to   = aws_cloudwatch_log_group.log-api-regular1
}

moved {
  from = aws_cloudwatch_log_group.log-edge-abtest
  to   = aws_cloudwatch_log_group.log-edge-abtest1
}

moved {
  from = aws_cloudwatch_log_group.log-edge-auth
  to   = aws_cloudwatch_log_group.log-edge-auth1
}

moved {
  from = aws_cloudwatch_log_group.log-edge-headers
  to   = aws_cloudwatch_log_group.log-edge-headers1
}

moved {
  from = aws_cloudwatch_log_group.log-edge-rewrite
  to   = aws_cloudwatch_log_group.log-edge-rewrite1
}

moved {
  from = aws_s3_bucket.origin-cf-validation
  to   = aws_s3_bucket.origin-cf-validation1
}

moved {
  from = aws_cloudfront_origin_request_policy.origin-request-validation
  to   = aws_cloudfront_origin_request_policy.origin-request-validation1
}

moved {
  from = aws_s3_object.premium-secret-html
  to   = aws_s3_object.premium-secret-html1
}

moved {
  from = aws_apigatewayv2_route.route-api-proxy
  to   = aws_apigatewayv2_route.route-api-proxy1
}

moved {
  from = aws_cloudfront_public_key.signing-key-cookies
  to   = aws_cloudfront_public_key.signing-key-cookies1
}

moved {
  from = aws_cloudfront_public_key.signing-key
  to   = aws_cloudfront_public_key.signing-key1
}

moved {
  from = aws_apigatewayv2_stage.stage-default
  to   = aws_apigatewayv2_stage.stage-default1
}

moved {
  from = aws_cloudfront_key_group.subscribers-group-cookies
  to   = aws_cloudfront_key_group.subscribers-group-cookies1
}

moved {
  from = aws_cloudfront_key_group.subscribers-group
  to   = aws_cloudfront_key_group.subscribers-group1
}

moved {
  from = aws_cloudfront_function.viewer-request-kvs
  to   = aws_cloudfront_function.viewer-request-kvs1
}




### CATEGORY: IAM ###

resource "aws_iam_policy" "api-regular-logs" {
  name        = "api-regular-logs"
  description = "Access Policy api-regular-logs"
  policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": [
        "${aws_cloudwatch_log_group.log-api-regular1.arn}:*"
      ],
      "Sid": "AllowLogapiregular1"
    }
  ]
})
}

resource "aws_iam_policy" "edge-abtest-logs" {
  name        = "edge-abtest-logs"
  description = "Access Policy edge-abtest-logs"
  policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": [
        "${aws_cloudwatch_log_group.log-edge-abtest1.arn}:*"
      ],
      "Sid": "AllowLogedgeabtest1"
    }
  ]
})
}

resource "aws_iam_policy" "edge-auth-logs" {
  name        = "edge-auth-logs"
  description = "Access Policy edge-auth-logs"
  policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": [
        "${aws_cloudwatch_log_group.log-edge-auth1.arn}:*"
      ],
      "Sid": "AllowLogedgeauth1"
    }
  ]
})
}

resource "aws_iam_policy" "edge-headers-logs" {
  name        = "edge-headers-logs"
  description = "Access Policy edge-headers-logs"
  policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": [
        "${aws_cloudwatch_log_group.log-edge-headers1.arn}:*"
      ],
      "Sid": "AllowLogedgeheaders1"
    }
  ]
})
}

resource "aws_iam_policy" "edge-rewrite-logs" {
  name        = "edge-rewrite-logs"
  description = "Access Policy edge-rewrite-logs"
  policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": [
        "${aws_cloudwatch_log_group.log-edge-rewrite1.arn}:*"
      ],
      "Sid": "AllowLogedgerewrite1"
    }
  ]
})
}

data "aws_iam_policy_document" "lambda_function_api-regular-nonedge1_st_State3_doc" {
  statement {
    sid       = "AllowReadParam"
    effect    = "Allow"
    actions   = ["ssm:GetParameter"]
    resources = [aws_ssm_parameter.CloudFrontOutputs1.arn]
  }
  statement {
    sid       = "AllowReadParam1"
    effect    = "Allow"
    actions   = ["ssm:GetParameter"]
    resources = [aws_ssm_parameter.cf-signing-private-key1.arn]
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

resource "aws_iam_policy" "lambda_function_api-regular-nonedge1_st_State3" {
  name        = "lambda_function_api-regular-nonedge1_st_State3"
  description = "Access Policy for api-regular-nonedge1"
  policy      = data.aws_iam_policy_document.lambda_function_api-regular-nonedge1_st_State3_doc.json
}

resource "aws_iam_role" "api-regular-nonedge1_role" {
  name = "api-regular-nonedge1_role"
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
    Name           = "api-regular-nonedge1_role"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "edge-abtest-viewer-response1_role" {
  name = "edge-abtest-viewer-response1_role"
  assume_role_policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": ["lambda.amazonaws.com", "edgelambda.amazonaws.com"]
      }
    }
  ]
})
  force_detach_policies = false
  max_session_duration  = 3600
  path                  = "/"
  tags = {
    Name           = "edge-abtest-viewer-response1_role"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "edge-auth-viewer-request1_role" {
  name = "edge-auth-viewer-request1_role"
  assume_role_policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": ["lambda.amazonaws.com", "edgelambda.amazonaws.com"]
      }
    }
  ]
})
  force_detach_policies = false
  max_session_duration  = 3600
  path                  = "/"
  tags = {
    Name           = "edge-auth-viewer-request1_role"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "edge-rewrite-origin-request1_role" {
  name = "edge-rewrite-origin-request1_role"
  assume_role_policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": ["lambda.amazonaws.com", "edgelambda.amazonaws.com"]
      }
    }
  ]
})
  force_detach_policies = false
  max_session_duration  = 3600
  path                  = "/"
  tags = {
    Name           = "edge-rewrite-origin-request1_role"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "edge-security-headers-origin-response1_role" {
  name = "edge-security-headers-origin-response1_role"
  assume_role_policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": ["lambda.amazonaws.com", "edgelambda.amazonaws.com"]
      }
    }
  ]
})
  force_detach_policies = false
  max_session_duration  = 3600
  path                  = "/"
  tags = {
    Name           = "edge-security-headers-origin-response1_role"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role_policy_attachment" "api-regular-logs_attach_api-regular-nonedge1_role" {
  policy_arn = aws_iam_policy.api-regular-logs.arn
  role       = aws_iam_role.api-regular-nonedge1_role.name
}

resource "aws_iam_role_policy_attachment" "edge-abtest-logs_attach_edge-abtest-viewer-response1_role" {
  policy_arn = aws_iam_policy.edge-abtest-logs.arn
  role       = aws_iam_role.edge-abtest-viewer-response1_role.name
}

resource "aws_iam_role_policy_attachment" "edge-auth-logs_attach_edge-auth-viewer-request1_role" {
  policy_arn = aws_iam_policy.edge-auth-logs.arn
  role       = aws_iam_role.edge-auth-viewer-request1_role.name
}

resource "aws_iam_role_policy_attachment" "edge-headers-logs_attach_edge-security-headers-origin-response1_role" {
  policy_arn = aws_iam_policy.edge-headers-logs.arn
  role       = aws_iam_role.edge-security-headers-origin-response1_role.name
}

resource "aws_iam_role_policy_attachment" "edge-rewrite-logs_attach_edge-rewrite-origin-request1_role" {
  policy_arn = aws_iam_policy.edge-rewrite-logs.arn
  role       = aws_iam_role.edge-rewrite-origin-request1_role.name
}

resource "aws_iam_role_policy_attachment" "lambda_function_api-regular-nonedge1_st_State3_attach" {
  policy_arn = aws_iam_policy.lambda_function_api-regular-nonedge1_st_State3.arn
  role       = aws_iam_role.api-regular-nonedge1_role.name
}




### CATEGORY: NETWORK ###

resource "aws_apigatewayv2_api" "http-api-regular1" {
  name          = "http-api-regular1"
  description   = "HTTP API v2 exposed via CloudFront under /api. AWS_PROXY integration with the regular Lambda; catch-all proxy route on the default stage with auto_deploy."
  protocol_type = "HTTP"
  tags = {
    Name           = "http-api-regular1"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_apigatewayv2_integration" "integration-lambda-regular1" {
  api_id                 = aws_apigatewayv2_api.http-api-regular1.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.api-regular-nonedge1.invoke_arn
  payload_format_version = "2.0"
  timeout_milliseconds   = 30000
  depends_on             = [aws_lambda_permission.perm_aws_apigatewayv2_api_http-api-regular1_to_api-regular-nonedge1]
}

resource "aws_apigatewayv2_route" "route-api-proxy1" {
  api_id    = aws_apigatewayv2_api.http-api-regular1.id
  route_key = "ANY /api/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.integration-lambda-regular1.id}"
}

resource "aws_apigatewayv2_stage" "stage-default1" {
  api_id      = aws_apigatewayv2_api.http-api-regular1.id
  name        = "$default"
  auto_deploy = true
  tags = {
    Name           = "stage-default1"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_cloudfront_cache_policy" "cache-validation1" {
  name    = "cache-validation1"
  comment = "Cache policy propria, para validar o fio contra a managed"
  min_ttl = 1
  parameters_in_cache_key_and_forwarded_to_origin {
    enable_accept_encoding_brotli = true
    enable_accept_encoding_gzip   = true
    cookies_config {
      cookie_behavior = "none"
    }
    headers_config {
      header_behavior = "none"
    }
    query_strings_config {
      query_string_behavior = "none"
    }
  }
}

resource "aws_cloudfront_distribution" "cdn-open1" {
  comment             = "Open CDN (no auth): signed-URL base, no edge functions. Cache policies + CloudFront Function backed by KVS."
  default_root_object = "index.html"
  enabled             = true
  http_version        = "http2and3"
  is_ipv6_enabled     = true
  price_class         = "PriceClass_All"
  default_cache_behavior {
    cache_policy_id        = data.aws_cloudfront_cache_policy.policy_cachingoptimized.id
    target_origin_id       = "origin_origin-open1"
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    viewer_protocol_policy = "redirect-to-https"
  }
  ordered_cache_behavior {
    cache_policy_id            = aws_cloudfront_cache_policy.cache-validation1.id
    origin_request_policy_id   = aws_cloudfront_origin_request_policy.origin-request-validation1.id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.headers-validation1.id
    target_origin_id           = "origin_origin-open1"
    allowed_methods            = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods             = ["GET", "HEAD", "OPTIONS"]
    path_pattern               = "/route-api1/*"
    viewer_protocol_policy     = "redirect-to-https"
    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.viewer-request-kvs1.arn
    }
  }
  origin {
    domain_name              = aws_s3_bucket.origin-cf-validation1.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.oac_origin-cf-validation1.id
    origin_id                = "origin_origin-open1"
  }
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  tags = {
    Name           = "cdn-open1"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

resource "aws_cloudfront_distribution" "cdn-protected1" {
  comment             = "Protected CDN: lab + public/private galleries, /api, 4 Lambda@Edge, signed cookies/URLs, FLE."
  default_root_object = "index.html"
  enabled             = true
  http_version        = "http2and3"
  is_ipv6_enabled     = true
  price_class         = "PriceClass_All"
  default_cache_behavior {
    cache_policy_id        = data.aws_cloudfront_cache_policy.policy_cachingoptimized.id
    target_origin_id       = "origin_origin-protected1"
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    viewer_protocol_policy = "redirect-to-https"
    lambda_function_association {
      event_type = "origin-request"
      lambda_arn = aws_lambda_function.edge-rewrite-origin-request1.qualified_arn
    }
    lambda_function_association {
      event_type = "origin-response"
      lambda_arn = aws_lambda_function.edge-security-headers-origin-response1.qualified_arn
    }
    lambda_function_association {
      event_type = "viewer-response"
      lambda_arn = aws_lambda_function.edge-abtest-viewer-response1.qualified_arn
    }
    lambda_function_association {
      event_type = "viewer-request"
      lambda_arn = aws_lambda_function.edge-auth-viewer-request1.qualified_arn
    }
  }
  ordered_cache_behavior {
    cache_policy_id        = data.aws_cloudfront_cache_policy.policy_cachingdisabled.id
    target_origin_id       = "origin_origin-api-gateway1"
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    path_pattern           = "/api1/*"
    viewer_protocol_policy = "redirect-to-https"
  }
  ordered_cache_behavior {
    cache_policy_id        = data.aws_cloudfront_cache_policy.policy_cachingdisabled.id
    target_origin_id       = "origin_origin-protected1"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    path_pattern           = "/lab1/*"
    viewer_protocol_policy = "redirect-to-https"
    lambda_function_association {
      event_type = "origin-request"
      lambda_arn = aws_lambda_function.edge-rewrite-origin-request1.qualified_arn
    }
    lambda_function_association {
      event_type = "origin-response"
      lambda_arn = aws_lambda_function.edge-security-headers-origin-response1.qualified_arn
    }
    lambda_function_association {
      event_type = "viewer-response"
      lambda_arn = aws_lambda_function.edge-abtest-viewer-response1.qualified_arn
    }
  }
  ordered_cache_behavior {
    cache_policy_id        = data.aws_cloudfront_cache_policy.policy_cachingoptimized.id
    target_origin_id       = "origin_origin-protected1"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    path_pattern           = "/premium1/*"
    trusted_key_groups     = [aws_cloudfront_key_group.subscribers-group1.id]
    viewer_protocol_policy = "redirect-to-https"
  }
  ordered_cache_behavior {
    cache_policy_id        = data.aws_cloudfront_cache_policy.policy_cachingoptimized.id
    target_origin_id       = "origin_origin-protected1"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    path_pattern           = "/public1/*"
    viewer_protocol_policy = "redirect-to-https"
  }
  ordered_cache_behavior {
    cache_policy_id        = data.aws_cloudfront_cache_policy.policy_cachingoptimized.id
    target_origin_id       = "origin_origin-protected1"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    path_pattern           = "/private1/*"
    trusted_key_groups     = [aws_cloudfront_key_group.subscribers-group-cookies1.id]
    viewer_protocol_policy = "redirect-to-https"
  }
  origin {
    domain_name              = aws_s3_bucket.origin-cf-validation1.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.oac_origin-cf-validation1.id
    origin_id                = "origin_origin-protected1"
  }
  origin {
    domain_name = "${aws_apigatewayv2_api.http-api-regular1.id}.execute-api.${data.aws_region.current.region}.amazonaws.com"
    origin_id   = "origin_origin-api-gateway1"
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
    Name           = "cdn-protected1"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

resource "aws_cloudfront_field_level_encryption_config" "card-encryption1" {
  content_type_profile_config {
    forward_when_content_type_is_unknown = true
    content_type_profiles {
      items {
        profile_id   = aws_cloudfront_field_level_encryption_profile.card-profile1.id
        content_type = "application/x-www-form-urlencoded"
        format       = "URLEncoded"
      }
    }
  }
  query_arg_profile_config {
    forward_when_query_arg_profile_is_unknown = true
  }
}

resource "aws_cloudfront_field_level_encryption_profile" "card-profile1" {
  name = "card-profile1"
  encryption_entities {
    items {
      provider_id   = "cloudman-fle-provider"
      public_key_id = aws_cloudfront_public_key.signing-key1.id
      field_patterns {
        items = ["credit-card-*"]
      }
    }
  }
}

resource "aws_cloudfront_function" "viewer-request-kvs1" {
  name = "viewer-request-kvs1"
  code = <<-EOF
import cf from 'cloudfront';
const kvs = cf.kvs();

async function handler(event) {
    const request = event.request;
    let banner = 'sem-kvs';
    try {
        banner = await kvs.get('banner');
    } catch (e) {
        banner = 'chave-ausente';
    }
    request.headers['x-struct8-banner'] = { value: banner };
    return request;
}
EOF
  comment                      = "Le uma chave do Key Value Store e devolve no header"
  key_value_store_associations = [aws_cloudfront_key_value_store.kvs-validation1.arn]
  publish                      = true
  runtime                      = "cloudfront-js-2.0"
  tags = {
    Name           = "viewer-request-kvs1"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_cloudfront_key_group" "subscribers-group-cookies1" {
  name  = "subscribers-group-cookies1"
  items = [aws_cloudfront_public_key.signing-key-cookies1.id]
}

resource "aws_cloudfront_key_group" "subscribers-group1" {
  name  = "subscribers-group1"
  items = [aws_cloudfront_public_key.signing-key1.id]
}

resource "aws_cloudfront_key_value_store" "kvs-validation1" {
  name = "kvs-validation1"
}

resource "aws_cloudfront_origin_access_control" "oac_origin-cf-validation1" {
  name                              = "oac-origin-cf-validation1"
  description                       = "OAC for origin-cf-validation1"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_origin_request_policy" "origin-request-validation1" {
  name = "origin-request-validation1"
  cookies_config {
    cookie_behavior = "none"
  }
  headers_config {
    header_behavior = "none"
  }
  query_strings_config {
    query_string_behavior = "none"
  }
}

resource "aws_cloudfront_public_key" "signing-key-cookies1" {
  name    = "signing-key-cookies1"
  comment = "Signed-cookie public key for /private; its id is the cookie Key-Pair-Id."
  encoded_key = <<-EOF
-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAqaq7WRyC/XwxVPT1STyZ
6jWUSz9AALkDxQD8xb6eV+69Udc+X3VR5IM1Tg6i3Q24b7Jq0P2Xzn7oJ7mphrW/
XWc6pDqW9atOKxt9y1g02wmedhlHrgTToqeb9oAikGwgOGe2X8ZMRPFESiOzkZW/
s7ell7GJOXZ+M8G7fbI07xEDsEAKJ00DtsPTN6zuEVfs4H+ay08/aDKoS6qHQKpM
mtZ0EaVi8vQZelHCxilsnwD/or+0EYMO2tEoUMUrtbJ3dJja6koB4DkbJ4i3Dt02
ySXjhIA180u8ZblHMOpLB/gn5bfvr2sM5ASDCqb5gv4MV2CjB4e9j00lmxSav7cG
wQIDAQAB
-----END PUBLIC KEY-----
EOF
}

resource "aws_cloudfront_public_key" "signing-key1" {
  name    = "signing-key1"
  comment = "Disposable demo key (no private half). Used by field-level encryption and the /premium signed-URL key group."
  encoded_key = <<-EOF
-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAl8Q8aW6nki9vHic8OcLx
oh4PKEmqPZHejyd1PfrIdVn12PW+XpOdSNC3izm8sDBVrv2Bs3hQKBKGW0YRn/8Z
QTpYEM3hucp2qcAIRX90NK7VZNp3roNrEc1fqexBiAWmMfVrzSfw9Aa/zZJ+SFiJ
bPtG1jVwOo1bUaWOIsgY5Rlk63FBt2yQZivbgpHJWgxdzsZsE4hbXAyODrKdylU4
9psTspDqHLwM/JKaRrlkGxPh2xN5FY2dxhpn2nHY+tFsWIushmqQtwKUNhDhhfKi
oPf55edG1QFEzyjzm21jz5J9um+ph3F8I/2wPXPzGS5G5yu6O5yz4R3T+2huYcGr
LQIDAQAB
-----END PUBLIC KEY-----
EOF
}

resource "aws_cloudfront_response_headers_policy" "headers-validation1" {
  name = "headers-validation"
  cors_config {
    access_control_allow_credentials = false
    access_control_max_age_sec       = 600
    origin_override                  = true
    access_control_allow_headers {
      items = ["*"]
    }
    access_control_allow_methods {
      items = ["GET", "HEAD", "OPTIONS"]
    }
    access_control_allow_origins {
      items = ["*"]
    }
  }
  security_headers_config {
    content_security_policy {
      content_security_policy = "default-src 'self'"
      override                = true
    }
    content_type_options {
      override = true
    }
    frame_options {
      frame_option = "SAMEORIGIN"
      override     = true
    }
    referrer_policy {
      override        = true
      referrer_policy = "strict-origin-when-cross-origin"
    }
    strict_transport_security {
      access_control_max_age_sec = 31536000
      include_subdomains         = true
      override                   = true
      preload                    = false
    }
    xss_protection {
      mode_block = true
      override   = true
      protection = true
    }
  }
  server_timing_headers_config {
    enabled       = true
    sampling_rate = 10
  }
}

resource "aws_cloudfrontkeyvaluestore_key" "banner1" {
  key                 = "banner"
  key_value_store_arn = aws_cloudfront_key_value_store.kvs-validation1.arn
  value               = "struct8-validacao"
}




### CATEGORY: STORAGE ###

resource "aws_s3_bucket" "origin-cf-validation1" {
  bucket              = "origem-cf-validacao"
  force_destroy       = true
  object_lock_enabled = false
  tags = {
    Name           = "origin-cf-validation1"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_s3_bucket_ownership_controls" "origin-cf-validation1_controls" {
  bucket = aws_s3_bucket.origin-cf-validation1.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

data "aws_iam_policy_document" "aws_s3_bucket_policy_origin-cf-validation1_st_State3_doc" {
  statement {
    sid    = "AllowCloudFrontServicePrincipalReadOnly"
    effect = "Allow"
    principals {
      identifiers = ["cloudfront.amazonaws.com"]
      type        = "Service"
    }
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.origin-cf-validation1.arn}/*"]
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = ["arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${aws_cloudfront_distribution.cdn-open1.id}"]
    }
  }
  statement {
    sid    = "AllowCloudFrontServicePrincipalReadOnly1"
    effect = "Allow"
    principals {
      identifiers = ["cloudfront.amazonaws.com"]
      type        = "Service"
    }
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.origin-cf-validation1.arn}/*"]
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = ["arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${aws_cloudfront_distribution.cdn-protected1.id}"]
    }
  }
}

resource "aws_s3_bucket_policy" "aws_s3_bucket_policy_origin-cf-validation1_st_State3" {
  bucket = aws_s3_bucket.origin-cf-validation1.id
  policy = data.aws_iam_policy_document.aws_s3_bucket_policy_origin-cf-validation1_st_State3_doc.json
}

resource "aws_s3_bucket_public_access_block" "origin-cf-validation1_block" {
  block_public_acls       = true
  block_public_policy     = true
  bucket                  = aws_s3_bucket.origin-cf-validation1.id
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "origin-cf-validation1_configuration" {
  bucket = aws_s3_bucket.origin-cf-validation1.id
  rule {
    bucket_key_enabled = true
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "origin-cf-validation1_versioning" {
  bucket = aws_s3_bucket.origin-cf-validation1.id
  versioning_configuration {
    mfa_delete = "Disabled"
    status     = "Suspended"
  }
}

resource "aws_s3_object" "img-private-2" {
  source       = "${path.module}/.external_modules/struct8-templates/templates/cloudfront-lambda-edge-showcase/v1/lab/private/photo-1.svg"
  bucket       = aws_s3_bucket.origin-cf-validation1.bucket
  content_type = "image/svg+xml"
  etag         = filemd5("${path.module}/.external_modules/struct8-templates/templates/cloudfront-lambda-edge-showcase/v1/lab/private/photo-1.svg")
  key          = "private/photo-1.svg"
  tags = {
    Name           = "img-private-2"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_s3_object" "img-public-2" {
  source       = "${path.module}/.external_modules/struct8-templates/templates/cloudfront-lambda-edge-showcase/v1/lab/public/photo-1.svg"
  bucket       = aws_s3_bucket.origin-cf-validation1.bucket
  content_type = "image/svg+xml"
  etag         = filemd5("${path.module}/.external_modules/struct8-templates/templates/cloudfront-lambda-edge-showcase/v1/lab/public/photo-1.svg")
  key          = "public/photo-1.svg"
  tags = {
    Name           = "img-public-2"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_s3_object" "index-html2" {
  acl          = "private"
  bucket       = aws_s3_bucket.origin-cf-validation1.bucket
  content      = "<!doctype html><html lang=\"en\"><head><meta charset=\"utf-8\"><title>Struct8 CloudFront</title></head><body><h1>CloudFront serving from S3</h1><p>If you are reading this through the CloudFront domain, the Origin Access Control, the distribution and the cache policy are deployed and working.</p></body></html>"
  content_type = "text/html"
  key          = "index.html"
  tags = {
    Name           = "index-html2"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_s3_object" "lab-app-js1" {
  source       = "${path.module}/.external_modules/struct8-templates/templates/cloudfront-lambda-edge-showcase/v1/lab/app.js"
  bucket       = aws_s3_bucket.origin-cf-validation1.bucket
  content_type = "application/javascript"
  etag         = filemd5("${path.module}/.external_modules/struct8-templates/templates/cloudfront-lambda-edge-showcase/v1/lab/app.js")
  key          = "lab/app.js"
  tags = {
    Name           = "lab-app-js1"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_s3_object" "lab-index-html1" {
  source       = "${path.module}/.external_modules/struct8-templates/templates/cloudfront-lambda-edge-showcase/v1/lab/index.html"
  bucket       = aws_s3_bucket.origin-cf-validation1.bucket
  content_type = "text/html"
  etag         = filemd5("${path.module}/.external_modules/struct8-templates/templates/cloudfront-lambda-edge-showcase/v1/lab/index.html")
  key          = "lab/index.html"
  tags = {
    Name           = "lab-index-html1"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_s3_object" "lab-styles-css1" {
  source       = "${path.module}/.external_modules/struct8-templates/templates/cloudfront-lambda-edge-showcase/v1/lab/styles.css"
  bucket       = aws_s3_bucket.origin-cf-validation1.bucket
  content_type = "text/css"
  etag         = filemd5("${path.module}/.external_modules/struct8-templates/templates/cloudfront-lambda-edge-showcase/v1/lab/styles.css")
  key          = "lab/styles.css"
  tags = {
    Name           = "lab-styles-css1"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_s3_object" "premium-secret-html1" {
  acl          = "private"
  bucket       = aws_s3_bucket.origin-cf-validation1.bucket
  content      = "<!doctype html><meta charset=utf-8><title>Premium</title><h1>Signed-URL protected content</h1><p>You presented a valid signed URL. Direct access to /premium without a signature returns 403.</p>"
  content_type = "text/html"
  key          = "premium/secret.html"
  tags = {
    Name           = "premium-secret-html1"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}




### CATEGORY: COMPUTE ###

data "archive_file" "archive_struct8-templates_api-regular-nonedge1" {
  output_path = "${path.module}/struct8-templates_api-regular-nonedge1.zip"
  source_dir  = "${path.module}/.external_modules/struct8-templates/templates/cloudfront-lambda-edge-showcase/v1/functions/api-regular"
  type        = "zip"
}

resource "aws_lambda_function" "api-regular-nonedge1" {
  function_name                  = "api-regular-nonedge1"
  architectures                  = ["arm64"]
  description                    = "REGULAR (non-edge) Lambda for contrast: no region restriction, accepts env vars, larger timeout. Lightweight backend example."
  filename                       = data.archive_file.archive_struct8-templates_api-regular-nonedge1.output_path
  handler                        = "index.handler"
  memory_size                    = 256
  publish                        = false
  reserved_concurrent_executions = -1
  role                           = aws_iam_role.api-regular-nonedge1_role.arn
  runtime                        = "nodejs20.x"
  source_code_hash               = data.archive_file.archive_struct8-templates_api-regular-nonedge1.output_base64sha256
  timeout                        = 30
  environment {
    variables = {
    PRIVATE_KEY_PARAM             = "/cloudfront-lab/signing-private-key"
    CF_OUTPUTS_PARAM              = "/cloudfront-lab/cf-outputs"
    GREETING_NAME                 = "world"
    NAME                          = "api-regular-nonedge1"
    REGION                        = data.aws_region.current.region
    ACCOUNT                       = data.aws_caller_identity.current.account_id
    AWS_SSM_PARAMETER_NAME_0      = "cf-signing-private-key1"
    AWS_SSM_PARAMETER_NAME_ENVVAR = "CloudFrontOutputs1"
  }
  }
  tags = {
    Name           = "api-regular-nonedge1"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_iam_role_policy_attachment.lambda_function_api-regular-nonedge1_st_State3_attach, aws_iam_role_policy_attachment.api-regular-logs_attach_api-regular-nonedge1_role]
}

data "archive_file" "archive_struct8-templates_edge-abtest-viewer-response1" {
  output_path = "${path.module}/struct8-templates_edge-abtest-viewer-response1.zip"
  source_dir  = "${path.module}/.external_modules/struct8-templates/templates/cloudfront-lambda-edge-showcase/v1/edge/abtest-viewer-response"
  type        = "zip"
}

resource "aws_lambda_function" "edge-abtest-viewer-response1" {
  function_name                  = "edge-abtest-viewer-response1"
  architectures                  = ["x86_64"]
  description                    = "Lambda@Edge (viewer-response): A/B testing / per-device cookie on the response to the viewer."
  filename                       = data.archive_file.archive_struct8-templates_edge-abtest-viewer-response1.output_path
  handler                        = "index.handler"
  memory_size                    = 128
  publish                        = true
  region                         = "us-east-1"
  reserved_concurrent_executions = -1
  role                           = aws_iam_role.edge-abtest-viewer-response1_role.arn
  runtime                        = "nodejs20.x"
  source_code_hash               = data.archive_file.archive_struct8-templates_edge-abtest-viewer-response1.output_base64sha256
  timeout                        = 5
  tags = {
    Name           = "edge-abtest-viewer-response1"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_iam_role_policy_attachment.edge-abtest-logs_attach_edge-abtest-viewer-response1_role]
}

data "archive_file" "archive_struct8-templates_edge-auth-viewer-request1" {
  output_path = "${path.module}/struct8-templates_edge-auth-viewer-request1.zip"
  source_dir  = "${path.module}/.external_modules/struct8-templates/templates/cloudfront-lambda-edge-showcase/v1/edge/auth-viewer-request"
  type        = "zip"
}

resource "aws_lambda_function" "edge-auth-viewer-request1" {
  function_name                  = "edge-auth-viewer-request1"
  architectures                  = ["x86_64"]
  description                    = "Lambda@Edge (viewer-request): authentication/authorization at the edge before serving. Edge requires us-east-1, a published version, and no env vars."
  filename                       = data.archive_file.archive_struct8-templates_edge-auth-viewer-request1.output_path
  handler                        = "index.handler"
  memory_size                    = 128
  publish                        = true
  region                         = "us-east-1"
  reserved_concurrent_executions = -1
  role                           = aws_iam_role.edge-auth-viewer-request1_role.arn
  runtime                        = "nodejs20.x"
  source_code_hash               = data.archive_file.archive_struct8-templates_edge-auth-viewer-request1.output_base64sha256
  timeout                        = 5
  tags = {
    Name           = "edge-auth-viewer-request1"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_iam_role_policy_attachment.edge-auth-logs_attach_edge-auth-viewer-request1_role]
}

data "archive_file" "archive_struct8-templates_edge-rewrite-origin-request1" {
  output_path = "${path.module}/struct8-templates_edge-rewrite-origin-request1.zip"
  source_dir  = "${path.module}/.external_modules/struct8-templates/templates/cloudfront-lambda-edge-showcase/v1/edge/rewrite-origin-request"
  type        = "zip"
}

resource "aws_lambda_function" "edge-rewrite-origin-request1" {
  function_name                  = "edge-rewrite-origin-request1"
  architectures                  = ["x86_64"]
  description                    = "Lambda@Edge (origin-request): URL rewrite / SPA routing before reaching the origin."
  filename                       = data.archive_file.archive_struct8-templates_edge-rewrite-origin-request1.output_path
  handler                        = "index.handler"
  memory_size                    = 128
  publish                        = true
  region                         = "us-east-1"
  reserved_concurrent_executions = -1
  role                           = aws_iam_role.edge-rewrite-origin-request1_role.arn
  runtime                        = "nodejs20.x"
  source_code_hash               = data.archive_file.archive_struct8-templates_edge-rewrite-origin-request1.output_base64sha256
  timeout                        = 5
  tags = {
    Name           = "edge-rewrite-origin-request1"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_iam_role_policy_attachment.edge-rewrite-logs_attach_edge-rewrite-origin-request1_role]
}

data "archive_file" "archive_struct8-templates_edge-security-headers-origin-response1" {
  output_path = "${path.module}/struct8-templates_edge-security-headers-origin-response1.zip"
  source_dir  = "${path.module}/.external_modules/struct8-templates/templates/cloudfront-lambda-edge-showcase/v1/edge/security-headers-origin-response"
  type        = "zip"
}

resource "aws_lambda_function" "edge-security-headers-origin-response1" {
  function_name                  = "edge-security-headers-origin-response1"
  architectures                  = ["x86_64"]
  description                    = "Lambda@Edge (origin-response): injects security headers (HSTS, CSP). Cheaper alternative: aws_cloudfront_response_headers_policy."
  filename                       = data.archive_file.archive_struct8-templates_edge-security-headers-origin-response1.output_path
  handler                        = "index.handler"
  memory_size                    = 128
  publish                        = true
  region                         = "us-east-1"
  reserved_concurrent_executions = -1
  role                           = aws_iam_role.edge-security-headers-origin-response1_role.arn
  runtime                        = "nodejs20.x"
  source_code_hash               = data.archive_file.archive_struct8-templates_edge-security-headers-origin-response1.output_base64sha256
  timeout                        = 5
  ephemeral_storage {
    size = 512
  }
  tags = {
    Name           = "edge-security-headers-origin-response1"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_iam_role_policy_attachment.edge-headers-logs_attach_edge-security-headers-origin-response1_role]
}

resource "aws_lambda_permission" "perm_aws_apigatewayv2_api_http-api-regular1_to_api-regular-nonedge1" {
  function_name = aws_lambda_function.api-regular-nonedge1.function_name
  statement_id  = "perm_aws_apigatewayv2_api_http-api-regular1_to_api-regular-nonedge1"
  principal     = "apigateway.amazonaws.com"
  action        = "lambda:InvokeFunction"
  source_arn    = "${aws_apigatewayv2_api.http-api-regular1.execution_arn}/*/*"
}




### CATEGORY: MONITORING ###

resource "aws_cloudwatch_log_group" "log-api-regular1" {
  name              = "/aws/lambda/api-regular-nonedge"
  log_group_class   = "STANDARD"
  retention_in_days = 14
  skip_destroy      = false
  tags = {
    Name           = "log-api-regular1"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_cloudwatch_log_group" "log-edge-abtest1" {
  name              = "/aws/lambda/edge-abtest-viewer-response"
  log_group_class   = "STANDARD"
  retention_in_days = 14
  skip_destroy      = false
  tags = {
    Name           = "log-edge-abtest1"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_cloudwatch_log_group" "log-edge-auth1" {
  name              = "/aws/lambda/edge-auth-viewer-request"
  log_group_class   = "STANDARD"
  retention_in_days = 14
  skip_destroy      = false
  tags = {
    Name           = "log-edge-auth1"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_cloudwatch_log_group" "log-edge-headers1" {
  name              = "/aws/lambda/edge-security-headers-origin-response"
  log_group_class   = "STANDARD"
  retention_in_days = 14
  skip_destroy      = false
  tags = {
    Name           = "log-edge-headers1"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_cloudwatch_log_group" "log-edge-rewrite1" {
  name              = "/aws/lambda/edge-rewrite-origin-request"
  log_group_class   = "STANDARD"
  retention_in_days = 14
  skip_destroy      = false
  tags = {
    Name           = "log-edge-rewrite1"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}




### CATEGORY: CONFIG ###

resource "aws_ssm_parameter" "CloudFrontOutputs1" {
  name        = "/cloudfront-lab/cf-outputs"
  data_type   = "text"
  description = "Grouped outputs (distribution domain_name/id, public key id) for the login Lambda to read at runtime instead of hardcoded env vars."
  overwrite   = true
  tier        = "Standard"
  type        = "String"
  value = jsonencode({
    "aws_cloudfront_distribution" = {
      "cdn-protected1" = {
        "id"                             = "${aws_cloudfront_distribution.cdn-protected1.id}"
        "arn"                            = "${aws_cloudfront_distribution.cdn-protected1.arn}"
        "caller_reference"               = "${aws_cloudfront_distribution.cdn-protected1.caller_reference}"
        "domain_name"                    = "${aws_cloudfront_distribution.cdn-protected1.domain_name}"
        "etag"                           = "${aws_cloudfront_distribution.cdn-protected1.etag}"
        "hosted_zone_id"                 = "${aws_cloudfront_distribution.cdn-protected1.hosted_zone_id}"
        "in_progress_validation_batches" = "${aws_cloudfront_distribution.cdn-protected1.in_progress_validation_batches}"
        "last_modified_time"             = "${aws_cloudfront_distribution.cdn-protected1.last_modified_time}"
        "logging_v1_enabled"             = "${aws_cloudfront_distribution.cdn-protected1.logging_v1_enabled}"
        "status"                         = "${aws_cloudfront_distribution.cdn-protected1.status}"
        "trusted_key_groups"             = "${aws_cloudfront_distribution.cdn-protected1.trusted_key_groups}"
        "trusted_signers"                = "${aws_cloudfront_distribution.cdn-protected1.trusted_signers}"
      }
    }
    "aws_cloudfront_public_key" = {
      "signing-key-cookies1" = {
        "id"               = "${aws_cloudfront_public_key.signing-key-cookies1.id}"
        "caller_reference" = "${aws_cloudfront_public_key.signing-key-cookies1.caller_reference}"
        "etag"             = "${aws_cloudfront_public_key.signing-key-cookies1.etag}"
      }
    }
  })
  tags = {
    Name           = "CloudFrontOutputs1"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_ssm_parameter" "cf-signing-private-key1" {
  name        = "/cloudfront-lab/signing-private-key"
  data_type   = "text"
  description = "RSA private key (SecureString) for CloudFront signed cookies. The login Lambda reads it at runtime to sign the /private policy. Demo/lab only; in production use a rotated secret store, never git."
  overwrite   = false
  tier        = "Standard"
  type        = "SecureString"
  value = <<EOF
-----BEGIN PRIVATE KEY-----
MIIEuwIBADANBgkqhkiG9w0BAQEFAASCBKUwggShAgEAAoIBAQCpqrtZHIL9fDFU
9PVJPJnqNZRLP0AAuQPFAPzFvp5X7r1R1z5fdVHkgzVODqLdDbhvsmrQ/ZfOfugn
uamGtb9dZzqkOpb1q04rG33LWDTbCZ52GUeuBNOip5v2gCKQbCA4Z7ZfxkxE8URK
I7ORlb+zt6WXsYk5dn4zwbt9sjTvEQOwQAonTQO2w9M3rO4RV+zgf5rLTz9oMqhL
qodAqkya1nQRpWLy9Bl6UcLGKWyfAP+iv7QRgw7a0ShQxSu1snd0mNrqSgHgORsn
iLcO3TbJJeOEgDXzS7xluUcw6ksH+Cflt++vawzkBIMKpvmC/gxXYKMHh72PTSWb
FJq/twbBAgMBAAECgf8eru2qs+lMhkU1pAcn83myTXZAFXQxrUPtQLx11n80T8yV
HGP/R2xD8yaUszjo2S5dpNqEaRgnE/RQGtd5sSyma6DDSoU6cHx2d0ZMm+sTIa4y
lWfNJLpRVBZ0gb++do9tI/RrZaUtYqSC8+npjjdY/QFJaaXzamZwXbzWgn/oK9PT
KKJqRVR3DDOuUOweB16oniokW5+fkeYDig5PjV25/c6cWrXOgxGNFRbZI5F926Ht
gA9IWAJu0cHUxWNUnv3BpS6GqLKlUymzRKgtar226K93oqMu3mUCNY6jvMNNz23t
9i5HzE39fKGgRvdRxjX823Zmn6grpIZjh0jbKAECgYEA5RNzr9Fhqe3X2Nf2nMHj
u8MJJ2EjoYUw1kVjaY9YXC+wrLwlsmmlR/Lmv6KtxpgTxioytMDUaJBiGX0vxOZ/
QhxUazkQdFQefeV4pabhEgzYfW5xMEEUmN32VOBAmZABUPNC0eheOhKG8rk4UkMV
gWdGtlPOMUBQ4QlppPhl3sECgYEAvZvAZVT5dgd1z8+sEeqND1VYUwwLN7G6EzmC
xxYRdTpBf+v6KBYIZujRp9pseM9C79WlWEweTau3A6BdrA7TbVFKvV5McjOXp5LL
eq6Cgzhn3zXk+LQrIcoPekduW55waJXr/voOVw5udo01Hs9MKnNPVc3yFDqqqdPQ
MJBDKAECgYBx2QAG4l3ScVVz/Kkg8S+4ck8LVji6HpLN+wBURxyX/E+nGX72s5Ck
OHE7zqLk71Hsi65VrPwj15YZquDhz9hxR9kgzOSDnAbndPNICK8VJHM3q3rvi3is
HKw/NJCGgU5WKAAOiJjD7c9JtInsQFDg1i4LkY0JZziLDv2FMrqWQQKBgHyFbTUf
OTVqcNSpbjfV8g2/3uGrZzKMZcd6XYih1ZVHTPzV3NO2pI3xGL9DkzlD5JHdnVj/
pGcd/nNDPkFg+zkvygXTiCD4AQDsRvWq5cuHn6/XlShAKpNmQAPuJWvGAcytqO8r
CX/i2mjBE8HIIh0+3TtcpT7jyHD/yhoapAABAoGBAM/jacp2t/4AdLmDZCWmLg+9
2THH31Yomrc3X9iUbckck5wa3Od6kOvyoiVMLo9g7PejHazye5xRf+NasmTDx+hf
lUPKlmEu06uDRLrPYYpbLhHwQP7AvccioCVqV3MRpx5V0nxJzeAv8GZily/BvAS8
9VJANYWVMlOOQOM2H5kz
-----END PRIVATE KEY-----
  EOF
  tags = {
    Name           = "cf-signing-private-key1"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}


