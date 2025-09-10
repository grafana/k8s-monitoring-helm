{{/* Inputs: Values (values) logsOutput, tracesOutput, name */}}
{{- define "feature.frontendObservability.processor.batch.alloy.target" }}otelcol.processor.batch.{{ .name | default "default" }}.input{{ end }}
{{- define "feature.frontendObservability.processor.batch.alloy" }}
otelcol.processor.batch {{ .name | default "default" | quote }} {
  send_batch_size = {{ .Values.processors.batch.size }}
  send_batch_max_size = {{ .Values.processors.batch.maxSize }}
  timeout = {{ .Values.processors.batch.timeout | quote}}

  output {
{{- if .logs }}
    logs = {{ .logs }}
{{- end }}
{{- if .traces }}
    traces = {{ .traces }}
{{- end }}
  }
}
{{- end }}
