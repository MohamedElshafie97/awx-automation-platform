#!/bin/bash
#
# One-shot bootstrap, run by the awx-init service before web and task start.
# Every step is idempotent, so it runs on every `docker compose up` and also
# applies migrations after an AWX version bump.

set -euo pipefail

log() { echo "[awx-init] $*"; }

log "Waiting for the database"
until awx-manage check --database default >/dev/null 2>&1; do sleep 3; done

log "Applying migrations (first start takes a few minutes)"
awx-manage migrate --noinput

if ! awx-manage shell -c "from django.contrib.auth.models import User; exit(0 if User.objects.filter(username='${AWX_ADMIN_USER}').exists() else 1)" 2>/dev/null; then
    log "Creating admin user ${AWX_ADMIN_USER}"
    awx-manage createsuperuser --noinput --username "${AWX_ADMIN_USER}" --email "${AWX_ADMIN_EMAIL}"
fi

# The task container's hostname is the instance AWX schedules work on.
# Registering it here means the queues exist before the first job.
log "Registering instance and queues"
awx-manage provision_instance --hostname=awx-task --node_type=hybrid
awx-manage register_queue --queuename=controlplane --hostnames=awx-task
awx-manage register_queue --queuename=default --hostnames=awx-task
awx-manage register_default_execution_environments

log "Done"
