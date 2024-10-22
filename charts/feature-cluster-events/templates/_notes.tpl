{{- define "feature.clusterEvents.notes.deployments" }}{{- end }}

{{- define "feature.clusterEvents.notes.task" }}
Gather Kubernetes Cluster events{{- if .Values.namespaces }} from the namespaces {{ .Values.namespaces | join "," }}{{- end }}
{{- end }}

{{- define "feature.clusterEvents.notes.actions" }}{{- end }}

{{- define "feature.clusterEvents.summary" -}}
version: {{ .Chart.Version }}
{{- end }}
