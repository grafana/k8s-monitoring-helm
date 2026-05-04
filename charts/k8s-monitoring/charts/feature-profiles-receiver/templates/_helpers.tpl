{{- define "feature.profilesReceiver.escape_label" -}}
{{ . | replace "-" "_" | replace "." "_" | replace "/" "_" }}
{{- end }}

{{- define "feature.profilesReceiver.pod_annotation" -}}
{{ printf "__meta_kubernetes_pod_annotation_%s" (include "feature.profilesReceiver.escape_label" .) }}
{{- end }}

{{- define "feature.profilesReceiver.pod_label" -}}
{{ printf "__meta_kubernetes_pod_label_%s" (include "feature.profilesReceiver.escape_label" .) }}
{{- end }}
