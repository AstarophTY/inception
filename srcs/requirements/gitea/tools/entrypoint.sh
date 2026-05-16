#!/bin/bash
set -e

APP_INI="/data/gitea/conf/app.ini"

ROOT_URL="${GITEA__server__ROOT_URL:-}"
SERVE_FROM_SUB_PATH="${GITEA__server__SERVE_FROM_SUB_PATH:-}"
DB_TYPE="${GITEA__database__DB_TYPE:-}"
DB_PATH="${GITEA__database__PATH:-}"
DB_HOST="${GITEA__database__HOST:-}"
DB_NAME="${GITEA__database__NAME:-}"
DB_USER="${GITEA__database__USER:-}"
DB_PASSWD="${GITEA__database__PASSWD:-}"

if [ -z "${ROOT_URL}" ] && [ -n "${DOMAIN_NAME}" ]; then
	ROOT_URL="https://${DOMAIN_NAME}/gitea/"
fi

set_ini_value() {
	local section="$1"
	local key="$2"
	local value="$3"

	if [ ! -f "${APP_INI}" ]; then
		printf "[%s]\n%s = %s\n" "${section}" "${key}" "${value}" >"${APP_INI}"
		return
	fi

	awk -v section="${section}" -v key="${key}" -v value="${value}" '
		BEGIN { in_section=0; done=0 }
		$0 ~ "^\\[" section "\\]" { in_section=1; print; next }
		in_section && $0 ~ "^\\[" { if (!done) { print key " = " value; done=1 } in_section=0 }
		in_section && $0 ~ "^[[:space:]]*" key "[[:space:]]*=" { print key " = " value; done=1; next }
		{ print }
		END {
			if (!done) {
				if (!in_section) {
					print "[" section "]"
				}
				print key " = " value
			}
		}
	' "${APP_INI}" >"${APP_INI}.tmp" && mv "${APP_INI}.tmp" "${APP_INI}"
}

if [ -n "${ROOT_URL}" ]; then
	set_ini_value "server" "ROOT_URL" "${ROOT_URL}"
fi

if [ -n "${SERVE_FROM_SUB_PATH}" ]; then
	set_ini_value "server" "SERVE_FROM_SUB_PATH" "${SERVE_FROM_SUB_PATH}"
fi

if [ -n "${DB_TYPE}" ]; then
	set_ini_value "database" "DB_TYPE" "${DB_TYPE}"
fi

if [ -f /run/secrets/gitea_db_password ]; then
	DB_PASSWD="$(cat /run/secrets/gitea_db_password)"
fi

if [ -z "${DB_HOST}" ] && [ "${DB_TYPE}" = "mysql" ]; then
	DB_HOST="mariadb:3306"
fi

if [ -n "${DB_HOST}" ]; then
	set_ini_value "database" "HOST" "${DB_HOST}"
fi

if [ -n "${DB_NAME}" ]; then
	set_ini_value "database" "NAME" "${DB_NAME}"
fi

if [ -n "${DB_USER}" ]; then
	set_ini_value "database" "USER" "${DB_USER}"
fi

if [ -n "${DB_PASSWD}" ]; then
	set_ini_value "database" "PASSWD" "${DB_PASSWD}"
fi

set_ini_value "security" "INSTALL_LOCK" "true"

if [ -z "${DB_PATH}" ] && [ "${DB_TYPE}" = "sqlite3" ]; then
	DB_PATH="/data/gitea/gitea.db"
fi

if [ -n "${DB_PATH}" ]; then
	set_ini_value "database" "PATH" "${DB_PATH}"
	mkdir -p "$(dirname "${DB_PATH}")"
	if [ ! -f "${DB_PATH}" ]; then
		touch "${DB_PATH}"
	fi
fi

exec gitea web --config "${APP_INI}"
