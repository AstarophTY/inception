#!/bin/bash
set -e

if [ -z "$(ls -A /var/www/html 2>/dev/null)" ] || [ ! -f /var/www/html/index.php ]; then
  echo "[entrypoint] Downloading WordPress core..."
  wget -q https://wordpress.org/latest.tar.gz -O /tmp/wordpress.tar.gz
  tar -xzf /tmp/wordpress.tar.gz -C /tmp
  cp -r /tmp/wordpress/* /var/www/html/
fi

echo "[entrypoint] Setting permissions for WordPress files..."
chown -R www-data:www-data /var/www/html
find /var/www/html -type d -exec chmod 755 {} \;
find /var/www/html -type f -exec chmod 644 {} \;

echo "[entrypoint] Starting php-fpm in foreground"
exec php-fpm8.2 -F
