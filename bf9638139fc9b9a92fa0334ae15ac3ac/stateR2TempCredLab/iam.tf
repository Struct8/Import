data "cloudflare_account_api_token_permission_groups_list" "r2-temp-cred-lab-parent_groups" {
  account_id = "bf9638139fc9b9a92fa0334ae15ac3ac"
}

resource "cloudflare_account_token" "r2-temp-cred-lab-parent" {
  # ajuste manual · policies[*].resources — The form has no field for the scope of a token policy (policies.resources is hidden), so the generator scopes every policy to the whole account. This lab token must reach only the bucket struct8-r2-temp-cred-lab.
  account_id = "bf9638139fc9b9a92fa0334ae15ac3ac"
  name       = "r2-temp-cred-lab-parent"
  expires_on = "2026-11-23T00:00:00Z"
  policies = [
    {
      effect = "allow"
      permission_groups = [
        {
          id = [for g in data.cloudflare_account_api_token_permission_groups_list.r2-temp-cred-lab-parent_groups.result : g.id if g.name == "Workers R2 Storage Bucket Item Write"][0]
        }
      ]
      resources = jsonencode({
          "com.cloudflare.edge.r2.bucket.bf9638139fc9b9a92fa0334ae15ac3ac_default_struct8-r2-temp-cred-lab" = "*"
        })
    }
  ]
}
