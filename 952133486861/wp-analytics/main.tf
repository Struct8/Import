terraform {
  required_providers {
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

resource "aws_iam_role_policy_attachment" "cloudfront_realtime_log_config_cdnLogConfig_st_wp-analytics_attach" {
  policy_arn = aws_iam_policy.cloudfront_realtime_log_config_cdnLogConfig_st_wp-analytics.arn
  role       = aws_iam_role.cdnLogConfig_role.name
}

resource "aws_iam_role_policy_attachment" "kinesis_firehose_delivery_stream_cdnLogFirehose_st_wp-analytics_attach" {
  policy_arn = aws_iam_policy.kinesis_firehose_delivery_stream_cdnLogFirehose_st_wp-analytics.arn
  role       = aws_iam_role.cdnLogFirehose_role.name
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
      name    = "country"
      comment = "Two-letter country of the visitor."
      type    = "string"
    }
    columns {
      name    = "method"
      comment = "HTTP method."
      type    = "string"
    }
    columns {
      name    = "uri_stem"
      comment = "Path of the request, without the query string."
      type    = "string"
    }
    columns {
      name    = "uri_query"
      comment = "Query string."
      type    = "string"
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
  count_if(uri_stem LIKE '/product/%') AS product_views,
  count_if(uri_stem = '/cart/') AS cart_views,
  count_if(uri_stem LIKE '/checkout/%' AND method = 'GET') AS checkout_views,
  count_if(uri_stem LIKE '/wp-json/wc/store/v1/checkout%' AND method = 'POST') AS orders_placed
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
SELECT uri_stem, count(*) AS requests
FROM cdn_log
WHERE concat(year, month, day) >= date_format(current_date - interval '7' day, '%Y%m%d')
  AND method = 'GET' AND status = 200 AND behavior_path = 'Default (*)'
GROUP BY uri_stem
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
  AND behavior_path = 'Default (*)'
GROUP BY 1, 2
ORDER BY 1 DESC, 3 DESC;
  EOF
  workgroup = aws_athena_workgroup.cdnAnalytics.name
}

resource "aws_athena_workgroup" "cdnAnalytics" {
  name = "cdnAnalytics"
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


