#!/bin/bash

set -e

OUTPUT_DIR="/etc/nginx/ssl"
mkdir -p "$OUTPUT_DIR"

CA_KEY="$OUTPUT_DIR/ca.key"
CA_CERT="$OUTPUT_DIR/ca.crt"
KEY_FILE="$OUTPUT_DIR/server.key"
CERT_FILE="$OUTPUT_DIR/server.crt"

COUNTRY="FR"
STATE="Auvergne-Rhône-Alpes"
CITY="Lyon"
ORG="MyCompany"
ORG_UNIT="IT"
COMMON_NAME="${DOMAIN_NAME:-localhost}"
EMAIL="webmaster@${DOMAIN_NAME:-localhost}"

echo "Generating TLS certificate in $OUTPUT_DIR (for local/testing only)."
rm -f "$KEY_FILE" "$CERT_FILE"

if [ ! -f "$CA_KEY" ] || [ ! -f "$CA_CERT" ]; then
  echo "Creating local CA in $OUTPUT_DIR"
  umask 077
  openssl genrsa -out "$CA_KEY" 4096
  openssl req -x509 -new -nodes -sha256 -days 3650 \
    -key "$CA_KEY" \
    -out "$CA_CERT" \
    -subj "/C=$COUNTRY/ST=$STATE/L=$CITY/O=$ORG/OU=$ORG_UNIT/CN=${COMMON_NAME} Local CA/emailAddress=$EMAIL"
fi
umask 077
openssl genrsa -out "$KEY_FILE" 2048

CSR="$OUTPUT_DIR/server.csr"
EXT="$OUTPUT_DIR/server.ext"

cat > "$EXT" <<-EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = $COMMON_NAME
DNS.2 = localhost
IP.1 = 127.0.0.1
EOF

openssl req -new -sha256 \
  -key "$KEY_FILE" \
  -out "$CSR" \
  -subj "/C=$COUNTRY/ST=$STATE/L=$CITY/O=$ORG/OU=$ORG_UNIT/CN=$COMMON_NAME/emailAddress=$EMAIL"

openssl x509 -req -sha256 -days 365 \
  -in "$CSR" \
  -CA "$CA_CERT" -CAkey "$CA_KEY" -CAcreateserial \
  -out "$CERT_FILE" \
  -extfile "$EXT"

rm -f "$CSR" "$EXT" "$OUTPUT_DIR/ca.srl"

echo "Generated certificate: $CERT_FILE (signed by local CA: $CA_CERT)"

