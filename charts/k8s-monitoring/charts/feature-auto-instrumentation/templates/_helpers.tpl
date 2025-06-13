{{- define "escape_annotation" -}}
{{ . | replace "-" "_" | replace "." "_" | replace "/" "_" }}
{{- end }}

{{- define "pod_annotation" -}}
{{ printf "__meta_kubernetes_pod_annotation_%s" (include "escape_annotation" .) }}
{{- end }}

{{- define "service_annotation" -}}
{{ printf "__meta_kubernetes_service_annotation_%s" (include "escape_annotation" .) }}
{{- end }}
