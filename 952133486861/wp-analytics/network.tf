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
