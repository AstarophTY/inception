#!/bin/bash
set -e

DBDIR=/var/lib/mysql

chown -R mysql:mysql "$DBDIR" /var/run/mysqld

ROOT_PW="$(cat /run/secrets/db_root_password)"
USER_PW="$(cat /run/secrets/db_password)"
GITEA_DB_NAME="${GITEA_DB_NAME}"
GITEA_DB_USER="${GITEA_DB_USER}"
GITEA_DB_PW=""

if [ -f /run/secrets/gitea_db_password ]; then
	GITEA_DB_PW="$(cat /run/secrets/gitea_db_password)"
fi

if [ ! -d "$DBDIR/mysql" ]; then
	echo "[mariadb] Initialising data directory"
	mysql_install_db --datadir="$DBDIR" --user=mysql --skip-test-db >/dev/null
else
	echo "[mariadb] Existing data directory found, skipping mysql_install_db."
fi

echo "[mariadb] Ensuring database and users exist (idempotent bootstrap)"
BOOTSTRAP_SQL="/tmp/bootstrap.sql"
cat > "${BOOTSTRAP_SQL}" <<-EOF
	USE mysql;
	FLUSH PRIVILEGES;
	ALTER USER 'root'@'localhost' IDENTIFIED BY '${ROOT_PW}';
	DELETE FROM mysql.user WHERE User='';
	DROP DATABASE IF EXISTS test;
	CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
	CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${USER_PW}';
	ALTER USER '${MYSQL_USER}'@'%' IDENTIFIED BY '${USER_PW}';
	GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
EOF

if [ -n "${GITEA_DB_NAME}" ] && [ -n "${GITEA_DB_USER}" ] && [ -n "${GITEA_DB_PW}" ]; then
	cat >> "${BOOTSTRAP_SQL}" <<-EOF
	CREATE DATABASE IF NOT EXISTS \`${GITEA_DB_NAME}\`;
	CREATE USER IF NOT EXISTS '${GITEA_DB_USER}'@'%' IDENTIFIED BY '${GITEA_DB_PW}';
	ALTER USER '${GITEA_DB_USER}'@'%' IDENTIFIED BY '${GITEA_DB_PW}';
	GRANT ALL PRIVILEGES ON \`${GITEA_DB_NAME}\`.* TO '${GITEA_DB_USER}'@'%';
EOF
fi

cat >> "${BOOTSTRAP_SQL}" <<-EOF
	FLUSH PRIVILEGES;
EOF

mysqld --user=mysql --bootstrap < "${BOOTSTRAP_SQL}"

echo "[mariadb] Starting mysqld (foreground, PID 1, user=mysql)"
exec mysqld --user=mysql --bind-address=0.0.0.0
