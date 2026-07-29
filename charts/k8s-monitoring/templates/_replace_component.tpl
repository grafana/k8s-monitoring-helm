{{/*
Helpers for applying user-supplied `replaceComponent` entries to rendered Alloy configs.

Each replacement targets a component emitted with a `} // <type> "<name>"` close tag. A
replacement is validated across *all* enabled collectors: it only needs to match one of
them (see the cross-collector check in alloy-config.yaml). `apply` operates on a single
collector's config and never fails — it returns the config with the replacement applied, or
unchanged if the component isn't present. The caller detects whether it applied by comparing
the returned config to the input; the marker comment `apply` inserts on a match guarantees the
config changes whenever it matches, even if the new body is identical to the old one.
`notFoundError` is what aborts the render once a replacement is known to match no collector.

A replacement with `module: <name>` is scoped to the `declare "<module>" { ... }` block. If
that module isn't present in a given config, the replacement does not match it.
*/}}

{{/*
replaceComponent.key — return a unique key for this replacement

Inputs:
  .type
  .name
  .module?
*/}}
{{- define "replaceComponent.key" }}
{{- if .module }}
  {{- printf "[%s] %s \"%s\"" .module .type .name }}
{{- else }}
  {{- printf "%s \"%s\"" .type .name }}
{{- end }}
{{- end }}

{{/*
replaceComponent.apply — return .config with this replacement applied.

If the replacement's component is present it is replaced (and a marker comment is inserted so
the override is visible in the rendered ConfigMap); otherwise .config is returned unchanged.

Inputs:
  .config      — the rendered Alloy config string
  .replacement — a single {type, name, module?, content} entry
*/}}
{{- define "replaceComponent.apply" -}}
{{- $config := .config }}
{{- $escapedType := replace "." "\\." .replacement.type }}
{{- $componentRegex := printf "(?s)%s \"%s\" \\{.*?\\} // %s \"%s\"" $escapedType .replacement.name $escapedType .replacement.name -}}
{{- /* Mark the body so a rendered ConfigMap alone shows the component was overridden (useful for triage). */ -}}
{{- $marker := "// This component was replaced by the chart's `replaceComponent` setting." -}}
{{- $newBody := printf "%s \"%s\" {\n%s\n%s\n} // %s \"%s\"" .replacement.type .replacement.name $marker (trimSuffix "\n" .replacement.content) .replacement.type .replacement.name -}}
{{- if .replacement.module -}}
  {{- $moduleRegex := printf "(?s)declare \"%s\" \\{.*?\\} // declare \"%s\"" .replacement.module .replacement.module -}}
  {{- $moduleBlock := regexFind $moduleRegex .config -}}
  {{- if and $moduleBlock (regexFind $componentRegex $moduleBlock) -}}
    {{- $newModuleBlock := regexReplaceAllLiteral $componentRegex $moduleBlock $newBody -}}
    {{- $config = replace $moduleBlock $newModuleBlock .config -}}
  {{- end -}}
{{- else -}}
  {{- if regexFind $componentRegex .config -}}
    {{- $config = regexReplaceAllLiteral $componentRegex .config $newBody -}}
  {{- end -}}
{{- end -}}
{{- $config -}}
{{- end -}}

{{/*
replaceComponent.notFoundError — print an error message about a replacement that matched no collector.

Inputs:
  .replacement — the {type, name, module?} entry that could not be found
*/}}
{{- define "replaceComponent.notFoundError" -}}
{{- $msg := list "" (printf "Could not find the component %s %q to replace in any collector's configuration." .replacement.type .replacement.name) "" -}}
{{- if .replacement.module -}}
  {{- $msg = append $msg (printf "Ensure the component exists inside a `declare %q { ... }` block that is rendered by at least one collector, and that its template emits a `} // %s %q` closing tag." .replacement.module .replacement.type .replacement.name) -}}
{{- else -}}
  {{- $msg = append $msg (printf "Ensure the component is rendered by at least one collector and that its template emits a `} // %s %q` closing tag." .replacement.type .replacement.name) -}}
{{- end -}}
{{- $msg = append $msg "Or, mark this replacement as optional to skip it when it is not present:" -}}
{{- $msg = append $msg "replaceComponent:" -}}
{{- $msg = append $msg (printf "  - type: %s" .replacement.type) -}}
{{- $msg = append $msg (printf "    name: %s" .replacement.name) -}}
{{- if .replacement.module -}}
  {{- $msg = append $msg (printf "    module: %s" .replacement.module) -}}
{{- end -}}
{{- $msg = append $msg "    optional: true" -}}
{{- $msg = append $msg "    content: ..." -}}
{{- fail (join "\n" $msg) -}}
{{- end -}}
