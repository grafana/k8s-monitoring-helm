{{- define "escape_label" -}}
{{ . | replace "-" "_" | replace "." "_" | replace "/" "_" }}
{{- end }}

{{- define "pod_label" -}}
{{ printf "__meta_kubernetes_pod_label_%s" (include "escape_label" .) }}
{{- end }}

{{- define "pod_annotation" -}}
{{ printf "__meta_kubernetes_pod_annotation_%s" (include "escape_label" .) }}
{{- end }}

{{- define "helper.namespace" -}}
{{- .Values.global.namespaceOverride | default .Release.Namespace -}}
{{- end -}}

{{/*
Detect whether a list of namespaces contains any regular expression, as opposed to only exact namespace
names. A Kubernetes namespace name must be a valid DNS-1123 label (`[a-z0-9]([-a-z0-9]*[a-z0-9])?`, max 63
characters), so any entry containing a character outside that alphabet, or exceeding the length limit, can
only be a regular expression. Outputs "true" if any entry is a regex, and an empty string otherwise.
*/}}
{{- define "feature.podLogsViaLoki.namespaces.hasRegex" -}}
{{- $hasRegex := "false" -}}
{{- range . -}}
  {{- if or (not (regexMatch "^[a-z0-9]([-a-z0-9]*[a-z0-9])?$" .)) (gt (len .) 63) -}}
    {{- $hasRegex = "true" -}}
  {{- end -}}
{{- end -}}
{{- $hasRegex -}}
{{- end -}}
