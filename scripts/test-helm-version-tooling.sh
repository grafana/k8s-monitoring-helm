#!/usr/bin/env bash
set -euo pipefail

repoRoot="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tempDir="$(mktemp -d)"
cleanup() {
    rm -rf "${tempDir}"
}
trap cleanup EXIT

mkdir -p "${tempDir}/scripts/bin"
cp -P "${repoRoot}/scripts/bin/helm" "${tempDir}/scripts/bin/helm"
cp "${repoRoot}/scripts/helm-with-version" "${tempDir}/scripts/helm-with-version"

export HELM_CLI_CACHE_DIR="${tempDir}/helm cache"
os=$(uname -s | tr '[:upper:]' '[:lower:]')
case "$(uname -m)" in
    x86_64 | amd64) arch=amd64 ;;
    arm64 | aarch64) arch=arm64 ;;
    *) echo "Unsupported test architecture" >&2; exit 1 ;;
esac
helmDir="${HELM_CLI_CACHE_DIR}/9.8.7/${os}-${arch}"
mkdir -p "${helmDir}"
cat > "${helmDir}/helm" <<'EOF'
#!/usr/bin/env bash
if [[ "${1:-}" == fail ]]; then
    exit 42
fi
printf '%s|' "$0" "$@"
EOF
chmod +x "${helmDir}/helm"

assertOutput() {
    local expected=$1
    shift
    local actual
    actual=$("$@")
    if [[ "${actual}" != "${expected}" ]]; then
        echo "Unexpected output from $*: ${actual}" >&2
        exit 1
    fi
}

helper="${tempDir}/scripts/helm-with-version"
helmEntry="${tempDir}/scripts/bin/helm"
assertOutput "${helmDir}/helm|version|--short|" "${helper}" 9.8.7 version --short
assertOutput "${helmDir}/helm|version|--short|" "${helper}" run v9.8.7 version --short
assertOutput "${helmDir}/helm" "${helper}" which v9.8.7
assertOutput "${helmDir}/helm|version|--short|" \
    bash -c "$("${helper}" export 9.8.7); helm version --short"

assertOutput "${helmDir}/helm|version|--short|" env HELM_VERSION=v9.8.7 "${helmEntry}" version --short
assertOutput "${helmDir}/helm|template|release|--values|values with spaces.yaml|" \
    env HELM_VERSION=9.8.7 "${helmEntry}" template release --values "values with spaces.yaml"
# These are arguments to Helm, not options for helm-with-version.
for argument in --help run which export; do
    assertOutput "${helmDir}/helm|${argument}|" env HELM_VERSION=9.8.7 "${helmEntry}" "${argument}"
done
assertOutput "${helmDir}/helm|" env HELM_VERSION=9.8.7 "${helmEntry}"
# External tools and child processes find the same implementation through PATH.
assertOutput "${helmDir}/helm|version|--short|" \
    env HELM_VERSION=9.8.7 PATH="${tempDir}/scripts/bin:${PATH}" bash -c 'helm version --short'

if (unset HELM_VERSION; "${helmEntry}" version >/dev/null 2>&1); then
    echo "Helm entry accepted an unset HELM_VERSION." >&2
    exit 1
fi

set +e
HELM_VERSION=9.8.7 "${helmEntry}" fail >/dev/null 2>&1
status=$?
set -e
if [[ "${status}" -ne 42 ]]; then
    echo "Helm entry did not propagate the client failure." >&2
    exit 1
fi

mkdir -p "${tempDir}/commands"
cat > "${tempDir}/commands/curl" <<'EOF'
#!/usr/bin/env bash
exit 42
EOF
chmod +x "${tempDir}/commands/curl"
if HELM_VERSION=9.8.6 PATH="${tempDir}/commands:${PATH}" "${helmEntry}" version >/dev/null 2>&1; then
    echo "Helm entry did not propagate a failed download." >&2
    exit 1
fi

makeOutput="$(make -C "${repoRoot}/charts/k8s-monitoring/tests/platform/gke" -n clean \
    HELM_REPO_ROOT=/definitely/missing 2>&1)"
if [[ "${makeOutput}" == *'/definitely/missing'* ]]; then
    echo "Platform Makefiles resolve Helm while parsing a Helm-independent target." >&2
    exit 1
fi

echo "Helm version tooling tests passed."
