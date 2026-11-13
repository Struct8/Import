resource "cloudflare_dns_record" "saas-fallback" {
  name            = "saas-fallback"
  zone_id         = data.cloudflare_zone.struct8.id
  content         = "100::"
  private_routing = false
  proxied         = true
  ttl             = 1
  type            = "AAAA"
}

resource "cloudflare_custom_hostname" "worker-gcp" {
  zone_id  = data.cloudflare_zone.struct8.id
  hostname = "worker.gcp.cloudman.pro"
  ssl = {
    method = "http"
    type   = "dv"
  }
}

resource "cloudflare_custom_hostname_fallback_origin" "fallback-origin" {
  zone_id = data.cloudflare_zone.struct8.id
  origin  = "saas-fallback.struct8.com"
}
