#!/bin/bash
set -e

DBDIR=/var/lib/mysql

if [ -z "$(ls -A $DBDIR 2>/dev/null)" ]; then
  echo "[entrypoint] Initialising MariaDB data directory"
  mysqld --initialize-insecure --datadir=$DBDIR --user=mysql
  chown -R mysql:mysql $DBDIR

  # Start temporary server
  mysqld_safe --datadir=$DBDIR &
  pid="$!"
  sleep 2

  # Read secrets or env fallback
  if [ -f /run/secrets/db_root_password ]; then
    ROOT_PW=$(cat /run/secrets/db_root_password)
  else
    ROOT_PW=${MYSQL_ROOT_PASSWORD:-root}
  fi
  if [ -f /run/secrets/db_password ]; then
    USER_PW=$(cat /run/secrets/db_password)
  else
    USER_PW=${MYSQL_PASSWORD:-password}
  fi

  # Wait for server to be ready
  for i in {1..30}; do
    mysqladmin ping >/dev/null 2>&1 && break || sleep 1
  done

  mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${ROOT_PW}';" || true
  mysql -e "CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};" || true
  mysql -e "CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${USER_PW}';" || true
  mysql -e "GRANT ALL ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%'; FLUSH PRIVILEGES;" || true

  echo "[entrypoint] Stopping temporary server"
  mysqladmin shutdown || true
  wait $pid || true
fi

exec mysqld
