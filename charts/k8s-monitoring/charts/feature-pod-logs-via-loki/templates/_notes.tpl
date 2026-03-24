{{- define "feature.podLogsViaLoki.notes.deployments" }}{{- end }}

{{- define "feature.podLogsViaLoki.notes.task" }}
Gather logs from Kubernetes Pods in Loki format
{{- end }}

{{- define "feature.podLogsViaLoki.notes.actions" }}{{- end }}

{{- define "feature.podLogsViaLoki.summary" -}}
version: {{ .Chart.Version }}
{{- end }}
