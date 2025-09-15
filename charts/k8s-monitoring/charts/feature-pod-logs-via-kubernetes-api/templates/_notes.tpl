{{- define "feature.podLogsViaKubernetesApi.notes.deployments" }}{{- end }}

{{- define "feature.podLogsViaKubernetesApi.notes.task" }}
Gather logs from Kubernetes Pods via the Kubernetes API
{{- end }}

{{- define "feature.podLogsViaKubernetesApi.notes.actions" }}{{- end }}

{{- define "feature.podLogsViaKubernetesApi.summary" -}}
version: {{ .Chart.Version }}
{{- end }}
