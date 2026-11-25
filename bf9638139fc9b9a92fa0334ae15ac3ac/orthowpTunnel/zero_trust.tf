resource "cloudflare_zero_trust_tunnel_cloudflared" "orthowp" {
  account_id = "bf9638139fc9b9a92fa0334ae15ac3ac"
  name       = "orthowp"
  config_src = "cloudflare"
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "orthowp_config" {
  account_id = cloudflare_zero_trust_tunnel_cloudflared.orthowp.account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.orthowp.id
  config = {
    ingress = [
      {
        hostname = "orthowp.struct8.com"
        service  = "http://localhost:80"
      },
      {
        service = "http_status:404"
      }
    ]
  }
}
