#!/bin/bash

set -eu

readonly SECRET_NAME=$1
readonly DOMAINS=$2
readonly DOMAIN_MAIN=$(echo $DOMAINS | sed 's/,.*//')
readonly SECRET_NAMESPACE=${SECRET_NAMESPACE:-default}

echo "Generating certificate ${DOMAIN_MAIN}"
certbot \
  --non-interactive \
  --agree-tos \
  --standalone \
  --standalone-supported-challenges http-01 \
  --email "${LETS_ENCRYPT_EMAIL}" \
  --domains "${DOMAINS}" \
  certonly

echo "Generating kubernetes secret ${SECRET_NAME} (namespace ${SECRET_NAMESPACE})"

kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: "${SECRET_NAME}"
  namespace: "${SECRET_NAMESPACE}"
type: Opaque
data:
  tls.crt: "$(cat /etc/letsencrypt/live/${DOMAIN_MAIN}/fullchain.pem | base64 | tr -d '\n')"
  tls.key: "$(cat /etc/letsencrypt/live/${DOMAIN_MAIN}/privkey.pem | base64 | tr -d '\n')"
EOF
