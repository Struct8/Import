data "cloudflare_account_api_token_permission_groups_list" "r2lab-r2-parent_groups" {
  account_id = "bf9638139fc9b9a92fa0334ae15ac3ac"
}

resource "cloudflare_account_token" "r2lab-r2-parent" {
  account_id = "bf9638139fc9b9a92fa0334ae15ac3ac"
  name       = "cross-cloud-r2lab-r2"
  policies = [
    {
      effect = "allow"
      permission_groups = [
        {
          id = [for g in data.cloudflare_account_api_token_permission_groups_list.r2lab-r2-parent_groups.result : g.id if g.name == "Workers R2 Storage Bucket Item Write"][0]
        }
      ]
      resources = jsonencode({ "com.cloudflare.edge.r2.bucket.bf9638139fc9b9a92fa0334ae15ac3ac_default_${cloudflare_r2_bucket.r2-lab-phase3.name}" = "*" })
    }
  ]
}
