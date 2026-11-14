resource "google_dns_record_set" "acme_cert_aws_gcp_aws_gcp_cloudman_pro_google_gcp_cloudman_pro" {
  for_each = {
    for dvo in aws_acm_certificate.cert-aws-gcp.domain_validation_options : dvo.domain_name => dvo
    if dvo.domain_name == "aws.gcp.cloudman.pro"
  }
  name         = each.value.resource_record_name
  managed_zone = data.google_dns_managed_zone.gcp-cloudman-pro.name
  project      = "deft-landing-343414"
  rrdatas      = [each.value.resource_record_value]
  ttl          = 300
  type         = each.value.resource_record_type
}
