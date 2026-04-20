{{/*
Applies user-supplied replacements to an Alloy config string.

Each replacement must match a component emitted with a `} // <type> "<name>"` close tag.
If no match is found, the render fails with a diagnostic pointing at the collector.

Inputs:
  .config         — the rendered Alloy config string
  .replacements   — list of {type, name, content} entries from .Values.replaceComponent
  .collectorName  — name of the collector being rendered (for error messages)

Returns: the config string with replacements applied.
*/}}
{{- define "replaceComponent.apply" -}}
{{- $config := .config -}}
{{- range $replacement := .replacements -}}
  {{- $escapedType := replace "." "\\." $replacement.type -}}
  {{- $componentRegex := printf "(?s)%s \"%s\" \\{.*?\\} // %s \"%s\"" $escapedType $replacement.name $escapedType $replacement.name -}}
  {{- if not (regexFind $componentRegex $config) -}}
    {{- fail (printf "replaceComponent: component %s %q not found in rendered config for collector %q. Ensure the component exists and its template emits a `} // %s %q` close tag." $replacement.type $replacement.name $.collectorName $replacement.type $replacement.name) -}}
  {{- end -}}
  {{- $newBody := printf "%s \"%s\" {\n%s\n} // %s \"%s\"" $replacement.type $replacement.name (trimSuffix "\n" $replacement.content) $replacement.type $replacement.name -}}
  {{- $config = regexReplaceAllLiteral $componentRegex $config $newBody -}}
{{- end -}}
{{- $config -}}
{{- end -}}
