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
    key     = "952133486861/wp-analytics/main.tfstate"
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




### CATEGORY: IAM ###

data "aws_iam_policy_document" "cloudfront_realtime_log_config_cdnLogConfig_st_wp-analytics_doc" {
  statement {
    sid       = "AllowCdnToWriteLog"
    effect    = "Allow"
    actions   = ["kinesis:DescribeStream", "kinesis:DescribeStreamSummary", "kinesis:PutRecord", "kinesis:PutRecords"]
    resources = [aws_kinesis_stream.cdnLogStream.arn]
  }
}

resource "aws_iam_policy" "cloudfront_realtime_log_config_cdnLogConfig_st_wp-analytics" {
  name        = "cloudfront_realtime_log_config_cdnLogConfig_st_wp-analytics"
  description = "Access Policy for cdnLogConfig"
  policy      = data.aws_iam_policy_document.cloudfront_realtime_log_config_cdnLogConfig_st_wp-analytics_doc.json
}

data "aws_iam_policy_document" "kinesis_firehose_delivery_stream_cdnLogFirehose_st_wp-analytics_doc" {
  statement {
    sid       = "AllowFirehoseToReadLog"
    effect    = "Allow"
    actions   = ["kinesis:DescribeStream", "kinesis:DescribeStreamSummary", "kinesis:GetRecords", "kinesis:GetShardIterator", "kinesis:ListShards"]
    resources = [aws_kinesis_stream.cdnLogStream.arn]
  }
  statement {
    sid       = "AllowBucketLevelActions"
    effect    = "Allow"
    actions   = ["s3:GetBucketLocation", "s3:ListBucket", "s3:ListBucketMultipartUploads"]
    resources = [aws_s3_bucket.cdnLogBucket.arn]
  }
  statement {
    sid       = "AllowObjectDelivery"
    effect    = "Allow"
    actions   = ["s3:AbortMultipartUpload", "s3:GetObject", "s3:PutObject"]
    resources = ["${aws_s3_bucket.cdnLogBucket.arn}/*"]
  }
}

resource "aws_iam_policy" "kinesis_firehose_delivery_stream_cdnLogFirehose_st_wp-analytics" {
  name        = "kinesis_firehose_delivery_stream_cdnLogFirehose_st_wp-analytics"
  description = "Access Policy for cdnLogFirehose"
  policy      = data.aws_iam_policy_document.kinesis_firehose_delivery_stream_cdnLogFirehose_st_wp-analytics_doc.json
}

data "aws_iam_policy_document" "lambda_function_analyticsPage_st_wp-analytics_doc" {
  statement {
    sid       = "AllowRunQueriesInWorkgroup"
    effect    = "Allow"
    actions   = ["athena:GetQueryExecution", "athena:GetQueryResults", "athena:StartQueryExecution", "athena:StopQueryExecution"]
    resources = [aws_athena_workgroup.cdnAnalytics.arn]
  }
  statement {
    sid       = "AllowWriteLogs"
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.analyticsPageLogs.arn}:*"]
  }
  statement {
    sid       = "AllowReadTable"
    effect    = "Allow"
    actions   = ["glue:GetTable"]
    resources = [aws_glue_catalog_table.cdn_log.arn, "arn:aws:glue:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:catalog", "arn:aws:glue:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:database/${aws_glue_catalog_table.cdn_log.database_name}"]
  }
  statement {
    sid       = "AllowBucketLevelActions"
    effect    = "Allow"
    actions   = ["s3:GetBucketLocation", "s3:ListBucket"]
    resources = [aws_s3_bucket.cdnLogBucket.arn]
  }
  statement {
    sid       = "AllowQueryResults"
    effect    = "Allow"
    actions   = ["s3:AbortMultipartUpload", "s3:GetObject", "s3:ListMultipartUploadParts", "s3:PutObject"]
    resources = ["${aws_s3_bucket.cdnLogBucket.arn}/*.csv", "${aws_s3_bucket.cdnLogBucket.arn}/*.csv.metadata"]
  }
  statement {
    sid       = "AllowReadLog"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.cdnLogBucket.arn}/cdn-log/*"]
  }
  statement {
    sid       = "AllowReadDatabase"
    effect    = "Allow"
    actions   = ["glue:GetDatabase"]
    resources = ["arn:aws:glue:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:catalog", "arn:aws:glue:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:database/${aws_glue_catalog_table.cdn_log.database_name}"]
  }
}

resource "aws_iam_policy" "lambda_function_analyticsPage_st_wp-analytics" {
  name        = "lambda_function_analyticsPage_st_wp-analytics"
  description = "Access Policy for analyticsPage"
  policy      = data.aws_iam_policy_document.lambda_function_analyticsPage_st_wp-analytics_doc.json
}

data "aws_iam_policy_document" "lambda_function_cspReceiver_st_wp-analytics_doc" {
  statement {
    sid       = "AllowWriteLogs"
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.cspReceiverLogs.arn}:*"]
  }
  statement {
    sid       = "AllowCountReports"
    effect    = "Allow"
    actions   = ["dynamodb:UpdateItem"]
    resources = [aws_dynamodb_table.cspTable.arn]
  }
}

resource "aws_iam_policy" "lambda_function_cspReceiver_st_wp-analytics" {
  name        = "lambda_function_cspReceiver_st_wp-analytics"
  description = "Access Policy for cspReceiver"
  policy      = data.aws_iam_policy_document.lambda_function_cspReceiver_st_wp-analytics_doc.json
}

resource "aws_iam_role" "analyticsPage_role" {
  name = "analyticsPage_role"
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
    Name           = "analyticsPage_role"
    State          = "wp-analytics"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "cdnLogConfig_role" {
  name = "cdnLogConfig_role"
  assume_role_policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudfront.amazonaws.com"
      }
    }
  ]
})
  force_detach_policies = false
  max_session_duration  = 3600
  path                  = "/"
  tags = {
    Name           = "cdnLogConfig_role"
    State          = "wp-analytics"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "cdnLogFirehose_role" {
  name = "cdnLogFirehose_role"
  assume_role_policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": "firehose.amazonaws.com"
      }
    }
  ]
})
  force_detach_policies = false
  max_session_duration  = 3600
  path                  = "/"
  tags = {
    Name           = "cdnLogFirehose_role"
    State          = "wp-analytics"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "cspReceiver_role" {
  name = "cspReceiver_role"
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
    Name           = "cspReceiver_role"
    State          = "wp-analytics"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role_policy_attachment" "cloudfront_realtime_log_config_cdnLogConfig_st_wp-analytics_attach" {
  policy_arn = aws_iam_policy.cloudfront_realtime_log_config_cdnLogConfig_st_wp-analytics.arn
  role       = aws_iam_role.cdnLogConfig_role.name
}

resource "aws_iam_role_policy_attachment" "kinesis_firehose_delivery_stream_cdnLogFirehose_st_wp-analytics_attach" {
  policy_arn = aws_iam_policy.kinesis_firehose_delivery_stream_cdnLogFirehose_st_wp-analytics.arn
  role       = aws_iam_role.cdnLogFirehose_role.name
}

resource "aws_iam_role_policy_attachment" "lambda_function_analyticsPage_st_wp-analytics_attach" {
  policy_arn = aws_iam_policy.lambda_function_analyticsPage_st_wp-analytics.arn
  role       = aws_iam_role.analyticsPage_role.name
}

resource "aws_iam_role_policy_attachment" "lambda_function_cspReceiver_st_wp-analytics_attach" {
  policy_arn = aws_iam_policy.lambda_function_cspReceiver_st_wp-analytics.arn
  role       = aws_iam_role.cspReceiver_role.name
}




### CATEGORY: NETWORK ###

resource "aws_cloudfront_realtime_log_config" "cdnLogConfig" {
  name          = "cdnLogConfig"
  fields        = ["timestamp", "c-country", "cs-method", "cs-uri-stem", "cs-uri-query", "sc-status", "sc-bytes", "time-taken", "cs-user-agent", "cs-referer", "x-edge-result-type", "x-edge-detailed-result-type", "cache-behavior-path-pattern"]
  sampling_rate = 100
  endpoint {
    stream_type = "Kinesis"
    kinesis_stream_config {
      role_arn   = aws_iam_role.cdnLogConfig_role.arn
      stream_arn = aws_kinesis_stream.cdnLogStream.arn
    }
  }
  depends_on = [aws_iam_role_policy_attachment.cloudfront_realtime_log_config_cdnLogConfig_st_wp-analytics_attach]
}

resource "aws_cloudfront_response_headers_policy" "cspReportOnly" {
  name    = "cspReportOnly"
  comment = "Copies the security headers of Managed-SecurityHeadersPolicy and adds a report-only CSP."
  custom_headers_config {
    items {
      header   = "Content-Security-Policy-Report-Only"
      override = true
      value    = "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self' data: https:; connect-src 'self' https:; frame-src 'self' https:; object-src 'none'; base-uri 'self'; form-action 'self'; frame-ancestors 'self'; report-uri ${aws_lambda_function_url.cspReceiverUrl.function_url}"
    }
  }
  security_headers_config {
    content_type_options {
      override = true
    }
    frame_options {
      frame_option = "SAMEORIGIN"
      override     = false
    }
    referrer_policy {
      override        = false
      referrer_policy = "strict-origin-when-cross-origin"
    }
    strict_transport_security {
      access_control_max_age_sec = 31536000
      override                   = false
    }
    xss_protection {
      mode_block = true
      override   = false
      protection = true
    }
  }
}




### CATEGORY: STORAGE ###

resource "aws_s3_bucket" "cdnLogBucket" {
  bucket              = "cdnlogbucket-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.region}-an"
  bucket_namespace    = "account-regional"
  force_destroy       = true
  object_lock_enabled = false
  tags = {
    Name           = "cdnLogBucket"
    State          = "wp-analytics"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_s3_bucket_ownership_controls" "cdnLogBucket_controls" {
  bucket = aws_s3_bucket.cdnLogBucket.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "cdnLogBucket_block" {
  block_public_acls       = true
  block_public_policy     = true
  bucket                  = aws_s3_bucket.cdnLogBucket.id
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cdnLogBucket_configuration" {
  bucket = aws_s3_bucket.cdnLogBucket.id
  rule {
    bucket_key_enabled = true
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "cdnLogBucket_versioning" {
  bucket = aws_s3_bucket.cdnLogBucket.id
  versioning_configuration {
    mfa_delete = "Disabled"
    status     = "Suspended"
  }
}




### CATEGORY: DATABASE ###

resource "aws_dynamodb_table" "cspTable" {
  name                        = "cspTable"
  billing_mode                = "PROVISIONED"
  deletion_protection_enabled = false
  hash_key                    = "pk"
  range_key                   = "sk"
  read_capacity               = 3
  stream_enabled              = false
  table_class                 = "STANDARD"
  write_capacity              = 3
  attribute {
    name = "pk"
    type = "S"
  }
  attribute {
    name = "sk"
    type = "S"
  }
  lifecycle {
    ignore_changes = [read_capacity]
  }
  tags = {
    Name           = "cspTable"
    State          = "wp-analytics"
    Struct8Creator = "Contato Struct"
  }
  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }
}




### CATEGORY: COMPUTE ###

data "archive_file" "archive_struct8-templates_analyticsPage" {
  output_path = "${path.module}/struct8-templates_analyticsPage.zip"
  source_dir  = "${path.module}/.external_modules/struct8-templates/templates/wordpress-professional/v1/lambda/analytics"
  type        = "zip"
}

resource "aws_lambda_function" "analyticsPage" {
  function_name                  = "analyticsPage"
  architectures                  = ["arm64"]
  description                    = "Analytics page: runs the CDN log queries in Athena and returns HTML."
  filename                       = data.archive_file.archive_struct8-templates_analyticsPage.output_path
  handler                        = "index.handler"
  memory_size                    = 1900
  publish                        = false
  reserved_concurrent_executions = -1
  role                           = aws_iam_role.analyticsPage_role.arn
  runtime                        = "python3.13"
  source_code_hash               = data.archive_file.archive_struct8-templates_analyticsPage.output_base64sha256
  timeout                        = 60
  environment {
    variables = {
    ATHENA_WORKGROUP               = aws_athena_workgroup.cdnAnalytics.name
    GLUE_DATABASE                  = aws_glue_catalog_database.cdn_analytics.name
    GLUE_TABLE                     = aws_glue_catalog_table.cdn_log.name
    NAME                           = "analyticsPage"
    REGION                         = data.aws_region.current.region
    ACCOUNT                        = data.aws_caller_identity.current.account_id
    AWS_LAMBDA_FUNCTION_URL_NAME_0 = "analyticsUrl"
    AWS_S3_BUCKET_NAME_0           = "cdnlogbucket-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.region}-an"
    AWS_ATHENA_WORKGROUP_NAME_0    = "cdnAnalytics"
    AWS_GLUE_CATALOG_TABLE_NAME_0  = "cdn_log"
  }
  }
  tags = {
    Name           = "analyticsPage"
    State          = "wp-analytics"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_iam_role_policy_attachment.lambda_function_analyticsPage_st_wp-analytics_attach]
}

data "archive_file" "archive_struct8-templates_cspReceiver" {
  output_path = "${path.module}/struct8-templates_cspReceiver.zip"
  source_dir  = "${path.module}/.external_modules/struct8-templates/templates/wordpress-professional/v1/lambda/csp-receiver"
  type        = "zip"
}

resource "aws_lambda_function" "cspReceiver" {
  function_name                  = "cspReceiver"
  architectures                  = ["arm64"]
  description                    = "Receives CSP violation reports from browsers and counts them in cspTable."
  filename                       = data.archive_file.archive_struct8-templates_cspReceiver.output_path
  handler                        = "index.handler"
  memory_size                    = 256
  publish                        = false
  reserved_concurrent_executions = -1
  role                           = aws_iam_role.cspReceiver_role.arn
  runtime                        = "python3.13"
  source_code_hash               = data.archive_file.archive_struct8-templates_cspReceiver.output_base64sha256
  timeout                        = 10
  environment {
    variables = {
    NAME                           = "cspReceiver"
    REGION                         = data.aws_region.current.region
    ACCOUNT                        = data.aws_caller_identity.current.account_id
    AWS_LAMBDA_FUNCTION_URL_NAME_0 = "cspReceiverUrl"
    AWS_DYNAMODB_TABLE_NAME_0      = "cspTable"
    SITE_HOST                      = "wp.cloudman.pro"
  }
  }
  tags = {
    Name           = "cspReceiver"
    State          = "wp-analytics"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_iam_role_policy_attachment.lambda_function_cspReceiver_st_wp-analytics_attach]
}

resource "aws_lambda_function_url" "analyticsUrl" {
  function_name      = aws_lambda_function.analyticsPage.function_name
  authorization_type = "AWS_IAM"
}

resource "aws_lambda_function_url" "cspReceiverUrl" {
  function_name      = aws_lambda_function.cspReceiver.function_name
  authorization_type = "NONE"
}

resource "aws_lambda_permission" "perm_aws_lambda_function_url_cspReceiverUrl_to_cspReceiver" {
  function_name          = aws_lambda_function.cspReceiver.function_name
  statement_id           = "perm_aws_lambda_function_url_cspReceiverUrl_to_cspReceiver"
  principal              = "*"
  action                 = "lambda:InvokeFunctionUrl"
  function_url_auth_type = "NONE"
}

resource "aws_lambda_permission" "perm_aws_lambda_function_url_cspReceiverUrl_to_cspReceiver_invoke" {
  function_name            = aws_lambda_function.cspReceiver.function_name
  statement_id             = "perm_aws_lambda_function_url_cspReceiverUrl_to_cspReceiver_invoke"
  principal                = "*"
  action                   = "lambda:InvokeFunction"
  invoked_via_function_url = true
}

resource "aws_appautoscaling_policy" "sc_policy_Read_cspTable" {
  name               = "DynamoDBReadCapacityUtilization:sc_target_Read_cspTable"
  resource_id        = aws_appautoscaling_target.sc_target_Read_cspTable.resource_id
  policy_type        = "TargetTrackingScaling"
  scalable_dimension = aws_appautoscaling_target.sc_target_Read_cspTable.scalable_dimension
  service_namespace  = aws_appautoscaling_target.sc_target_Read_cspTable.service_namespace
  target_tracking_scaling_policy_configuration {
    target_value = 70.0
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBReadCapacityUtilization"
    }
  }
}

resource "aws_appautoscaling_target" "sc_target_Read_cspTable" {
  resource_id        = "table/${aws_dynamodb_table.cspTable.name}"
  max_capacity       = 20
  min_capacity       = 5
  scalable_dimension = "dynamodb:table:ReadCapacityUnits"
  service_namespace  = "dynamodb"
  tags = {
    Name           = "sc_target_Read_cspTable"
    State          = "wp-analytics"
    Struct8Creator = "Contato Struct"
  }
}




### CATEGORY: ANALYTICS ###

resource "aws_glue_catalog_database" "cdn_analytics" {
  name = "cdn_analytics"
  tags = {
    Name           = "cdn_analytics"
    State          = "wp-analytics"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_glue_catalog_table" "cdn_log" {
  database_name = aws_glue_catalog_database.cdn_analytics.name
  name          = "cdn_log"
  parameters = {
    "projection.enabled"        = "true"
    "projection.year.type"      = "integer"
    "projection.year.range"     = "2026,2036"
    "projection.month.type"     = "integer"
    "projection.month.range"    = "1,12"
    "projection.month.digits"   = "2"
    "projection.day.type"       = "integer"
    "projection.day.range"      = "1,31"
    "projection.day.digits"     = "2"
    "storage.location.template" = "s3://${aws_s3_bucket.cdnLogBucket.bucket}/cdn-log/year=$${year}/month=$${month}/day=$${day}/"
  }
  table_type = "EXTERNAL_TABLE"
  partition_keys {
    name = "year"
    type = "string"
  }
  partition_keys {
    name = "month"
    type = "string"
  }
  partition_keys {
    name = "day"
    type = "string"
  }
  storage_descriptor {
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    location      = "s3://${aws_s3_bucket.cdnLogBucket.bucket}/cdn-log/"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"
    columns {
      name    = "ts"
      comment = "Time of the request, in seconds since 1970."
      type    = "double"
    }
    columns {
      name    = "status"
      comment = "HTTP status the CDN answered."
      type    = "int"
    }
    columns {
      name    = "bytes"
      comment = "Bytes the CDN sent."
      type    = "bigint"
    }
    columns {
      name    = "method"
      comment = "HTTP method."
      type    = "string"
    }
    columns {
      name    = "uri_stem"
      comment = "Path of the request, including the query string. Use split_part(uri_stem, '?', 1) for the path alone."
      type    = "string"
    }
    columns {
      name    = "time_taken"
      comment = "Seconds from the request to the last byte."
      type    = "double"
    }
    columns {
      name    = "user_agent"
      comment = "User-Agent header."
      type    = "string"
    }
    columns {
      name    = "referer"
      comment = "Referer header."
      type    = "string"
    }
    columns {
      name    = "uri_query"
      comment = "Query string."
      type    = "string"
    }
    columns {
      name    = "edge_result_type"
      comment = "Hit, Miss, RefreshHit, Error..."
      type    = "string"
    }
    columns {
      name    = "edge_detailed_result_type"
      comment = "Detailed result, such as a response from the WAF."
      type    = "string"
    }
    columns {
      name    = "country"
      comment = "Two-letter country of the visitor."
      type    = "string"
    }
    columns {
      name    = "behavior_path"
      comment = "Path pattern of the cache behavior that served the request."
      type    = "string"
    }
    ser_de_info {
      parameters = {
        "field.delim"          = "\t"
        "serialization.format" = "1"
      }
      serialization_library = "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe"
    }
  }
}

resource "aws_athena_named_query" "cacheAndErrors" {
  name        = "cacheAndErrors"
  database    = aws_glue_catalog_database.cdn_analytics.name
  description = "Result of each request (hit, miss, error) and the average time, per path pattern."
  query = <<EOF
SELECT behavior_path, edge_result_type, count(*) AS requests,
  round(avg(time_taken), 3) AS avg_seconds, sum(bytes) AS bytes
FROM cdn_log
WHERE concat(year, month, day) >= date_format(current_date - interval '1' day, '%Y%m%d')
GROUP BY 1, 2
ORDER BY requests DESC;
  EOF
  workgroup = aws_athena_workgroup.cdnAnalytics.name
}

resource "aws_athena_named_query" "shopFunnel" {
  name        = "shopFunnel"
  database    = aws_glue_catalog_database.cdn_analytics.name
  description = "Requests to each step of the purchase, per day."
  query = <<EOF
SELECT concat(year, '-', month, '-', day) AS day,
  count_if(split_part(uri_stem, '?', 1) LIKE '/product/%') AS product_views,
  count_if(split_part(uri_stem, '?', 1) = '/cart/') AS cart_views,
  count_if(split_part(uri_stem, '?', 1) LIKE '/checkout/%' AND method = 'GET') AS checkout_views,
  count_if(split_part(uri_stem, '?', 1) LIKE '/wp-json/wc/store/v1/checkout%' AND method = 'POST') AS orders_placed
FROM cdn_log
WHERE concat(year, month, day) >= date_format(current_date - interval '14' day, '%Y%m%d')
GROUP BY 1
ORDER BY 1 DESC;
  EOF
  workgroup = aws_athena_workgroup.cdnAnalytics.name
}

resource "aws_athena_named_query" "topPages" {
  name        = "topPages"
  database    = aws_glue_catalog_database.cdn_analytics.name
  description = "Most viewed pages in the last 7 days, bots included."
  query = <<EOF
SELECT split_part(uri_stem, '?', 1) AS page, count(*) AS requests
FROM cdn_log
WHERE concat(year, month, day) >= date_format(current_date - interval '7' day, '%Y%m%d')
  AND method = 'GET' AND status = 200 AND behavior_path = '*'
GROUP BY 1
ORDER BY requests DESC
LIMIT 50;
  EOF
  workgroup = aws_athena_workgroup.cdnAnalytics.name
}

resource "aws_athena_named_query" "visitsByCountry" {
  name        = "visitsByCountry"
  database    = aws_glue_catalog_database.cdn_analytics.name
  description = "Requests per country and day, last 7 days."
  query = <<EOF
SELECT concat(year, '-', month, '-', day) AS day, country, count(*) AS requests
FROM cdn_log
WHERE concat(year, month, day) >= date_format(current_date - interval '7' day, '%Y%m%d')
  AND behavior_path = '*'
GROUP BY 1, 2
ORDER BY 1 DESC, 3 DESC;
  EOF
  workgroup = aws_athena_workgroup.cdnAnalytics.name
}

resource "aws_athena_workgroup" "cdnAnalytics" {
  name          = "cdnAnalytics"
  force_destroy = true
  configuration {
    bytes_scanned_cutoff_per_query = 10737418240
    result_configuration {
      output_location = "s3://${aws_s3_bucket.cdnLogBucket.id}"
      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }
  }
  tags = {
    Name           = "cdnAnalytics"
    State          = "wp-analytics"
    Struct8Creator = "Contato Struct"
  }
}




### CATEGORY: INTEGRATION ###

resource "aws_kinesis_firehose_delivery_stream" "cdnLogFirehose" {
  name        = "cdnLogFirehose"
  destination = "extended_s3"
  extended_s3_configuration {
    bucket_arn          = aws_s3_bucket.cdnLogBucket.arn
    buffering_size      = 64
    compression_format  = "GZIP"
    error_output_prefix = "cdn-log-errors/!{firehose:error-output-type}/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/"
    prefix              = "cdn-log/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/"
    role_arn            = aws_iam_role.cdnLogFirehose_role.arn
  }
  kinesis_source_configuration {
    kinesis_stream_arn = aws_kinesis_stream.cdnLogStream.arn
    role_arn           = aws_iam_role.cdnLogFirehose_role.arn
  }
  tags = {
    Name           = "cdnLogFirehose"
    State          = "wp-analytics"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_iam_role_policy_attachment.kinesis_firehose_delivery_stream_cdnLogFirehose_st_wp-analytics_attach]
}

resource "aws_kinesis_stream" "cdnLogStream" {
  name        = "cdnLogStream"
  shard_count = 1
  tags = {
    Name           = "cdnLogStream"
    State          = "wp-analytics"
    Struct8Creator = "Contato Struct"
  }
}




### CATEGORY: MONITORING ###

resource "aws_cloudwatch_log_group" "analyticsPageLogs" {
  name              = "/aws/lambda/analyticsPage"
  log_group_class   = "STANDARD"
  retention_in_days = 7
  skip_destroy      = false
  tags = {
    Name           = "analyticsPageLogs"
    State          = "wp-analytics"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_cloudwatch_log_group" "cspReceiverLogs" {
  name              = "/aws/lambda/cspReceiver"
  log_group_class   = "STANDARD"
  retention_in_days = 7
  skip_destroy      = false
  tags = {
    Name           = "cspReceiverLogs"
    State          = "wp-analytics"
    Struct8Creator = "Contato Struct"
  }
}


