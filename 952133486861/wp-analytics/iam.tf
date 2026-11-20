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
    sid       = "AllowCspTableScan"
    effect    = "Allow"
    actions   = ["dynamodb:Scan"]
    resources = [aws_dynamodb_table.cspTable.arn]
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
    sid       = "AllowSendTracesToXRay"
    effect    = "Allow"
    actions   = ["xray:PutTelemetryRecords", "xray:PutTraceSegments"]
    resources = ["*"]
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
  statement {
    sid       = "AllowSendTracesToXRay"
    effect    = "Allow"
    actions   = ["xray:PutTelemetryRecords", "xray:PutTraceSegments"]
    resources = ["*"]
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
