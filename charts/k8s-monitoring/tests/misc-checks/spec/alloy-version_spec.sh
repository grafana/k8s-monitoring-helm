# shellcheck shell=sh

Describe 'Alloy version consistency'
  # The pinned Alloy version is embedded in several Makefile-generated files. They are generated
  # independently, so they drift apart if one is regenerated without the others (for example, the
  # Windows presets were once left on an older Alloy version than _collector_version.tpl). These
  # checks assert that every embedded copy matches the pinned tag in _collector_version.tpl.
  chart_root="${SHELLSPEC_PROJECT_ROOT}/../.."
  windows_suffix="windowsservercore-ltsc2022"

  # The pinned Alloy image tag (e.g. "v1.19.2") is the source of truth the other files must match.
  pinned_tag() {
    sed -n 's/.*pinnedImageTag" -}}\(.*\){{- *end.*/\1/p' \
      "${chart_root}/templates/collectors/_collector_version.tpl"
  }

  Describe 'templates/collectors/_collector_version.tpl'
    It 'defines a pinned Alloy image tag'
      When call pinned_tag
      The output should match pattern "v[0-9]*"
    End
  End

  Describe 'collectors/presets/windows.yaml'
    windows_preset_tag() {
      sed -n 's/^[[:space:]]*tag:[[:space:]]*//p' "${chart_root}/collectors/presets/windows.yaml"
    }
    It 'pins the Alloy image tag to the pinned version with the Windows Server Core suffix'
      When call windows_preset_tag
      The output should equal "$(pinned_tag)-${windows_suffix}"
    End
  End

  Describe 'collectors/presets/windows-scrapeable.yaml'
    windows_scrapeable_image() {
      sed -n 's|^[[:space:]]*image:[[:space:]]*\(docker.io/grafana/alloy:.*\)|\1|p' \
        "${chart_root}/collectors/presets/windows-scrapeable.yaml"
    }
    It 'pins the firewall init container image to the pinned version with the Windows Server Core suffix'
      When call windows_scrapeable_image
      The output should equal "docker.io/grafana/alloy:$(pinned_tag)-${windows_suffix}"
    End
  End

  Describe 'docs/Versions.md'
    # The row for the current chart version must list the pinned Alloy binary (without the leading "v").
    chart_version() {
      sed -n 's/^version:[[:space:]]*//p' "${chart_root}/Chart.yaml"
    }
    versions_md_column() {
      awk -F'|' -v v="$(chart_version)" -v col="$1" '
        { gsub(/[[:space:]]/, "", $2); gsub(/[[:space:]]/, "", $col) }
        $2 == v { print $col }
      ' "${chart_root}/docs/Versions.md"
    }
    versions_md_binary() {
      versions_md_column 5
    }
    # A tagged release's row keeps the Alloy Operator it shipped with, so it can't match a newer unreleased bump.
    released_with_other_operator() {
      operator="$(versions_md_column 3)"
      [ -n "${operator}" ] && [ "${operator}" != "${ALLOY_OPERATOR_VERSION}" ]
    }
    Skip if 'the current chart version was released with a different Alloy Operator' released_with_other_operator
    It 'lists the pinned Alloy binary version for the current chart version'
      When call versions_md_binary
      The output should equal "$(pinned_tag | sed 's/^v//')"
    End
  End
End
