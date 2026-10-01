#!/usr/bin/env bash
#
# Print fresh secrets for docker/.env. Run once, before the first start:
#   cd docker && cp .env.example .env && ../scripts/generate-secrets.sh >> .env

set -euo pipefail

rand() { openssl rand -base64 48 | tr -dc 'A-Za-z0-9' | head -c "$1"; }

cat <<EOF
AWX_SECRET_KEY=$(rand 50)
AWX_PG_PASSWORD=$(rand 32)
AWX_BROADCAST_WEBSOCKET_SECRET=$(rand 32)
DJANGO_SUPERUSER_PASSWORD=$(rand 20)
EOF
