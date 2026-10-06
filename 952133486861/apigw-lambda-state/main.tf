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
    key     = "952133486861/apigw-lambda-state/main.tfstate"
    region  = "us-west-2"
    encrypt = true
  }
}

# --- Main Cloud Provider ---
provider "aws" {
  region = "us-east-1"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

### SYSTEM DATA SOURCES ###

data "aws_route53_zone" "your-domain" {
  name = "cloudman.pro"
}




### CATEGORY: IAM ###

data "aws_iam_policy_document" "lambda_function_demo-handler_st_apigw-lambda-state_doc" {
  statement {
    sid       = "AllowWriteLogs"
    effect    = "Allow"
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.demo-handler-logs.arn}:*"]
  }
}

resource "aws_iam_policy" "lambda_function_demo-handler_st_apigw-lambda-state" {
  name        = "lambda_function_demo-handler_st_apigw-lambda-state"
  description = "Access Policy for demo-handler"
  policy      = data.aws_iam_policy_document.lambda_function_demo-handler_st_apigw-lambda-state_doc.json
}

data "aws_iam_policy_document" "doc_perm_role_apigw_demo-rest-api_to_assets" {
  statement {
    sid       = "AllowBucketLevelActions"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.assets.arn]
  }
  statement {
    sid       = "AllowObjectCRUD"
    effect    = "Allow"
    actions   = ["s3:DeleteObject", "s3:GetObject", "s3:PutObject"]
    resources = ["${aws_s3_bucket.assets.arn}/*"]
  }
}

data "aws_iam_policy_document" "doc_perm_role_apigw_demo-rest-api_to_events" {
  statement {
    sid       = "AllowKinesisStreamAccess"
    effect    = "Allow"
    actions   = ["kinesis:PutRecord"]
    resources = [aws_kinesis_stream.events.arn]
  }
}

data "aws_iam_policy_document" "doc_perm_role_apigw_demo-rest-api_to_items" {
  statement {
    sid       = "AllowDynamoDBCRUD"
    effect    = "Allow"
    actions   = ["dynamodb:DeleteItem", "dynamodb:GetItem", "dynamodb:PutItem"]
    resources = [aws_dynamodb_table.items.arn, "${aws_dynamodb_table.items.arn}/*"]
  }
}

data "aws_iam_policy_document" "doc_perm_role_apigw_demo-rest-api_to_jobs" {
  statement {
    sid       = "AllowSQSActions"
    effect    = "Allow"
    actions   = ["sqs:DeleteMessage", "sqs:ReceiveMessage", "sqs:SendMessage"]
    resources = [aws_sqs_queue.jobs.arn]
  }
}

data "aws_iam_policy_document" "doc_trust_role_apigw_demo-rest-api_to_assets" {
  statement {
    effect = "Allow"
    principals {
      identifiers = ["apigateway.amazonaws.com"]
      type        = "Service"
    }
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "doc_trust_role_apigw_demo-rest-api_to_events" {
  statement {
    effect = "Allow"
    principals {
      identifiers = ["apigateway.amazonaws.com"]
      type        = "Service"
    }
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "doc_trust_role_apigw_demo-rest-api_to_items" {
  statement {
    effect = "Allow"
    principals {
      identifiers = ["apigateway.amazonaws.com"]
      type        = "Service"
    }
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "doc_trust_role_apigw_demo-rest-api_to_jobs" {
  statement {
    effect = "Allow"
    principals {
      identifiers = ["apigateway.amazonaws.com"]
      type        = "Service"
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "demo-handler_role" {
  name = "demo-handler_role"
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
    Name           = "demo-handler_role"
    State          = "apigw-lambda-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "role_apigw_demo-rest-api_to_assets" {
  name               = "api-demo-rest-api-assets-role"
  assume_role_policy = data.aws_iam_policy_document.doc_trust_role_apigw_demo-rest-api_to_assets.json
}

resource "aws_iam_role" "role_apigw_demo-rest-api_to_events" {
  name               = "api-demo-rest-api-events-role"
  assume_role_policy = data.aws_iam_policy_document.doc_trust_role_apigw_demo-rest-api_to_events.json
}

resource "aws_iam_role" "role_apigw_demo-rest-api_to_items" {
  name               = "api-demo-rest-api-items-role"
  assume_role_policy = data.aws_iam_policy_document.doc_trust_role_apigw_demo-rest-api_to_items.json
}

resource "aws_iam_role" "role_apigw_demo-rest-api_to_jobs" {
  name               = "api-demo-rest-api-jobs-role"
  assume_role_policy = data.aws_iam_policy_document.doc_trust_role_apigw_demo-rest-api_to_jobs.json
}

resource "aws_iam_role_policy" "policy_role_apigw_demo-rest-api_to_assets" {
  name   = "access-assets"
  policy = data.aws_iam_policy_document.doc_perm_role_apigw_demo-rest-api_to_assets.json
  role   = aws_iam_role.role_apigw_demo-rest-api_to_assets.id
}

resource "aws_iam_role_policy" "policy_role_apigw_demo-rest-api_to_events" {
  name   = "access-events"
  policy = data.aws_iam_policy_document.doc_perm_role_apigw_demo-rest-api_to_events.json
  role   = aws_iam_role.role_apigw_demo-rest-api_to_events.id
}

resource "aws_iam_role_policy" "policy_role_apigw_demo-rest-api_to_items" {
  name   = "access-items"
  policy = data.aws_iam_policy_document.doc_perm_role_apigw_demo-rest-api_to_items.json
  role   = aws_iam_role.role_apigw_demo-rest-api_to_items.id
}

resource "aws_iam_role_policy" "policy_role_apigw_demo-rest-api_to_jobs" {
  name   = "access-jobs"
  policy = data.aws_iam_policy_document.doc_perm_role_apigw_demo-rest-api_to_jobs.json
  role   = aws_iam_role.role_apigw_demo-rest-api_to_jobs.id
}

resource "aws_iam_role_policy_attachment" "lambda_function_demo-handler_st_apigw-lambda-state_attach" {
  policy_arn = aws_iam_policy.lambda_function_demo-handler_st_apigw-lambda-state.arn
  role       = aws_iam_role.demo-handler_role.name
}

resource "aws_acm_certificate" "api-cert" {
  domain_name       = "api.cloudman.pro"
  key_algorithm     = "RSA_2048"
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
  options {
    certificate_transparency_logging_preference = "ENABLED"
  }
  tags = {
    Name           = "api-cert"
    State          = "apigw-lambda-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_acm_certificate_validation" "Validation_api-cert" {
  certificate_arn         = aws_acm_certificate.api-cert.arn
  validation_record_fqdns = [for record in aws_route53_record.Route53_Record_api-cert_api_cloudman_pro : record.fqdn]
}




### CATEGORY: NETWORK ###

resource "aws_route53_record" "Route53_Record_api-cert_api_cloudman_pro" {
  for_each = {
    for dvo in aws_acm_certificate.api-cert.domain_validation_options : dvo.domain_name => dvo
    if dvo.domain_name == "api.cloudman.pro"
  }
  name            = each.value.resource_record_name
  zone_id         = data.aws_route53_zone.your-domain.zone_id
  allow_overwrite = true
  records         = [each.value.resource_record_value]
  ttl             = 300
  type            = each.value.resource_record_type
}

resource "aws_route53_record" "alias_a_aws_api_gateway_domain_name_api-custom-domain_api_cloudman_pro" {
  name    = "api.cloudman.pro"
  zone_id = data.aws_route53_zone.your-domain.zone_id
  type    = "A"
  alias {
    name                   = aws_api_gateway_domain_name.api-custom-domain.regional_domain_name
    zone_id                = aws_api_gateway_domain_name.api-custom-domain.regional_zone_id
    evaluate_target_health = false
  }
}

resource "aws_api_gateway_api_key" "demo-api-key" {
  name        = "demo-api-key"
  description = "API key required by the API. Value auto-generated by AWS (value_strategy auto). Sent in the x-api-key header. Bound to the usage plan that defines quota and throttle."
  tags = {
    Name           = "demo-api-key"
    State          = "apigw-lambda-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_api_gateway_base_path_mapping" "api-custom-domain_mapping" {
  api_id      = aws_api_gateway_rest_api.demo-rest-api.id
  domain_name = aws_api_gateway_domain_name.api-custom-domain.domain_name
  stage_name  = aws_api_gateway_stage.prod.stage_name
}

resource "aws_api_gateway_deployment" "demo-deployment" {
  rest_api_id = aws_api_gateway_rest_api.demo-rest-api.id
  lifecycle {
    create_before_destroy = true
  }
  triggers = {
    redeployment = sha1(join(",", [jsonencode(aws_api_gateway_rest_api.demo-rest-api.body), jsonencode([aws_api_gateway_rest_api.demo-rest-api.binary_media_types, aws_api_gateway_rest_api.demo-rest-api.minimum_compression_size, aws_api_gateway_rest_api.demo-rest-api.api_key_source, aws_api_gateway_rest_api.demo-rest-api.policy])]))
  }
  depends_on = [aws_lambda_permission.perm_aws_api_gateway_rest_api_demo-rest-api_to_demo-handler_openapi]
}

resource "aws_api_gateway_domain_name" "api-custom-domain" {
  domain_name              = "api.cloudman.pro"
  regional_certificate_arn = aws_acm_certificate_validation.Validation_api-cert.certificate_arn
  endpoint_configuration {
    types = ["REGIONAL"]
  }
  tags = {
    Name           = "api-custom-domain"
    State          = "apigw-lambda-state"
    Struct8Creator = "Contato Struct"
  }
}

locals {
  api_config_demo-rest-api = [
    {
      path             = "/demo-handler"
      uri              = "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:${data.aws_caller_identity.current.account_id}:function:${aws_lambda_function.demo-handler.function_name}/invocations"
      type             = "aws_proxy"
      methods          = ["get", "post", "put", "delete"]
      method_security  = {"get" = [{ "api_key" = [] }], "post" = [{ "api_key" = [] }], "put" = [{ "api_key" = [] }], "delete" = [{ "api_key" = [] }]}
      enable_mock      = true
      credentials      = null
      requestTemplates = null
      integ_method     = "POST"
      parameters       = null
      integ_req_params = null
      error_responses  = {}
      error_templates  = {}
      binary_body      = false
      passthrough      = null
      success_template = null
      cache_keys       = []
    },
    {
      path            = "/assets/{proxy+}"
      uri             = "arn:aws:apigateway:us-east-1:s3:path/${aws_s3_bucket.assets.id}/{proxy}"
      type            = "aws"
      methods         = ["get", "put", "delete"]
      method_security = {"get" = [{ "api_key" = [] }], "put" = [{ "api_key" = [] }], "delete" = [{ "api_key" = [] }]}
      enable_mock     = true
      credentials     = aws_iam_role.role_apigw_demo-rest-api_to_assets.arn
      requestTemplates = {
      }
      integ_method = "MATCH"
      parameters = [
          {
            name     = "proxy"
            in       = "path"
            required = true
            schema   = { type = "string" }
          }
        ]
      integ_req_params = {
        "integration.request.path.proxy" = "method.request.path.proxy"
      }
      error_responses  = {"403" = "403", "404" = "404", "429" = "429", "503" = "503", "4(0[0-25-9]|1[0-9]|2[0-8]|[3-9][0-9])" = "400", "5(0[0-24-9]|[1-9][0-9])" = "500"}
      error_templates  = {"403" = "{\"message\":\"Forbidden\"}", "404" = "{\"message\":\"Not Found\"}", "429" = "{\"message\":\"Too Many Requests\"}", "503" = "{\"message\":\"Service Unavailable\"}", "4(0[0-25-9]|1[0-9]|2[0-8]|[3-9][0-9])" = "{\"message\":\"Bad Request\"}", "5(0[0-24-9]|[1-9][0-9])" = "{\"message\":\"Internal Server Error\"}"}
      binary_body      = true
      passthrough      = null
      success_template = null
      cache_keys       = ["method.request.path.proxy"]
    },
    {
      path            = "/assets/{proxy+}"
      uri             = "arn:aws:apigateway:us-east-1:s3:path/${aws_s3_bucket.assets.id}/{proxy}"
      type            = "aws"
      methods         = ["post"]
      method_security = {"post" = [{ "api_key" = [] }]}
      enable_mock     = true
      credentials     = aws_iam_role.role_apigw_demo-rest-api_to_assets.arn
      requestTemplates = {
      }
      integ_method = "PUT"
      parameters = [
          {
            name     = "proxy"
            in       = "path"
            required = true
            schema   = { type = "string" }
          }
        ]
      integ_req_params = {
        "integration.request.path.proxy" = "method.request.path.proxy"
      }
      error_responses  = {"403" = "403", "404" = "404", "429" = "429", "503" = "503", "4(0[0-25-9]|1[0-9]|2[0-8]|[3-9][0-9])" = "400", "5(0[0-24-9]|[1-9][0-9])" = "500"}
      error_templates  = {"403" = "{\"message\":\"Forbidden\"}", "404" = "{\"message\":\"Not Found\"}", "429" = "{\"message\":\"Too Many Requests\"}", "503" = "{\"message\":\"Service Unavailable\"}", "4(0[0-25-9]|1[0-9]|2[0-8]|[3-9][0-9])" = "{\"message\":\"Bad Request\"}", "5(0[0-24-9]|[1-9][0-9])" = "{\"message\":\"Internal Server Error\"}"}
      binary_body      = true
      passthrough      = null
      success_template = null
      cache_keys       = ["method.request.path.proxy"]
    },
    {
      path            = "/items/{id}"
      uri             = "arn:aws:apigateway:us-east-1:dynamodb:action/GetItem"
      type            = "aws"
      methods         = ["get"]
      method_security = {"get" = [{ "api_key" = [] }]}
      enable_mock     = true
      credentials     = aws_iam_role.role_apigw_demo-rest-api_to_items.arn
      requestTemplates = {
        "application/json" = "#set($hashKey = $input.params('id'))#if($hashKey.matches('^([^%]|%[0-9A-Fa-f]{2})*$'))#set($hashKey = $util.urlDecode($hashKey.replace(\"+\",\"%2B\")))#end{\"TableName\": \"${aws_dynamodb_table.items.name}\", \"Key\": { \"id\": { \"S\": \"$util.escapeJavaScript($hashKey).replaceAll(\"\\\\'\",\"'\")\" } } }"
      }
      integ_method     = "POST"
      parameters       = [{"name": "id", "in": "path", "required": true, "schema": {"type": "string"}}]
      integ_req_params = null
      error_responses  = {"403" = "403", "404" = "404", "429" = "429", "503" = "503", "4(0[0-25-9]|1[0-9]|2[0-8]|[3-9][0-9])" = "400", "5(0[0-24-9]|[1-9][0-9])" = "500"}
      error_templates  = {"403" = "{\"message\":\"Forbidden\"}", "404" = "{\"message\":\"Not Found\"}", "429" = "{\"message\":\"Too Many Requests\"}", "503" = "{\"message\":\"Service Unavailable\"}", "4(0[0-25-9]|1[0-9]|2[0-8]|[3-9][0-9])" = "#set($type = $input.path('$.__type'))#if(!$type)#set($type = '')#end#if($type.contains(\"AccessDenied\"))#set($context.responseOverride.status = 403){\"message\":\"Forbidden\"}#elseif($type.contains(\"ResourceNotFound\"))#set($context.responseOverride.status = 404){\"message\":\"Not Found\"}#elseif($type.contains(\"Throughput\") || $type.contains(\"Throttl\") || $type.contains(\"LimitExceeded\"))#set($context.responseOverride.status = 429){\"message\":\"Too Many Requests\"}#{else}{\"message\":\"Bad Request\"}#end", "5(0[0-24-9]|[1-9][0-9])" = "{\"message\":\"Internal Server Error\"}"}
      binary_body      = false
      passthrough      = "never"
      success_template = "#set($item = $input.path('$.Item'))#set($payload = $input.path('$.Item.Payload.S'))#if(\"$!item\" == '')#set($context.responseOverride.status = 404){\"message\":\"Not Found\"}#elseif(\"$!payload\" != '')$payload#{else}$input.json('$.Item')#end"
      cache_keys       = ["method.request.path.id"]
    },
    {
      path            = "/items/{id}"
      uri             = "arn:aws:apigateway:us-east-1:dynamodb:action/DeleteItem"
      type            = "aws"
      methods         = ["delete"]
      method_security = {"delete" = [{ "api_key" = [] }]}
      enable_mock     = true
      credentials     = aws_iam_role.role_apigw_demo-rest-api_to_items.arn
      requestTemplates = {
        "application/json" = "#set($hashKey = $input.params('id'))#if($hashKey.matches('^([^%]|%[0-9A-Fa-f]{2})*$'))#set($hashKey = $util.urlDecode($hashKey.replace(\"+\",\"%2B\")))#end{\"TableName\": \"${aws_dynamodb_table.items.name}\", \"Key\": { \"id\": { \"S\": \"$util.escapeJavaScript($hashKey).replaceAll(\"\\\\'\",\"'\")\" } } }"
      }
      integ_method     = "POST"
      parameters       = [{"name": "id", "in": "path", "required": true, "schema": {"type": "string"}}]
      integ_req_params = null
      error_responses  = {"403" = "403", "404" = "404", "429" = "429", "503" = "503", "4(0[0-25-9]|1[0-9]|2[0-8]|[3-9][0-9])" = "400", "5(0[0-24-9]|[1-9][0-9])" = "500"}
      error_templates  = {"403" = "{\"message\":\"Forbidden\"}", "404" = "{\"message\":\"Not Found\"}", "429" = "{\"message\":\"Too Many Requests\"}", "503" = "{\"message\":\"Service Unavailable\"}", "4(0[0-25-9]|1[0-9]|2[0-8]|[3-9][0-9])" = "#set($type = $input.path('$.__type'))#if(!$type)#set($type = '')#end#if($type.contains(\"AccessDenied\"))#set($context.responseOverride.status = 403){\"message\":\"Forbidden\"}#elseif($type.contains(\"ResourceNotFound\"))#set($context.responseOverride.status = 404){\"message\":\"Not Found\"}#elseif($type.contains(\"Throughput\") || $type.contains(\"Throttl\") || $type.contains(\"LimitExceeded\"))#set($context.responseOverride.status = 429){\"message\":\"Too Many Requests\"}#{else}{\"message\":\"Bad Request\"}#end", "5(0[0-24-9]|[1-9][0-9])" = "{\"message\":\"Internal Server Error\"}"}
      binary_body      = false
      passthrough      = "never"
      success_template = null
      cache_keys       = ["method.request.path.id"]
    },
    {
      path            = "/items/{id}"
      uri             = "arn:aws:apigateway:us-east-1:dynamodb:action/PutItem"
      type            = "aws"
      methods         = ["post", "put"]
      method_security = {"post" = [{ "api_key" = [] }], "put" = [{ "api_key" = [] }]}
      enable_mock     = true
      credentials     = aws_iam_role.role_apigw_demo-rest-api_to_items.arn
      requestTemplates = {
        "application/json" = "#set($hashKey = $input.params('id'))#if($hashKey.matches('^([^%]|%[0-9A-Fa-f]{2})*$'))#set($hashKey = $util.urlDecode($hashKey.replace(\"+\",\"%2B\")))#end{\"TableName\": \"${aws_dynamodb_table.items.name}\", \"Item\": { \"id\": { \"S\": \"$util.escapeJavaScript($hashKey).replaceAll(\"\\\\'\",\"'\")\" }, \"Payload\": { \"S\": \"$util.escapeJavaScript($input.body).replaceAll(\"\\\\'\",\"'\")\" } } }"
        "text/plain"       = "#set($hashKey = $input.params('id'))#if($hashKey.matches('^([^%]|%[0-9A-Fa-f]{2})*$'))#set($hashKey = $util.urlDecode($hashKey.replace(\"+\",\"%2B\")))#end{\"TableName\": \"${aws_dynamodb_table.items.name}\", \"Item\": { \"id\": { \"S\": \"$util.escapeJavaScript($hashKey).replaceAll(\"\\\\'\",\"'\")\" }, \"Payload\": { \"S\": \"$util.escapeJavaScript($input.body).replaceAll(\"\\\\'\",\"'\")\" } } }"
      }
      integ_method     = "POST"
      parameters       = [{"name": "id", "in": "path", "required": true, "schema": {"type": "string"}}]
      integ_req_params = null
      error_responses  = {"403" = "403", "404" = "404", "429" = "429", "503" = "503", "4(0[0-25-9]|1[0-9]|2[0-8]|[3-9][0-9])" = "400", "5(0[0-24-9]|[1-9][0-9])" = "500"}
      error_templates  = {"403" = "{\"message\":\"Forbidden\"}", "404" = "{\"message\":\"Not Found\"}", "429" = "{\"message\":\"Too Many Requests\"}", "503" = "{\"message\":\"Service Unavailable\"}", "4(0[0-25-9]|1[0-9]|2[0-8]|[3-9][0-9])" = "#set($type = $input.path('$.__type'))#if(!$type)#set($type = '')#end#if($type.contains(\"AccessDenied\"))#set($context.responseOverride.status = 403){\"message\":\"Forbidden\"}#elseif($type.contains(\"ResourceNotFound\"))#set($context.responseOverride.status = 404){\"message\":\"Not Found\"}#elseif($type.contains(\"Throughput\") || $type.contains(\"Throttl\") || $type.contains(\"LimitExceeded\"))#set($context.responseOverride.status = 429){\"message\":\"Too Many Requests\"}#{else}{\"message\":\"Bad Request\"}#end", "5(0[0-24-9]|[1-9][0-9])" = "{\"message\":\"Internal Server Error\"}"}
      binary_body      = false
      passthrough      = "never"
      success_template = null
      cache_keys       = ["method.request.path.id"]
    },
    {
      path            = "/jobs"
      uri             = "arn:aws:apigateway:us-east-1:sqs:path/${data.aws_caller_identity.current.account_id}/${aws_sqs_queue.jobs.name}"
      type            = "aws"
      methods         = ["get", "post", "put", "delete"]
      method_security = {"get" = [{ "api_key" = [] }], "post" = [{ "api_key" = [] }], "put" = [{ "api_key" = [] }], "delete" = [{ "api_key" = [] }]}
      enable_mock     = true
      credentials     = aws_iam_role.role_apigw_demo-rest-api_to_jobs.arn
      requestTemplates = {
        "application/json"                  = "#set($method = $context.httpMethod)#if($method == 'POST' || $method == 'PUT')Action=SendMessage&MessageBody=$util.urlEncode($input.body)#elseif($method == 'GET')Action=ReceiveMessage&MaxNumberOfMessages=10&WaitTimeSeconds=20&VisibilityTimeout=30#elseif($method == 'DELETE')Action=DeleteMessage&ReceiptHandle=$util.urlEncode($input.params('receiptHandle'))#elseif($method == 'HEAD')Action=GetQueueAttributes&AttributeName=ApproximateNumberOfMessages#{else}Action=GetQueueAttributes#end"
        "application/x-www-form-urlencoded" = "#set($method = $context.httpMethod)#if($method == 'POST' || $method == 'PUT')Action=SendMessage&MessageBody=$util.urlEncode($input.body)#elseif($method == 'GET')Action=ReceiveMessage&MaxNumberOfMessages=10&WaitTimeSeconds=20&VisibilityTimeout=30#elseif($method == 'DELETE')Action=DeleteMessage&ReceiptHandle=$util.urlEncode($input.params('receiptHandle'))#elseif($method == 'HEAD')Action=GetQueueAttributes&AttributeName=ApproximateNumberOfMessages#{else}Action=GetQueueAttributes#end"
        "text/plain"                        = "#set($method = $context.httpMethod)#if($method == 'POST' || $method == 'PUT')Action=SendMessage&MessageBody=$util.urlEncode($input.body)#elseif($method == 'GET')Action=ReceiveMessage&MaxNumberOfMessages=10&WaitTimeSeconds=20&VisibilityTimeout=30#elseif($method == 'DELETE')Action=DeleteMessage&ReceiptHandle=$util.urlEncode($input.params('receiptHandle'))#elseif($method == 'HEAD')Action=GetQueueAttributes&AttributeName=ApproximateNumberOfMessages#{else}Action=GetQueueAttributes#end"
      }
      integ_method = "POST"
      parameters = [
          {
            "name": "receiptHandle",
            "in": "query",
            "required": false,
            "schema": { "type": "string" }
          }
        ]
      integ_req_params = {
        "integration.request.header.Content-Type" = "'application/x-www-form-urlencoded'"
      }
      error_responses  = {"403" = "403", "404" = "404", "429" = "429", "503" = "503", "4(0[0-25-9]|1[0-9]|2[0-8]|[3-9][0-9])" = "400", "5(0[0-24-9]|[1-9][0-9])" = "500"}
      error_templates  = {"403" = "{\"message\":\"Forbidden\"}", "404" = "{\"message\":\"Not Found\"}", "429" = "{\"message\":\"Too Many Requests\"}", "503" = "{\"message\":\"Service Unavailable\"}", "4(0[0-25-9]|1[0-9]|2[0-8]|[3-9][0-9])" = "{\"message\":\"Bad Request\"}", "5(0[0-24-9]|[1-9][0-9])" = "{\"message\":\"Internal Server Error\"}"}
      binary_body      = false
      passthrough      = "never"
      success_template = null
      cache_keys       = []
    },
    {
      path            = "/events"
      uri             = "arn:aws:apigateway:us-east-1:kinesis:action/PutRecord"
      type            = "aws"
      methods         = ["post", "put"]
      method_security = {"post" = [{ "api_key" = [] }], "put" = [{ "api_key" = [] }]}
      enable_mock     = true
      credentials     = aws_iam_role.role_apigw_demo-rest-api_to_events.arn
      requestTemplates = {
        "application/json"     = "#set($partition = $input.params('partitionKey'))#if(\"$!partition\" == '')#set($partition = $context.requestId)#end{\"StreamName\":\"${aws_kinesis_stream.events.name}\",\"Data\":\"$util.base64Encode($input.body)\",\"PartitionKey\":\"$util.escapeJavaScript($partition).replaceAll(\"\\\\'\",\"'\")\"}"
        "text/plain"           = "#set($partition = $input.params('partitionKey'))#if(\"$!partition\" == '')#set($partition = $context.requestId)#end{\"StreamName\":\"${aws_kinesis_stream.events.name}\",\"Data\":\"$util.base64Encode($input.body)\",\"PartitionKey\":\"$util.escapeJavaScript($partition).replaceAll(\"\\\\'\",\"'\")\"}"
        "text/csv"             = "#set($partition = $input.params('partitionKey'))#if(\"$!partition\" == '')#set($partition = $context.requestId)#end{\"StreamName\":\"${aws_kinesis_stream.events.name}\",\"Data\":\"$util.base64Encode($input.body)\",\"PartitionKey\":\"$util.escapeJavaScript($partition).replaceAll(\"\\\\'\",\"'\")\"}"
        "application/x-ndjson" = "#set($partition = $input.params('partitionKey'))#if(\"$!partition\" == '')#set($partition = $context.requestId)#end{\"StreamName\":\"${aws_kinesis_stream.events.name}\",\"Data\":\"$util.base64Encode($input.body)\",\"PartitionKey\":\"$util.escapeJavaScript($partition).replaceAll(\"\\\\'\",\"'\")\"}"
      }
      integ_method = "POST"
      parameters = [
          {
            "name": "partitionKey",
            "in": "query",
            "required": false,
            "schema": { "type": "string" }
          }
        ]
      integ_req_params = {
        "integration.request.header.Content-Type" = "'application/x-amz-json-1.1'"
      }
      error_responses  = {"403" = "403", "404" = "404", "429" = "429", "503" = "503", "4(0[0-25-9]|1[0-9]|2[0-8]|[3-9][0-9])" = "400", "5(0[0-24-9]|[1-9][0-9])" = "500"}
      error_templates  = {"403" = "{\"message\":\"Forbidden\"}", "404" = "{\"message\":\"Not Found\"}", "429" = "{\"message\":\"Too Many Requests\"}", "503" = "{\"message\":\"Service Unavailable\"}", "4(0[0-25-9]|1[0-9]|2[0-8]|[3-9][0-9])" = "#set($type = $input.path('$.__type'))#if(!$type)#set($type = '')#end#if($type.contains(\"AccessDenied\"))#set($context.responseOverride.status = 403){\"message\":\"Forbidden\"}#elseif($type.contains(\"ResourceNotFound\"))#set($context.responseOverride.status = 404){\"message\":\"Not Found\"}#elseif($type.contains(\"Throughput\") || $type.contains(\"Throttl\") || $type.contains(\"LimitExceeded\"))#set($context.responseOverride.status = 429){\"message\":\"Too Many Requests\"}#{else}{\"message\":\"Bad Request\"}#end", "5(0[0-24-9]|[1-9][0-9])" = "{\"message\":\"Internal Server Error\"}"}
      binary_body      = false
      passthrough      = "never"
      success_template = null
      cache_keys       = []
    },
  ]
  openapi_spec_demo-rest-api = {
      openapi = "3.0.1"
      info = {
        title   = "demo-rest-api"
        version = "1.0"
      }
      
      components = {
        securitySchemes = {
            "api_key" = {
              type = "apiKey"
              name = "x-api-key"
              in   = "header"
            }
        }
      }
      "x-amazon-apigateway-binary-media-types" = ["application/octet-stream", "binary/octet-stream", "application/pdf", "application/zip", "application/x-zip-compressed", "application/gzip", "application/x-gzip", "application/x-tar", "application/x-7z-compressed", "application/vnd.rar", "application/x-rar-compressed", "application/msword", "application/vnd.ms-excel", "application/vnd.ms-powerpoint", "application/vnd.openxmlformats-officedocument.wordprocessingml.document", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", "application/vnd.openxmlformats-officedocument.presentationml.presentation", "image/*", "audio/*", "video/*", "font/*"]
      "x-amazon-apigateway-gateway-responses" = {
        DEFAULT_4XX = {
          responseParameters = {
            "gatewayresponse.header.Access-Control-Allow-Origin" = "'*'"
          }
        }
        DEFAULT_5XX = {
          responseParameters = {
            "gatewayresponse.header.Access-Control-Allow-Origin" = "'*'"
          }
        }
      }
      paths = {
        for path in distinct([for i in local.api_config_demo-rest-api : i.path]) :
        path => merge([
          for item in local.api_config_demo-rest-api :
          merge(
            {
              for method in toset(item.methods) :
              method => merge(
                {
                  "responses" = merge({
                    "200" = {
                      description = "Successful operation"
                      headers = merge({
                        "Access-Control-Allow-Origin" = { schema = { type = "string" } }
                        "Set-Cookie"                  = { schema = { type = "string" } }
                      }, item.binary_body ? {
                        "Content-Type"            = { schema = { type = "string" } }
                        "X-Content-Type-Options"  = { schema = { type = "string" } }
                        "Content-Security-Policy" = { schema = { type = "string" } }
                        "ETag"                    = { schema = { type = "string" } }
                        "Last-Modified"           = { schema = { type = "string" } }
                        "Cache-Control"           = { schema = { type = "string" } }
                        "Content-Disposition"     = { schema = { type = "string" } }
                        "Content-Encoding"        = { schema = { type = "string" } }
                      } : {})
                    }
                  }, {
                    for code in distinct(values(item.error_responses)) : code => {
                      description = "Error returned by the integration"
                      headers = {
                        "Access-Control-Allow-Origin" = { schema = { type = "string" } }
                      }
                    }
                  })
                  "x-amazon-apigateway-integration" = merge(
                    {
                      uri        = item.uri
                      httpMethod = item.integ_method == "MATCH" ? upper(method) : item.integ_method
                      type       = item.type
                    },
                    item.type == "aws_proxy" ? {} : {
                      responses = merge({
                        "default" = merge({
                          statusCode = "200"
                          responseParameters = merge({
                            "method.response.header.Access-Control-Allow-Origin" = "'*'"
                          }, item.binary_body ? {
                            "method.response.header.Content-Type"            = "integration.response.header.Content-Type"
                            "method.response.header.X-Content-Type-Options"  = "'nosniff'"
                            "method.response.header.Content-Security-Policy" = "'sandbox'"
                            "method.response.header.ETag"                    = "integration.response.header.ETag"
                            "method.response.header.Last-Modified"           = "integration.response.header.Last-Modified"
                            "method.response.header.Cache-Control"           = "integration.response.header.Cache-Control"
                            "method.response.header.Content-Disposition"     = "integration.response.header.Content-Disposition"
                            "method.response.header.Content-Encoding"        = "integration.response.header.Content-Encoding"
                          } : {})
                        }, item.binary_body ? {} : {
                          responseTemplates = {
                            "application/json" = item.success_template != null ? item.success_template : "$input.body"
                          }
                        })
                      }, {
                        for pattern, code in item.error_responses : pattern => {
                          statusCode = code
                          responseParameters = {
                            "method.response.header.Access-Control-Allow-Origin" = "'*'"
                          }
                          responseTemplates = {
                            "application/json" = item.error_templates[pattern]
                          }
                        }
                      })
                    },
                    item.credentials != null ? { credentials = item.credentials } : {},
                    item.requestTemplates != null ? { requestTemplates = item.requestTemplates } : {},
                    item.passthrough != null ? { passthroughBehavior = item.passthrough } : {},
                    length(item.cache_keys) > 0 ? { cacheKeyParameters = item.cache_keys } : {},
                    item.integ_req_params != null ? { requestParameters = item.integ_req_params } : {}
                  )
                },
                item.parameters != null ? { parameters = item.parameters } : {},
                contains(keys(item.method_security), method) ? {
                  security = item.method_security[method]
                } : {}
              )
              if method != "options"
            },
            item.enable_mock ? { "options" = {
          summary  = "CORS support"
          security = []  # <--- CORREÇÃO 1: Anula o authorizer global para o OPTIONS
          responses = {
            "200" = {
              description = "200 response"
              headers = {
                "Access-Control-Allow-Origin"  = { schema = { type = "string" } }
                "Access-Control-Allow-Methods" = { schema = { type = "string" } }
                "Access-Control-Allow-Headers" = { schema = { type = "string" } }
              }
            }
          }
          "x-amazon-apigateway-integration" = {
            type             = "mock"
            requestTemplates = { "application/json" = "{\"statusCode\": 200}" }
            responses = {
              default = {
                statusCode = "200"
                responseParameters = {
                  "method.response.header.Access-Control-Allow-Methods" = "'DELETE,GET,OPTIONS,POST,PUT'"
                  "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
                  "method.response.header.Access-Control-Allow-Origin"  = "'*'"
                }
              }
            }
          }
        } } : {}
          )
          if item.path == path
        ]...)
      }
    }
}

resource "aws_api_gateway_rest_api" "demo-rest-api" {
  name               = "demo-rest-api"
  binary_media_types = ["application/octet-stream", "binary/octet-stream", "application/pdf", "application/zip", "application/x-zip-compressed", "application/gzip", "application/x-gzip", "application/x-tar", "application/x-7z-compressed", "application/vnd.rar", "application/x-rar-compressed", "application/msword", "application/vnd.ms-excel", "application/vnd.ms-powerpoint", "application/vnd.openxmlformats-officedocument.wordprocessingml.document", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", "application/vnd.openxmlformats-officedocument.presentationml.presentation", "image/*", "audio/*", "video/*", "font/*"]
  body               = jsonencode(local.openapi_spec_demo-rest-api)
  description        = "Regional REST API. Routes are generated from the OpenAPI spec (demo-api-spec), each integration pointing to a service. Requires an API key on every method (api_key_required)."
  endpoint_configuration {
    types = ["REGIONAL"]
  }
  tags = {
    Name           = "demo-rest-api"
    State          = "apigw-lambda-state"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_iam_role.role_apigw_demo-rest-api_to_assets, aws_iam_role.role_apigw_demo-rest-api_to_items, aws_iam_role.role_apigw_demo-rest-api_to_jobs, aws_iam_role.role_apigw_demo-rest-api_to_events, aws_iam_role_policy.policy_role_apigw_demo-rest-api_to_assets, aws_iam_role_policy.policy_role_apigw_demo-rest-api_to_items, aws_iam_role_policy.policy_role_apigw_demo-rest-api_to_jobs, aws_iam_role_policy.policy_role_apigw_demo-rest-api_to_events]
}

resource "aws_api_gateway_stage" "prod" {
  deployment_id = aws_api_gateway_deployment.demo-deployment.id
  rest_api_id   = aws_api_gateway_rest_api.demo-rest-api.id
  stage_name    = "prod"
  tags = {
    Name           = "prod"
    State          = "apigw-lambda-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_api_gateway_usage_plan" "demo-usage-plan" {
  name        = "demo-usage-plan"
  description = "Usage plan binding the API key to the prod stage. Sets quota (10,000 req/month) and throttle (rate 10/s, burst 20)."
  api_stages {
    api_id = aws_api_gateway_stage.prod.rest_api_id
    stage  = aws_api_gateway_stage.prod.stage_name
  }
  quota_settings {
    limit  = 10000
    period = "MONTH"
  }
  tags = {
    Name           = "demo-usage-plan"
    State          = "apigw-lambda-state"
    Struct8Creator = "Contato Struct"
  }
  throttle_settings {
    burst_limit = 20
    rate_limit  = 10
  }
}

resource "aws_api_gateway_usage_plan_key" "UsagePlanKey" {
  key_id        = aws_api_gateway_api_key.demo-api-key.id
  usage_plan_id = aws_api_gateway_usage_plan.demo-usage-plan.id
  key_type      = "API_KEY"
}




### CATEGORY: STORAGE ###

resource "aws_s3_bucket" "assets" {
  bucket              = "assets-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.region}-an"
  bucket_namespace    = "account-regional"
  force_destroy       = true
  object_lock_enabled = false
  tags = {
    Name           = "assets"
    State          = "apigw-lambda-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_s3_bucket_ownership_controls" "assets_controls" {
  bucket = aws_s3_bucket.assets.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "assets_block" {
  block_public_acls       = true
  block_public_policy     = true
  bucket                  = aws_s3_bucket.assets.id
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "assets_configuration" {
  bucket = aws_s3_bucket.assets.id
  rule {
    bucket_key_enabled = true
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "assets_versioning" {
  bucket = aws_s3_bucket.assets.id
  versioning_configuration {
    mfa_delete = "Disabled"
    status     = "Suspended"
  }
}




### CATEGORY: DATABASE ###

resource "aws_dynamodb_table" "items" {
  name                        = "items"
  billing_mode                = "PAY_PER_REQUEST"
  deletion_protection_enabled = false
  hash_key                    = "id"
  stream_enabled              = false
  table_class                 = "STANDARD"
  attribute {
    name = "id"
    type = "S"
  }
  tags = {
    Name           = "items"
    State          = "apigw-lambda-state"
    Struct8Creator = "Contato Struct"
  }
}




### CATEGORY: COMPUTE ###

data "archive_file" "archive_struct8-hub_demo-handler" {
  output_path = "${path.module}/struct8-hub_demo-handler.zip"
  source_dir  = "${path.module}/.external_modules/struct8-hub/prebuilt"
  type        = "zip"
}

resource "aws_lambda_function" "demo-handler" {
  function_name                  = "demo-handler"
  architectures                  = ["arm64"]
  description                    = "API backend Lambda. Code comes from the public struct8-hub repo, prebuilt folder (runtime nodejs22.x, handler index.handler). Handles requests routed to /demo-handler."
  filename                       = data.archive_file.archive_struct8-hub_demo-handler.output_path
  handler                        = "index.handler"
  memory_size                    = 3008
  publish                        = false
  reserved_concurrent_executions = -1
  role                           = aws_iam_role.demo-handler_role.arn
  runtime                        = "nodejs22.x"
  source_code_hash               = data.archive_file.archive_struct8-hub_demo-handler.output_base64sha256
  timeout                        = 30
  environment {
    variables = {
    NAME    = "demo-handler"
    REGION  = data.aws_region.current.region
    ACCOUNT = data.aws_caller_identity.current.account_id
  }
  }
  tags = {
    Name           = "demo-handler"
    State          = "apigw-lambda-state"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_iam_role_policy_attachment.lambda_function_demo-handler_st_apigw-lambda-state_attach]
}

resource "aws_lambda_permission" "perm_aws_api_gateway_rest_api_demo-rest-api_to_demo-handler_openapi" {
  function_name = aws_lambda_function.demo-handler.function_name
  statement_id  = "perm_aws_api_gateway_rest_api_demo-rest-api_to_demo-handler_openapi"
  principal     = "apigateway.amazonaws.com"
  action        = "lambda:InvokeFunction"
  source_arn    = "${aws_api_gateway_rest_api.demo-rest-api.execution_arn}/*/*/demo-handler"
}




### CATEGORY: INTEGRATION ###

resource "aws_sqs_queue" "jobs" {
  name                              = "jobs"
  delay_seconds                     = 0
  fifo_queue                        = false
  kms_data_key_reuse_period_seconds = 300
  max_message_size                  = 262144
  message_retention_seconds         = 345600
  receive_wait_time_seconds         = 0
  sqs_managed_sse_enabled           = true
  visibility_timeout_seconds        = 30
  tags = {
    Name           = "jobs"
    State          = "apigw-lambda-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_kinesis_stream" "events" {
  name        = "events"
  shard_count = 1
  stream_mode_details {
    stream_mode = "PROVISIONED"
  }
  tags = {
    Name           = "events"
    State          = "apigw-lambda-state"
    Struct8Creator = "Contato Struct"
  }
}




### CATEGORY: MONITORING ###

resource "aws_cloudwatch_log_group" "demo-handler-logs" {
  name              = "/aws/lambda/demo-handler"
  log_group_class   = "STANDARD"
  retention_in_days = 1
  skip_destroy      = false
  tags = {
    Name           = "demo-handler-logs"
    State          = "apigw-lambda-state"
    Struct8Creator = "Contato Struct"
  }
}


