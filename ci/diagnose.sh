#!/usr/bin/env bash
#
# Turn container logs into GitHub annotations so a failed CI run can be
# diagnosed from the run summary without downloading logs.

cd "$(dirname "$0")/../docker" || exit 1

for svc in awx-init awx-task awx-ee awx-web postgres redis; do
    state=$(docker compose ps -a --format '{{.Service}} {{.State}} {{.ExitCode}}' | awk -v s="$svc" '$1==s {print $2" exit="$3}')
    lines=$(docker compose logs --no-color --tail 25 "$svc" 2>&1 \
        | sed -E 's/^[^|]*\| //' | grep -v '^\s*$' | tail -25 | tr '\n' '~' | cut -c1-3500)
    echo "::error title=${svc} (${state:-missing})::${lines//~/ %0A }"
done
