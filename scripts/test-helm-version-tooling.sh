#!/usr/bin/env bash
set -euo pipefail

repoRoot="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tempDir="$(mktemp -d)"
cleanup() {
    rm -rf "${tempDir}"
}
trap cleanup EXIT

mkdir -p "${tempDir}/scripts/bin"
cp "${repoRoot}/scripts/bin/helm" "${tempDir}/scripts/bin/helm"

cat > "${tempDir}/scripts/helm-with-version" <<'EOF'
#!/usr/bin/env bash
printf '%s|' "$@"
EOF
chmod +x "${tempDir}/scripts/helm-with-version"

actual="$(HELM_VERSION=9.8.7 "${tempDir}/scripts/bin/helm" version --short)"
expected='9.8.7|version|--short|'
if [[ "${actual}" != "${expected}" ]]; then
    echo "Helm shim did not forward the configured version and arguments." >&2
    exit 1
fi

if (unset HELM_VERSION; "${tempDir}/scripts/bin/helm" version >/dev/null 2>&1); then
    echo "Helm shim accepted an unset HELM_VERSION." >&2
    exit 1
fi

cat > "${tempDir}/scripts/helm-with-version" <<'EOF'
#!/usr/bin/env bash
exit 42
EOF
chmod +x "${tempDir}/scripts/helm-with-version"

set +e
HELM_VERSION=9.8.7 "${tempDir}/scripts/bin/helm" version >/dev/null 2>&1
status=$?
set -e
if [[ "${status}" -ne 42 ]]; then
    echo "Helm shim did not propagate the resolver failure." >&2
    exit 1
fi

makeOutput="$(make -C "${repoRoot}/charts/k8s-monitoring/tests/platform/gke" -n clean \
    HELM_REPO_ROOT=/definitely/missing 2>&1)"
if [[ "${makeOutput}" == *'/definitely/missing'* ]]; then
    echo "Platform Makefiles resolve Helm while parsing a Helm-independent target." >&2
    exit 1
fi

echo "Helm version tooling tests passed."
