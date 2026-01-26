{{- define "feature.podLogsObjects.notes.deployments" }}{{- end }}

{{- define "feature.podLogsObjects.notes.task" }}
gather Kubernetes Pod logs using PodLogs objects.
{{- end }}

{{- define "feature.podLogsObjects.notes.actions" }}{{- end }}

{{- define "feature.podLogsObjects.summary" -}}
version: {{ .Chart.Version }}
{{- end }}
