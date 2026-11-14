resource "aws_acm_certificate" "cert-aws-gcp" {
  domain_name       = "aws.gcp.cloudman.pro"
  key_algorithm     = "RSA_2048"
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
  options {
    certificate_transparency_logging_preference = "ENABLED"
  }
  tags = {
    Name           = "cert-aws-gcp"
    State          = "stateAwsDnsTarget"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_acm_certificate_validation" "Validation_cert-aws-gcp" {
  certificate_arn         = aws_acm_certificate.cert-aws-gcp.arn
  validation_record_fqdns = [for record in google_dns_record_set.acme_cert_aws_gcp_aws_gcp_cloudman_pro_google_gcp_cloudman_pro : record.name]
}
