{{- define "feature.autoInstrumentation.notes.deployments" }}
* Grafana Beyla (Daemonset)
{{- end }}

{{- define "feature.autoInstrumentation.notes.task" }}
Automatically instrument applications and services running in the cluster with Grafana Beyla
{{- end }}

{{- define "feature.autoInstrumentation.notes.actions" }}{{- end }}

{{- define "feature.autoInstrumentation.summary" -}}
version: {{ .Chart.Version }}
{{- end }}
