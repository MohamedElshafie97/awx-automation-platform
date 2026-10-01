#!/bin/bash
#
# awx-task entrypoint: wait for receptor (awx-ee) and migrations, then start
# the AWX task services (dispatcher, callback receiver, wsrelay).
#
# AWX's own launch_awx_task.sh isn't used because it calls
# `awx-manage provision_instance` without a hostname, which is the
# Kubernetes path (it would register the default queue as a container
# group). awx-init registers this node explicitly instead.

set -euo pipefail

for _ in $(seq 1 60); do
    [[ -S /var/run/receptor/receptor.sock ]] && break
    sleep 1
done
[[ -S /var/run/receptor/receptor.sock ]] || { echo "receptor socket not found - is awx-ee running?" >&2; exit 1; }

wait-for-migrations

exec supervisord -c /etc/supervisord_task.conf
