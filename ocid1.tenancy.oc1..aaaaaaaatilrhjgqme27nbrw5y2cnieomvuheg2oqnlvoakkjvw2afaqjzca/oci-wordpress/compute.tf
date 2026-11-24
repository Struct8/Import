resource "oci_core_instance" "wordpress" {
  compartment_id      = oci_identity_compartment.wordpress.id
  display_name        = "wordpress"
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  shape               = "VM.Standard.A1.Flex"
  state               = "RUNNING"
  create_vnic_details {
    subnet_id        = oci_core_subnet.web.id
    assign_public_ip = true
    nsg_ids          = [oci_core_network_security_group.web-nsg.id]
  }
  lifecycle {
    ignore_changes       = [source_details[0].source_id]
    replace_triggered_by = [terraform_data.wordpress_image]
  }
  metadata = {
    user_data = base64encode("#!/bin/bash\n# WordPress on Ubuntu 24.04 (OCI Ampere A1), database on the MySQL HeatWave DB system\n# \"wordpress-db\" of the same VCN. Log: /var/log/wordpress-setup.log\nset -euxo pipefail\nexec >/var/log/wordpress-setup.log 2>&1\n\n# The DB system: its fixed private IP and its administrator. Use here the same\n# user and password as in the form of the DB system \"wordpress-db\".\nDB_HOST=10.0.1.10\nDB_ADMIN_USER=wpadmin\nDB_ADMIN_PASSWORD='Troque-Esta-Senha-1'\n\nexport DEBIAN_FRONTEND=noninteractive\napt-get update\napt-get install -y apache2 php libapache2-mod-php php-mysql php-curl php-gd \\\n  php-mbstring php-xml php-zip php-intl mysql-client\n\n# The Ubuntu images of OCI reject every new connection except SSH (iptables).\n# Allow HTTP and HTTPS before the REJECT rule, and keep it after a reboot.\nREJECT_LINE=$(iptables -L INPUT --line-numbers -n | awk '$2 == \"REJECT\" { print $1; exit }')\nif [ -z \"$REJECT_LINE\" ]; then REJECT_LINE=1; fi\niptables -I INPUT \"$REJECT_LINE\" -p tcp -m multiport --dports 80,443 -m state --state NEW -j ACCEPT\nnetfilter-persistent save || true\n\n# The DB system takes longer to create than the instance: wait up to 60 minutes.\nfor attempt in $(seq 1 120); do\n  if mysqladmin ping -h \"$DB_HOST\" -u \"$DB_ADMIN_USER\" -p\"$DB_ADMIN_PASSWORD\" --silent; then break; fi\n  sleep 30\ndone\n\n# A database and a user of WordPress. The password of that user is made here\n# and stays only in wp-config.php on this instance.\nWP_DB_PASSWORD=\"Wp-$(openssl rand -hex 12)-9z\"\nmysql -h \"$DB_HOST\" -u \"$DB_ADMIN_USER\" -p\"$DB_ADMIN_PASSWORD\" <<SQL\nCREATE DATABASE IF NOT EXISTS wordpress CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;\nCREATE USER IF NOT EXISTS 'wordpress'@'%' IDENTIFIED BY '$WP_DB_PASSWORD';\nGRANT ALL PRIVILEGES ON wordpress.* TO 'wordpress'@'%';\nSQL\n\n# WordPress itself.\ncurl -fsSL -o /tmp/wordpress.tar.gz https://wordpress.org/latest.tar.gz\nrm -f /var/www/html/index.html\ntar -xzf /tmp/wordpress.tar.gz -C /var/www/html --strip-components=1\nSALTS=$(curl -fsSL https://api.wordpress.org/secret-key/1.1/salt/)\ncat >/var/www/html/wp-config.php <<EOF\n<?php\ndefine('DB_NAME', 'wordpress');\ndefine('DB_USER', 'wordpress');\ndefine('DB_PASSWORD', '$WP_DB_PASSWORD');\ndefine('DB_HOST', '$DB_HOST');\ndefine('DB_CHARSET', 'utf8mb4');\ndefine('DB_COLLATE', '');\ndefine('MYSQL_CLIENT_FLAGS', MYSQLI_CLIENT_SSL | MYSQLI_CLIENT_SSL_DONT_VERIFY_SERVER_CERT);\n$SALTS\n\\$table_prefix = 'wp_';\ndefine('WP_DEBUG', false);\nif (!defined('ABSPATH')) {\n  define('ABSPATH', __DIR__ . '/');\n}\nrequire_once ABSPATH . 'wp-settings.php';\nEOF\nchown -R www-data:www-data /var/www/html\n\n# Permalinks need .htaccess.\nsed -i '/<Directory \\/var\\/www\\/>/,/<\\/Directory>/ s/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf\na2enmod rewrite\nsystemctl restart apache2\n")
  }
  shape_config {
    memory_in_gbs = 12
    ocpus         = 2
  }
  source_details {
    source_id               = data.oci_core_images.wordpress_image.images[0].id
    boot_volume_vpus_per_gb = "10"
    source_type             = "image"
  }
}
