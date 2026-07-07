#!/usr/bin/env bash
# Updates all external Helm chart dependencies in Chart.yaml files to their latest versions.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SEARCH_PATH="${1:-$REPO_ROOT/charts}"

# Resolve to absolute path if relative
if [[ "$SEARCH_PATH" != /* ]]; then
    SEARCH_PATH="$(cd "$SEARCH_PATH" && pwd)"
fi

# Collect all unique repositories from all Chart.yaml files and add them to Helm
echo "Adding Helm repositories..."
repos_added=()
add_repo() {
    local url="$1"
    # Derive a stable repo name from the URL
    local name
    name=$(echo "$url" | sed -e 's|https\?://||' -e 's|/\?$||' -e 's|[^a-zA-Z0-9]|-|g')

    for added in "${repos_added[@]+"${repos_added[@]}"}"; do
        if [[ "$added" == "$url" ]]; then
            return
        fi
    done

    helm repo add "$name" "$url" --force-update >/dev/null 2>&1
    repos_added+=("$url")
}

# Obtain a bearer token for an OCI registry that issues a Docker Registry v2 auth
# challenge. Echoes the token, or nothing if the registry allows anonymous access.
oci_token() {
    local registry="$1" repo_path="$2"
    local challenge realm service scope token_url
    # Use GET (with the body discarded) rather than HEAD: some registries (ghcr.io)
    # only return the auth challenge on GET.
    challenge=$(curl -s -D - -o /dev/null "https://${registry}/v2/${repo_path}/tags/list" \
        | tr -d '\r' | grep -i '^www-authenticate:' || true)
    if [[ -z "$challenge" ]]; then
        return 0
    fi
    realm=$(echo "$challenge" | grep -o 'realm="[^"]*"' | cut -d'"' -f2 || true)
    service=$(echo "$challenge" | grep -o 'service="[^"]*"' | cut -d'"' -f2 || true)
    scope=$(echo "$challenge" | grep -o 'scope="[^"]*"' | cut -d'"' -f2 || true)
    [[ -z "$realm" ]] && return 0
    token_url="$realm"
    [[ -n "$service" ]] && token_url="${token_url}?service=${service}"
    [[ -n "$scope" ]] && token_url="${token_url}&scope=${scope}"
    curl -s "$token_url" | jq -r '.token // .access_token // empty' 2>/dev/null || true
}

# List all tags for an OCI repository, following Link-header pagination.
oci_list_tags() {
    local registry="$1" repo_path="$2" token="$3"
    local url="https://${registry}/v2/${repo_path}/tags/list?n=100"
    local auth=()
    [[ -n "$token" ]] && auth=(-H "Authorization: Bearer $token")
    local hdr body next
    hdr=$(mktemp)
    body=$(mktemp)
    while [[ -n "$url" ]]; do
        curl -s -D "$hdr" -o "$body" "${auth[@]+"${auth[@]}"}" "$url"
        jq -r '.tags[]?' "$body" 2>/dev/null || true
        next=$(tr -d '\r' < "$hdr" | grep -i '^link:' | sed -E 's/.*<([^>]+)>.*/\1/' || true)
        if [[ -n "$next" ]]; then
            case "$next" in
                https://*) url="$next" ;;
                *) url="https://${registry}${next}" ;;
            esac
        else
            url=""
        fi
    done
    rm -f "$hdr" "$body"
}

# Find the latest stable (X.Y.Z) version of a chart hosted in an OCI registry.
# Args: repository (oci://host/path), chart name.
latest_oci_version() {
    local repo="$1" name="$2"
    local stripped="${repo#oci://}"
    local registry="${stripped%%/*}"
    local path="${stripped#*/}"
    local repo_path="${path}/${name}"
    local token versions
    token=$(oci_token "$registry" "$repo_path")
    versions=$(oci_list_tags "$registry" "$repo_path" "$token" \
        | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' || true)
    echo "$versions" | sort -V | tail -1
}

# Find all Chart.yaml files
chart_files=()
while IFS= read -r f; do
    chart_files+=("$f")
done < <(find "$SEARCH_PATH" -name Chart.yaml -type f)

# First pass: add all repos
for chart_file in "${chart_files[@]}"; do
    dep_count=$(yq '.dependencies | length' "$chart_file")
    for ((i = 0; i < dep_count; i++)); do
        repo=$(yq ".dependencies[$i].repository" "$chart_file")
        # OCI repositories are referenced directly and are not added via `helm repo add`.
        if [[ -n "$repo" && "$repo" != "null" && "$repo" != "" && "$repo" != '""' && "$repo" != oci://* ]]; then
            add_repo "$repo"
        fi
    done
done

echo "Updating Helm repositories..."
helm repo update >/dev/null 2>&1

# Second pass: update versions
updated_charts=()
for chart_file in "${chart_files[@]}"; do
    dep_count=$(yq '.dependencies | length' "$chart_file")
    relative_path="${chart_file#"$REPO_ROOT/"}"

    for ((i = 0; i < dep_count; i++)); do
        repo=$(yq ".dependencies[$i].repository" "$chart_file")
        if [[ -z "$repo" || "$repo" == "null" || "$repo" == "" || "$repo" == '""' ]]; then
            continue
        fi

        name=$(yq ".dependencies[$i].name" "$chart_file")
        current_version=$(yq ".dependencies[$i].version" "$chart_file")

        # Search for the latest version of this chart
        if [[ "$repo" == oci://* ]]; then
            latest_version=$(latest_oci_version "$repo" "$name")
        else
            repo_name=$(echo "$repo" | sed -e 's|https\?://||' -e 's|/\?$||' -e 's|[^a-zA-Z0-9]|-|g')
            latest_version=$(helm search repo "$repo_name/$name" --output json 2>/dev/null | jq -r '.[0].version // empty')
        fi

        if [[ -z "$latest_version" ]]; then
            echo "  WARNING: Could not find $name in $repo"
            continue
        fi

        if [[ "$current_version" != "$latest_version" ]]; then
            echo "  $relative_path: $name $current_version -> $latest_version"
            yq -i ".dependencies[$i].version = \"$latest_version\"" "$chart_file"
            # Track unique chart names
            already_tracked=false
            for c in "${updated_charts[@]+"${updated_charts[@]}"}"; do
                if [[ "$c" == "$name" ]]; then
                    already_tracked=true
                    break
                fi
            done
            if [[ "$already_tracked" == false ]]; then
                updated_charts+=("$name")
            fi
        fi
    done
done

if [[ ${#updated_charts[@]} -eq 0 ]]; then
    echo "All dependencies are up to date."
else
    echo ""
    IFS=','; echo "Updated charts: ${updated_charts[*]}"
    echo "Run 'make build' to regenerate Chart.lock files."
fi
