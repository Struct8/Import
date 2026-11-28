data "cloudflare_zero_trust_tunnel_cloudflared_token" "wordpress_tunnel" {
  account_id = "bf9638139fc9b9a92fa0334ae15ac3ac"
  tunnel_id  = one([for it in data.cloudflare_zero_trust_tunnel_cloudflareds.orthowp.result : it.id if it.name == "orthowp"])
}

resource "oci_core_instance" "wordpress" {
  compartment_id      = oci_identity_compartment.wordpress.id
  display_name        = "wordpress"
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  shape               = "VM.Standard1.1"
  state               = "RUNNING"
  create_vnic_details {
    subnet_id        = oci_core_subnet.web.id
    assign_public_ip = true
    nsg_ids          = [oci_core_network_security_group.wordpress_nsg.id]
  }
  freeform_tags = {
    Name           = "wordpress"
    State          = "oci-wordpress"
    Struct8Creator = "Contato Struct"
  }
  lifecycle {
    ignore_changes       = [source_details[0].source_id]
    replace_triggered_by = [terraform_data.wordpress_image]
  }
  metadata = {
    wp_db_admin_user     = "wpadmin"
    wp_db_admin_password = "Troque-Esta-Senha-1"
    wp_db_host           = "10.0.1.10"
    wp_site_url          = "https://orthowp.struct8.com"
    user_data            = base64encode(join("\n", ["Content-Type: multipart/mixed; boundary=\"STRUCT8-USER-DATA\"", "MIME-Version: 1.0", "", "--STRUCT8-USER-DATA", "Content-Type: text/x-shellscript; charset=\"utf-8\"", "MIME-Version: 1.0", "", "#!/bin/bash", "set -eu", "case \"$(uname -m)\" in aarch64|arm64) arch=arm64 ;; *) arch=amd64 ;; esac", "curl -fsSL --retry 5 -o /usr/local/bin/cloudflared \"https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-$arch\"", "chmod 755 /usr/local/bin/cloudflared", "/usr/local/bin/cloudflared service install ${data.cloudflare_zero_trust_tunnel_cloudflared_token.wordpress_tunnel.token}", "--STRUCT8-USER-DATA", "Content-Type: text/plain; charset=\"utf-8\"", "MIME-Version: 1.0", "Content-Transfer-Encoding: base64", "", filebase64("${path.module}/.external_modules/Import/oci-wordpress/user-data.sh"), "--STRUCT8-USER-DATA--", ""]))
  }
  source_details {
    source_id               = data.oci_core_images.wordpress_image.images[0].id
    boot_volume_vpus_per_gb = "10"
    source_type             = "image"
  }
}
