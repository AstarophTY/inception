#!/bin/bash
set -e

if [ -z "${FTP_USER}" ]; then
	echo "[ftp] FTP_USER is required"
	exit 1
fi

if [ ! -f /run/secrets/ftp_password ]; then
	echo "[ftp] Missing /run/secrets/ftp_password"
	exit 1
fi

FTP_PASSWORD="$(cat /run/secrets/ftp_password)"

mkdir -p /var/www/html

if ! getent group www-data >/dev/null 2>&1; then
	groupadd -g 33 www-data
fi

if ! id "${FTP_USER}" >/dev/null 2>&1; then
	useradd -o -u 33 -g www-data -d /var/www/html -s /usr/sbin/nologin "${FTP_USER}"
fi

echo "${FTP_USER}:${FTP_PASSWORD}" | chpasswd

chown -R 33:33 /var/www/html

if [ -z "${FTP_PASV_ADDRESS}" ]; then
	echo "[ftp] FTP_PASV_ADDRESS is required"
	exit 1
fi

envsubst < /etc/vsftpd.conf.template > /etc/vsftpd.conf

mkdir -p /var/run/vsftpd/empty

echo "[ftp] Starting vsftpd..."
exec /usr/sbin/vsftpd /etc/vsftpd.conf
