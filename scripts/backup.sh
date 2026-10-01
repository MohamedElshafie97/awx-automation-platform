#!/usr/bin/env bash
#
# backup.sh - nightly AWX backup: database dump + the .env file.
#
# Both are needed to restore. The database holds every credential, but
# encrypted with AWX_SECRET_KEY from .env; a dump without the matching key
# restores a working AWX whose credentials can't be decrypted.
#
# Usage: backup.sh [-d BACKUP_DIR] [-r RETENTION_DAYS]
# Cron:  15 1 * * * /opt/awx/scripts/backup.sh -d /backup/awx -r 14 >> /var/log/awx-backup.log 2>&1

set -euo pipefail
umask 077

COMPOSE_DIR="$(cd "$(dirname "$0")/../docker" && pwd)"
DEST=/backup/awx
RETENTION=14

while getopts ":d:r:h" opt; do
    case "$opt" in
        d) DEST="$OPTARG" ;;
        r) RETENTION="$OPTARG" ;;
        h) sed -n '3,12p' "$0"; exit 0 ;;
        *) echo "Unknown option -$OPTARG" >&2; exit 2 ;;
    esac
done

log() { echo "$(date '+%F %T') $*"; }

# shellcheck disable=SC1091
source "$COMPOSE_DIR/.env"

stamp=$(date +%Y%m%d-%H%M%S)
run="$DEST/$stamp"
mkdir -p "$run"

log "Dumping database ${AWX_PG_DATABASE}"
docker compose -f "$COMPOSE_DIR/docker-compose.yml" exec -T postgres \
    pg_dump -U "$AWX_PG_USER" -d "$AWX_PG_DATABASE" -Fc > "$run/awx.pgdump"

# pg_restore --list fails on a truncated or corrupt custom-format dump
docker compose -f "$COMPOSE_DIR/docker-compose.yml" exec -T postgres \
    pg_restore --list < "$run/awx.pgdump" > /dev/null

cp "$COMPOSE_DIR/.env" "$run/env"
( cd "$run" && sha256sum awx.pgdump env > SHA256SUMS )

log "Backup OK: $run ($(du -sh "$run" | cut -f1))"

find "$DEST" -mindepth 1 -maxdepth 1 -type d -mtime +"$RETENTION" -exec rm -rf {} +
