{{- define "feature.integrations.notes.deployments" }}{{- end }}

{{- define "feature.integrations.notes.task" }}
{{- $sources := list }}
{{- if .Values.alloy.instances -}}{{- $sources = append $sources "Alloy" -}}{{- end -}}
{{- if (index .Values "cert-manager").instances -}}{{- $sources = append $sources "cert-manager" -}}{{- end -}}
{{- if .Values.etcd.instances -}}{{- $sources = append $sources "etcd" -}}{{- end -}}
{{- if .Values.loki.instances -}}{{- $sources = append $sources "loki" -}}{{- end -}}
{{- if .Values.mysql.instances -}}{{- $sources = append $sources "MySql" -}}{{- end -}}
{{- if $sources }}
Gather data from the {{ include "english_list" $sources }} {{ if eq (len $sources) 1 }}integration{{ else }}integrations{{ end }}.
{{- end }}
{{- end }}

{{- define "feature.integrations.notes.actions" }}{{- end }}

{{- define "feature.integrations.summary" -}}
{{- $sources := list }}
{{- if .Values.alloy.instances -}}{{- $sources = append $sources "alloy" -}}{{- end -}}
{{- if (index .Values "cert-manager").instances -}}{{- $sources = append $sources "cert-manager" -}}{{- end -}}
{{- if .Values.etcd.instances -}}{{- $sources = append $sources "etcd" -}}{{- end -}}
{{- if .Values.loki.instances -}}{{- $sources = append $sources "loki" -}}{{- end -}}
{{- if .Values.mysql.instances -}}{{- $sources = append $sources "mysql" -}}{{- end -}}
version: {{ .Chart.Version }}
sources: {{ $sources | join "," }}
{{- end }}
