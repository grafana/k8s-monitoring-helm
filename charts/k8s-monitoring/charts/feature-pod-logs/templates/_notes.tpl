{{- define "feature.podLogs.notes.deployments" }}{{- end }}

{{- define "feature.podLogs.notes.task" }}
Gather logs from Kubernetes Pods
{{- end }}

{{- define "feature.podLogs.notes.actions" }}{{- end }}

{{- define "feature.podLogs.summary" -}}
version: {{ .Chart.Version }}
method: {{ .Values.gatherMethod }}
{{- end }}
