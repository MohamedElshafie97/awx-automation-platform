#!/bin/bash
#
# awx-task entrypoint: start receptor, then the AWX task services
# (dispatcher, callback receiver, wsrelay) under supervisord.
#
# AWX's own launch_awx_task.sh isn't used because it calls
# `awx-manage provision_instance` without a hostname, which is the
# Kubernetes path (it would register the default queue as a container
# group). awx-init registers this node explicitly instead.

set -euo pipefail

mkdir -p /var/run/receptor
receptor --config /etc/receptor/receptor.conf &

# Don't let AWX submit work before the control socket exists
for _ in $(seq 1 30); do
    [[ -S /var/run/receptor/receptor.sock ]] && break
    sleep 1
done
[[ -S /var/run/receptor/receptor.sock ]] || { echo "receptor did not start" >&2; exit 1; }

wait-for-migrations

exec supervisord -c /etc/supervisord_task.conf
