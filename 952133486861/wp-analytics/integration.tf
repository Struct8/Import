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
