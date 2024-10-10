{{- define "feature.profiling.notes.deployments" }}{{- end }}

{{- define "feature.profiling.notes.task" }}
Gather profiles
{{- end }}

{{- define "feature.profiling.notes.actions" }}{{- end }}

{{- define "feature.profiling.summary" -}}
version: {{ .Chart.Version }}
method: {{ .Values.gatherMethod }}
{{- end }}
