{{- define "feature.podLogsViaOpenTelemetry.notes.deployments" }}{{- end }}

{{- define "feature.podLogsViaOpenTelemetry.notes.task" }}
Gather logs from Kubernetes Pods
{{- end }}

{{- define "feature.podLogsViaOpenTelemetry.notes.actions" }}{{- end }}

{{- define "feature.podLogsViaOpenTelemetry.summary" -}}
version: {{ .Chart.Version }}
{{- end }}
