resource "aws_cloudwatch_log_group" "wpReadCanaryLogs" {
  name              = "/aws/lambda/${element(split(":", aws_synthetics_canary.wpReadCanary.engine_arn), 6)}"
  log_group_class   = "STANDARD"
  retention_in_days = 30
  skip_destroy      = false
  tags = {
    Name           = "wpReadCanaryLogs"
    State          = "wordpress-loadtest"
    Struct8Creator = "Contato Struct"
  }
}

data "archive_file" "canary_struct8-templates_wpReadCanary" {
  output_path = "${path.module}/canary_struct8-templates_wpReadCanary_${substr(sha1(join(",", [for f in sort(fileset("${path.module}/.external_modules/struct8-templates/templates/wordpress-professional/v1/canary", "**")) : "${f}:${filesha1("${path.module}/.external_modules/struct8-templates/templates/wordpress-professional/v1/canary/${f}")}"])), 0, 16)}.zip"
  source_dir  = "${path.module}/.external_modules/struct8-templates/templates/wordpress-professional/v1/canary"
  type        = "zip"
}

resource "aws_synthetics_canary" "wpReadCanary" {
  name                 = "wpreadcanary"
  artifact_s3_location = "s3://${aws_s3_bucket.canaryArtifacts.bucket}/canary/wpreadcanary"
  delete_lambda        = true
  execution_role_arn   = aws_iam_role.wpReadCanary_role.arn
  handler              = "index.handler"
  runtime_version      = "syn-nodejs-playwright-9.0"
  start_canary         = true
  zip_file             = data.archive_file.canary_struct8-templates_wpReadCanary.output_path
  run_config {
    active_tracing     = false
    ephemeral_storage  = 1024
    memory_in_mb       = 960
    timeout_in_seconds = 120
    environment_variables = {
      NAME                 = "wpReadCanary"
      REGION               = data.aws_region.current.region
      ACCOUNT              = data.aws_caller_identity.current.account_id
      AWS_S3_BUCKET_NAME_0 = "canaryartifacts-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.region}-an"
      TARGET_URL           = "https://wp.cloudman.pro/"
    }
  }
  schedule {
    expression = "rate(5 minutes)"
    retry_config {
      max_retries = 0
    }
  }
  tags = {
    Name           = "wpReadCanary"
    State          = "wordpress-loadtest"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_iam_role_policy_attachment.synthetics_canary_wpReadCanary_st_wordpress-loadtest_attach]
}
