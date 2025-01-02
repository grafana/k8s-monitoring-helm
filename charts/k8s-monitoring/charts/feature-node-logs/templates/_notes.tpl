{{- define "feature.nodeLogs.notes.deployments" }}{{- end }}

{{- define "feature.nodeLogs.notes.task" }}
Gather logs from Kubernetes Nodes
{{- end }}

{{- define "feature.nodeLogs.notes.actions" }}{{- end }}

{{- define "feature.nodeLogs.summary" -}}
version: {{ .Chart.Version }}
{{- end }}
