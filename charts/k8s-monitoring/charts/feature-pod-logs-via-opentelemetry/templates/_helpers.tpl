{{- define "escape_label" -}}
{{ . | replace "-" "_" | replace "." "_" | replace "/" "_" }}
{{- end }}

{{- define "pod_label" -}}
{{ printf "__meta_kubernetes_pod_label_%s" (include "escape_label" .) }}
{{- end }}

{{- define "pod_annotation" -}}
{{ printf "__meta_kubernetes_pod_annotation_%s" (include "escape_label" .) }}
{{- end }}
