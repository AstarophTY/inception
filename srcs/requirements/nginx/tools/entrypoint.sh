#!/bin/bash
set -e

# /usr/local/bin/setup_ssl.sh

envsubst '${DOMAIN_NAME}' \
	< /etc/nginx/conf.d/default.conf.template \
	> /etc/nginx/conf.d/default.conf

echo "[nginx] Starting nginx (foreground, PID 1) for ${DOMAIN_NAME}"
exec nginx -g 'daemon off;'
