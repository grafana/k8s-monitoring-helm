{{- define "feature.podLogsViaK8sAPI.notes.deployments" }}{{- end }}

{{- define "feature.podLogsViaK8sAPI.notes.task" }}
Gather logs from Kubernetes Pods via the Kubernetes API.
{{- end }}

{{- define "feature.podLogsViaK8sAPI.notes.actions" }}{{- end }}

{{- define "feature.podLogsViaK8sAPI.summary" -}}
version: {{ .Chart.Version }}
{{- end }}
