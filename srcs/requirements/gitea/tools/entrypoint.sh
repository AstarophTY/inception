#!/bin/bash
set -e

APP_INI="/data/gitea/conf/app.ini"

ROOT_URL="${GITEA__server__ROOT_URL:-}"
SERVE_FROM_SUB_PATH="${GITEA__server__SERVE_FROM_SUB_PATH:-}"

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
		in_section && $0 ~ "^" key "[[:space:]]*=" { print key " = " value; done=1; next }
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

exec gitea web --config "${APP_INI}"
