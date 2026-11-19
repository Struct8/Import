data "aws_kms_key" "kmsWordpress" {
  key_id = "alias/kmsWordpress-xnA-aVKz"
}

data "aws_secretsmanager_secret" "wpSecrets" {
  name = "wpSecrets"
}

data "aws_ssm_parameter" "wpAdminPassword" {
  name            = "wpAdminPassword"
  with_decryption = false
}

data "aws_cloudfront_response_headers_policy" "cspReportOnly" {
  name = "cspReportOnly"
}

data "aws_cloudfront_realtime_log_config" "cdnLogConfig" {
  name = "cdnLogConfig"
}

data "aws_lambda_function_url" "analyticsUrl" {
  function_name = "analyticsPage"
}
