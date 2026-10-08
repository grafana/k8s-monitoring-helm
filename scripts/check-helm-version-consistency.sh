#!/usr/bin/env bash
set -euo pipefail

repoRoot="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
expectedVersion="$(<"${repoRoot}/.helm-version")"
failed=false

if [[ ! "${expectedVersion}" =~ ^[0-9]+[.][0-9]+[.][0-9]+$ ]]; then
    echo "Invalid version in .helm-version: ${expectedVersion}" >&2
    exit 1
fi

while IFS= read -r makefile; do
    while IFS= read -r actualVersion; do
        if [[ "${actualVersion}" != "${expectedVersion}" ]]; then
            echo "${makefile#"${repoRoot}/"}: HELM_VERSION is ${actualVersion}, expected ${expectedVersion}" >&2
            failed=true
        fi
    done < <(sed -n 's/^HELM_VERSION ?= //p' "${makefile}")
done < <(find "${repoRoot}" -type f \( -name Makefile -o -name '*.mk' \) -print)

while IFS= read -r workflow; do
    setupCount=$(grep -c 'uses: azure/setup-helm@' "${workflow}" || true)
    versionLines=$(awk '
        /uses: azure\/setup-helm@/ { expectingVersion = 1; next }
        expectingVersion && /^[[:space:]]+version:/ {
            print NR ":" $2
            expectingVersion = 0
        }
    ' "${workflow}")
    versionCount=$(printf '%s\n' "${versionLines}" | grep -c . || true)

    if [[ "${setupCount}" -ne "${versionCount}" ]]; then
        echo "${workflow#"${repoRoot}/"}: found ${setupCount} setup-helm steps but ${versionCount} version values" >&2
        failed=true
    fi

    while IFS=: read -r lineNumber actualVersion; do
        [[ -z "${lineNumber}" ]] && continue
        if [[ "${actualVersion}" != "v${expectedVersion}" ]]; then
            echo "${workflow#"${repoRoot}/"}:${lineNumber}: Helm version is ${actualVersion}, expected v${expectedVersion}" >&2
            failed=true
        fi
    done <<< "${versionLines}"
done < <(find "${repoRoot}/.github/workflows" -type f \( -name '*.yml' -o -name '*.yaml' \) -print)

if [[ "${failed}" == true ]]; then
    exit 1
fi

echo "All development and CI Helm versions match ${expectedVersion}."
