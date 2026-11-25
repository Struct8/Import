resource "cloudflare_dns_record" "cname_cloudflare_zero_trust_tunnel_cloudflared_orthowp_orthowp_struct8_com" {
  name    = "orthowp.struct8.com"
  zone_id = data.cloudflare_zone.struct8.id
  content = "${cloudflare_zero_trust_tunnel_cloudflared.orthowp.id}.cfargotunnel.com"
  proxied = true
  ttl     = 1
  type    = "CNAME"
}
