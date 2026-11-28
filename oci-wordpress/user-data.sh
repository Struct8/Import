#!/bin/bash
# WordPress on Ubuntu 24.04 (OCI Ampere A1), served through a Cloudflare Tunnel.
#
# The connector of the tunnel (cloudflared) is installed by the part of the cloud-init
# that runs before this script, when the instance is connected to the tunnel in the
# diagram. This script only installs WordPress and waits for the connector.
#
# Apache listens on 127.0.0.1:80 only: visitors reach it through the tunnel, never
# through a public port. The tunnel ingress points at http://localhost:80.
#
# Nothing secret is in this file. The values come from the instance metadata (the
# "metadata" field of the instance in the diagram):
#   wp_db_admin_user      administrator of the MySQL DB system   (required)
#   wp_db_admin_password  password of that administrator          (required)
#   wp_db_host            private IP of the DB system             (default 10.0.1.10)
#   wp_site_url           public address of the site              (default https://orthowp.struct8.com)
#
# Debug Access (Run Command) runs as the ocarun user. This script lets ocarun run
# commands as www-data, the owner of the site, so wp-cli can manage WordPress through
# it; ocarun gets no root.
#
# Log: /var/log/wordpress-setup.log
set -euo pipefail
exec >/var/log/wordpress-setup.log 2>&1

metadata() {
  # Instance metadata service v2 of OCI. Prints nothing when the key does not exist.
  curl -fsS --retry 5 -H "Authorization: Bearer Oracle" \
    "http://169.254.169.254/opc/v2/instance/metadata/$1" 2>/dev/null || true
}

DB_ADMIN_USER="$(metadata wp_db_admin_user)"
DB_ADMIN_PASSWORD="$(metadata wp_db_admin_password)"
DB_HOST="$(metadata wp_db_host)"
SITE_URL="$(metadata wp_site_url)"
DB_HOST="${DB_HOST:-10.0.1.10}"
SITE_URL="${SITE_URL:-https://orthowp.struct8.com}"

if [ -z "$DB_ADMIN_USER" ] || [ -z "$DB_ADMIN_PASSWORD" ]; then
  echo "Missing wp_db_admin_user or wp_db_admin_password in the instance metadata." >&2
  exit 1
fi

echo "== Packages"
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y apache2 php libapache2-mod-php php-mysql php-curl php-gd \
  php-mbstring php-xml php-zip php-intl mysql-client

echo "== WP-CLI"
curl -fsSL --retry 5 -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod 0755 /usr/local/bin/wp

echo "== Debug Access: ocarun runs commands as www-data, never as root"
SUDOERS_TMP="$(mktemp)"
echo 'ocarun ALL=(www-data) NOPASSWD: ALL' >"$SUDOERS_TMP"
visudo -cf "$SUDOERS_TMP"
install -m 0440 "$SUDOERS_TMP" /etc/sudoers.d/101-oracle-cloud-agent-run-command
rm -f "$SUDOERS_TMP"

echo "== Apache on 127.0.0.1:80 only"
sed -i 's/^Listen 80$/Listen 127.0.0.1:80/' /etc/apache2/ports.conf
sed -i 's/^\(\s*\)Listen 443$/\1# Listen 443/' /etc/apache2/ports.conf
# The visitor's address arrives in CF-Connecting-IP; the logs and WordPress use it.
a2enmod remoteip rewrite
cat >/etc/apache2/conf-available/cloudflare-tunnel.conf <<'EOF'
RemoteIPHeader CF-Connecting-IP
RemoteIPInternalProxy 127.0.0.1 ::1
EOF
a2enconf cloudflare-tunnel

echo "== Waiting for the MySQL DB system (up to 60 minutes)"
for attempt in $(seq 1 120); do
  if mysqladmin ping -h "$DB_HOST" -u "$DB_ADMIN_USER" -p"$DB_ADMIN_PASSWORD" --silent; then break; fi
  sleep 30
done

echo "== Database and user of WordPress"
# The password of this user is made here and stays only in wp-config.php.
WP_DB_PASSWORD="Wp-$(openssl rand -hex 12)-9z"
mysql -h "$DB_HOST" -u "$DB_ADMIN_USER" -p"$DB_ADMIN_PASSWORD" <<SQL
CREATE DATABASE IF NOT EXISTS wordpress CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'wordpress'@'%' IDENTIFIED BY '$WP_DB_PASSWORD';
ALTER USER 'wordpress'@'%' IDENTIFIED BY '$WP_DB_PASSWORD';
GRANT ALL PRIVILEGES ON wordpress.* TO 'wordpress'@'%';
SQL

echo "== WordPress"
curl -fsSL --retry 5 -o /tmp/wordpress.tar.gz https://wordpress.org/latest.tar.gz
rm -f /var/www/html/index.html
tar -xzf /tmp/wordpress.tar.gz -C /var/www/html --strip-components=1
SALTS=$(curl -fsSL --retry 5 https://api.wordpress.org/secret-key/1.1/salt/)
cat >/var/www/html/wp-config.php <<EOF
<?php
define('DB_NAME', 'wordpress');
define('DB_USER', 'wordpress');
define('DB_PASSWORD', '$WP_DB_PASSWORD');
define('DB_HOST', '$DB_HOST');
define('DB_CHARSET', 'utf8mb4');
define('DB_COLLATE', '');
define('MYSQL_CLIENT_FLAGS', MYSQLI_CLIENT_SSL | MYSQLI_CLIENT_SSL_DONT_VERIFY_SERVER_CERT);

// The tunnel delivers plain HTTP on localhost; the visitor used HTTPS.
if (isset(\$_SERVER['HTTP_X_FORWARDED_PROTO']) && \$_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') {
  \$_SERVER['HTTPS'] = 'on';
}
define('WP_HOME', '$SITE_URL');
define('WP_SITEURL', '$SITE_URL');
define('FORCE_SSL_ADMIN', true);

$SALTS
\$table_prefix = 'wp_';
define('WP_DEBUG', false);
if (!defined('ABSPATH')) {
  define('ABSPATH', __DIR__ . '/');
}
require_once ABSPATH . 'wp-settings.php';
EOF
chown -R www-data:www-data /var/www/html

# Permalinks need .htaccess.
sed -i '/<Directory \/var\/www\/>/,/<\/Directory>/ s/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf
systemctl restart apache2

echo "== Cloudflare Tunnel connector"
for attempt in $(seq 1 30); do
  if systemctl is-active --quiet cloudflared; then
    echo "cloudflared is running."
    break
  fi
  sleep 10
done
systemctl is-active --quiet cloudflared || echo "cloudflared is not running: see journalctl -u cloudflared." >&2

echo "== Done: $SITE_URL"
