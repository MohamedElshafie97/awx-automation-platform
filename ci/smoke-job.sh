#!/usr/bin/env bash
#
# End-to-end smoke test: create an inventory with localhost and run an
# ad-hoc `ping` through AWX. Passing means the whole chain works:
# API -> dispatcher -> receptor -> ansible-runner -> podman EE container.

set -euo pipefail

API=${AWX_URL:-http://127.0.0.1:8080}/api/v2
AUTH="admin:${DJANGO_SUPERUSER_PASSWORD:?}"

api() {
    local method=$1 path=$2 data=${3:-}
    curl -fsS -u "$AUTH" -X "$method" -H 'Content-Type: application/json' \
        ${data:+-d "$data"} "$API$path"
}
field() { python3 -c "import json,sys; print(json.load(sys.stdin)$1)"; }

org=$(api POST /organizations/ '{"name": "CI"}' | field '["id"]')
inv=$(api POST /inventories/ "{\"name\": \"ci-local\", \"organization\": $org}" | field '["id"]')
api POST "/inventories/$inv/hosts/" \
    '{"name": "localhost", "variables": "ansible_connection: local\nansible_python_interpreter: /usr/bin/python3"}' >/dev/null

job=$(api POST /ad_hoc_commands/ "{\"inventory\": $inv, \"module_name\": \"ping\", \"limit\": \"localhost\"}" | field '["id"]')
echo "ad-hoc command $job launched"

status=pending
for _ in $(seq 1 90); do
    status=$(api GET "/ad_hoc_commands/$job/" | field '["status"]')
    case $status in
        successful) echo "job $job: $status"; api GET "/ad_hoc_commands/$job/stdout/?format=txt" ; exit 0 ;;
        failed|error|canceled) break ;;
    esac
    sleep 5
done

explanation=$(api GET "/ad_hoc_commands/$job/" | field '.get("job_explanation", "")')
stdout=$(api GET "/ad_hoc_commands/$job/stdout/?format=txt" | tail -15 | tr '\n' '~')
echo "::error title=ad-hoc job $status::${explanation} ${stdout//~/ %0A }"
exit 1
