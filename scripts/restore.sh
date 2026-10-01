#!/usr/bin/env bash
#
# restore.sh - restore AWX from a backup.sh run onto this host.
#
# Usage: restore.sh /backup/awx/20261001-011500
#
# Stops AWX, restores .env (for the SECRET_KEY) and the database, then
# starts everything again. awx-init re-runs migrations, so restoring a
# backup from an older AWX version onto a newer image also works.

set -euo pipefail

src=${1:?usage: restore.sh <backup-dir>}
COMPOSE_DIR="$(cd "$(dirname "$0")/../docker" && pwd)"
dc() { docker compose -f "$COMPOSE_DIR/docker-compose.yml" "$@"; }

( cd "$src" && sha256sum -c --quiet SHA256SUMS ) || { echo "Checksum mismatch in $src" >&2; exit 1; }

read -r -p "This replaces the current AWX database. Type 'restore' to continue: " answer
[[ "$answer" == "restore" ]] || exit 1

[[ -f "$COMPOSE_DIR/.env" ]] && cp "$COMPOSE_DIR/.env" "$COMPOSE_DIR/.env.before-restore"
cp "$src/env" "$COMPOSE_DIR/.env"
# shellcheck disable=SC1091
source "$COMPOSE_DIR/.env"

dc stop awx-web awx-task
dc up -d postgres
until dc exec -T postgres pg_isready -U "$AWX_PG_USER" >/dev/null 2>&1; do sleep 2; done

dc exec -T postgres dropdb -U "$AWX_PG_USER" --if-exists "$AWX_PG_DATABASE"
dc exec -T postgres createdb -U "$AWX_PG_USER" "$AWX_PG_DATABASE"
dc exec -T postgres pg_restore -U "$AWX_PG_USER" -d "$AWX_PG_DATABASE" --no-owner < "$src/awx.pgdump"

dc up -d
echo "Restored from $src. Watch: docker compose logs -f awx-init"
