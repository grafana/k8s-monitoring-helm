{{- define "feature.podLogs-via-filesytem-loki.notes.deployments" }}{{- end }}

{{- define "feature.podLogs-via-filesytem-loki.notes.task" }}
Gather logs from Kubernetes pods via the filesystem.
{{- end }}

{{- define "feature.podLogs-via-filesytem-loki.notes.actions" }}{{- end }}

{{- define "feature.podLogs-via-filesytem-loki.summary" -}}
version: {{ .Chart.Version }}
{{- end }}
