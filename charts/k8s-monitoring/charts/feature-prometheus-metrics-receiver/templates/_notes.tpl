{{- define "feature.prometheusMetricsReceiver.notes.deployments" }}{{- end }}

{{- define "feature.prometheusMetricsReceiver.notes.task" }}
Open an HTTP receiver for Prometheus metrics
{{- end }}

{{- define "feature.prometheusMetricsReceiver.notes.actions" }}{{- end }}

{{- define "feature.prometheusMetricsReceiver.summary" -}}
version: {{ .Chart.Version }}
{{- end }}
