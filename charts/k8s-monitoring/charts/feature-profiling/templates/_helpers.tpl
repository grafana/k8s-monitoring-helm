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

