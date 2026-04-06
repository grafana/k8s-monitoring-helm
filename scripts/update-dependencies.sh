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
        if [[ -n "$repo" && "$repo" != "null" && "$repo" != "" && "$repo" != '""' ]]; then
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
        repo_name=$(echo "$repo" | sed -e 's|https\?://||' -e 's|/\?$||' -e 's|[^a-zA-Z0-9]|-|g')
        latest_version=$(helm search repo "$repo_name/$name" --output json 2>/dev/null | jq -r '.[0].version // empty')

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
