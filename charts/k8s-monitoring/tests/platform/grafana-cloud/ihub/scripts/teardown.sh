#!/usr/bin/env bash
# Usage: teardown.sh <cluster-name>
set -uo pipefail

CLUSTER="${1:?usage: teardown.sh <cluster-name>}"

if ! command -v gcx >/dev/null 2>&1; then
  echo "teardown: gcx not found; skipping Fleet Management cleanup" >&2
  exit 0
fi

# Best-effort: keep going on failure, but surface gcx errors (silent failures
# here read as "teardown did nothing" and leave orphaned FM rows behind).
echo "Removing k8s monitoring for cluster=${CLUSTER}..." >&2
gcx instrumentation clusters remove "${CLUSTER}" --yes >&2 \
  || echo "teardown: 'clusters remove ${CLUSTER}' failed (continuing)" >&2

# Family 3 (application observability): gcx clusters remove does NOT remove the
# app-instrumentation pipelines, so drop the namespace entry explicitly for tiers
# that enabled it (standard/maximum set IHUB_APP_NAMESPACE). Requires gcx >= 1.1.1.
if [ -n "${IHUB_APP_NAMESPACE:-}" ]; then
  echo "Disabling application observability for namespace=${IHUB_APP_NAMESPACE}..." >&2
  gcx instrumentation clusters apps remove "${CLUSTER}" "${IHUB_APP_NAMESPACE}" --yes >&2 \
    || echo "teardown: disabling app observability failed (continuing)" >&2
fi

# gcx returns collector ids in the resource model, so metadata.name carries a
# "resource-" prefix; the delete API wants the raw id, so strip it.
col_ids="$(gcx fleet collectors list -o json --limit 0 2>/dev/null \
  | jq -r --arg c "${CLUSTER}" '.[]? | select((.metadata.name // "") | contains($c)) | (.metadata.name | ltrimstr("resource-"))' 2>/dev/null)"
for id in ${col_ids}; do
  echo "Deleting collector ${id}" >&2
  gcx fleet collectors delete "${id}" >&2 \
    || echo "teardown: 'collectors delete ${id}' failed (continuing)" >&2
done
