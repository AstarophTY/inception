#!/bin/bash
set -e

if [ -z "$(ls -A /var/www/html 2>/dev/null)" ]; then
  echo "[entrypoint] Downloading WordPress core..."
  wget -q https://wordpress.org/latest.tar.gz -O /tmp/wordpress.tar.gz
  tar -xzf /tmp/wordpress.tar.gz -C /tmp
  cp -r /tmp/wordpress/* /var/www/html/
  chown -R www:www /var/www/html
fi

echo "[entrypoint] Starting php-fpm in foreground"
exec php-fpm8.2 -F
