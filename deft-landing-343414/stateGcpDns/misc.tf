resource "aws_route53_record" "ns_google_dns_managed_zone_gcp_cloudman_pro_gcp_cloudman_pro_aws_Zone" {
  name    = "gcp.cloudman.pro"
  zone_id = data.aws_route53_zone.Zone.zone_id
  records = [for ns in google_dns_managed_zone.gcp-cloudman-pro.name_servers : trimsuffix(ns, ".")]
  ttl     = 3600
  type    = "NS"
}
