resource "cloudflare_r2_bucket" "r2-lab-phase4" {
  account_id = "bf9638139fc9b9a92fa0334ae15ac3ac"
  name       = "r2-lab-phase4"
  location   = "enam"
  lifecycle {
    ignore_changes = [location]
  }
}

resource "cloudflare_r2_bucket" "r2-lab-phase4-other" {
  account_id = "bf9638139fc9b9a92fa0334ae15ac3ac"
  name       = "r2-lab-phase4-other"
  location   = "enam"
  lifecycle {
    ignore_changes = [location]
  }
}
