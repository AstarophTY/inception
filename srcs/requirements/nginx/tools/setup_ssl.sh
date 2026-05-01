#!/bin/bash

set -e

OUTPUT_DIR="/etc/nginx/ssl"
mkdir -p "$OUTPUT_DIR"

KEY_FILE="$OUTPUT_DIR/server.key"
CERT_FILE="$OUTPUT_DIR/server.crt"

COUNTRY="FR"
STATE="Auvergne-Rhône-Alpes"
CITY="Lyon"
ORG="MyCompany"
ORG_UNIT="IT"
COMMON_NAME="localhost"
EMAIL="admin@example.com"

if [ -f "$KEY_FILE" ] && [ -f "$CERT_FILE" ]; then
  echo "Existing TLS files found in $OUTPUT_DIR — leaving in place."
  exit 0
fi

echo "Generating self-signed TLS certificate in $OUTPUT_DIR (for local/testing only)."
umask 077
openssl genrsa -out "$KEY_FILE" 2048

openssl req -new -x509 -sha256 -days 365 \
  -key "$KEY_FILE" \
  -out "$CERT_FILE" \
  -subj "/C=$COUNTRY/ST=$STATE/L=$CITY/O=$ORG/OU=$ORG_UNIT/CN=$COMMON_NAME/emailAddress=$EMAIL"

echo "Generated certificate: $CERT_FILE"

