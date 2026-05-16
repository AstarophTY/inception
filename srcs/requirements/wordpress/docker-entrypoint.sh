#!/bin/bash
set -e

cd /var/www/html

DB_PASSWORD="$(cat /run/secrets/db_password)"
WP_ADMIN_PASSWORD="$(grep '^WP_ADMIN_PASSWORD=' /run/secrets/wp_credentials | cut -d= -f2-)"
WP_USER_PASSWORD="$(grep '^WP_USER_PASSWORD=' /run/secrets/wp_credentials | cut -d= -f2-)"

WP="wp --allow-root --path=/var/www/html"

if [ ! -f wp-config.php ]; then
	echo "[wordpress] Downloading WordPress core..."
	$WP core download --version=latest

	echo "[wordpress] Creating wp-config.php..."
	$WP config create \
		--dbname="${MYSQL_DATABASE}" \
		--dbuser="${MYSQL_USER}" \
		--dbpass="${DB_PASSWORD}" \
		--dbhost="${WORDPRESS_DB_HOST}" \
		--skip-check

	$WP config set WP_REDIS_HOST "${WP_REDIS_HOST}"
	$WP config set WP_REDIS_PORT "${WP_REDIS_PORT}" --raw
	$WP config set WP_CACHE true --raw

	echo "[wordpress] Waiting for MariaDB..."
	until $WP db check >/dev/null 2>&1; do
		sleep 2
	done

	echo "[wordpress] Installing WordPress..."
	$WP core install \
		--url="${WP_URL}" \
		--title="${WP_TITLE}" \
		--admin_user="${WP_ADMIN_USER}" \
		--admin_password="${WP_ADMIN_PASSWORD}" \
		--admin_email="${WP_ADMIN_EMAIL}" \
		--skip-email

	echo "[wordpress] Creating second (non-admin) user..."
	$WP user create "${WP_USER}" "${WP_USER_EMAIL}" \
		--role=author \
		--user_pass="${WP_USER_PASSWORD}"

	echo "[wordpress] Enabling Redis object cache..."
	$WP plugin install redis-cache --activate
	$WP redis enable || true
else
	echo "[wordpress] Existing installation found, skipping setup."
fi

chown -R www-data:www-data /var/www/html
mkdir -p /run/php

echo "[wordpress] Starting php-fpm (foreground, PID 1)"
exec php-fpm8.2 -F
