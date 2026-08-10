{{- define "escape_label_or_annotation" -}}
{{ . | replace "-" "_" | replace "." "_" | replace "/" "_" }}
{{- end }}

{{- define "pod_annotation" -}}
{{ printf "__meta_kubernetes_pod_annotation_%s" (include "escape_label_or_annotation" .) }}
{{- end }}

{{- define "pod_label" -}}
{{ printf "__meta_kubernetes_pod_label_%s" (include "escape_label_or_annotation" .) }}
{{- end }}

{{- define "service_annotation" -}}
{{ printf "__meta_kubernetes_service_annotation_%s" (include "escape_label_or_annotation" .) }}
{{- end }}

{{- define "service_label" -}}
{{ printf "__meta_kubernetes_service_label_%s" (include "escape_label_or_annotation" .) }}
{{- end }}

{{- define "helper.namespace" -}}
{{- .Values.global.namespaceOverride | default .Release.Namespace -}}
{{- end -}}

{{/*
Detect whether a list of namespaces contains any regular expression, as opposed to only exact namespace
names. A Kubernetes namespace name must be a valid DNS-1123 label (`[a-z0-9]([-a-z0-9]*[a-z0-9])?`, max 63
characters), so any entry containing a character outside that alphabet, or exceeding the length limit, can
only be a regular expression. Outputs "true" if any entry is a regex, and "false" otherwise.
*/}}
{{- define "feature.profiling.namespaces.hasRegex" -}}
{{- $hasRegex := "false" -}}
{{- range . -}}
  {{- if or (not (regexMatch "^[a-z0-9]([-a-z0-9]*[a-z0-9])?$" .)) (gt (len .) 63) -}}
    {{- $hasRegex = "true" -}}
  {{- end -}}
{{- end -}}
{{- $hasRegex -}}
{{- end -}}

