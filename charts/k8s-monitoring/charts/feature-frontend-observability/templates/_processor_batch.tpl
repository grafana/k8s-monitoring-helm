{{/* Inputs: Values (values) metricsOutput, logsOutput, tracesOutput, name */}}
{{- define "feature.applicationObservability.processor.batch.alloy.target" }}otelcol.processor.batch.{{ .name | default "default" }}.input{{ end }}
{{- define "feature.applicationObservability.processor.batch.alloy" }}
otelcol.processor.batch {{ .name | default "default" | quote }} {
  send_batch_size = {{ .Values.processors.batch.size }}
  send_batch_max_size = {{ .Values.processors.batch.maxSize }}
  timeout = {{ .Values.processors.batch.timeout | quote}}

  output {
{{- if and .metrics .Values.metrics.enabled }}
    metrics = {{ .metrics }}
{{- end }}
{{- if and .logs .Values.logs.enabled }}
    logs = {{ .logs }}
{{- end }}
{{- if and .traces .Values.traces.enabled }}
    traces = {{ .traces }}
{{- end }}
  }
}
{{- end }}