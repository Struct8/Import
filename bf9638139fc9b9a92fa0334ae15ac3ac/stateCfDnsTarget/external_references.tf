data "cloudflare_zone" "struct8" {
  filter = {
    name = "struct8.com"
  }
}
