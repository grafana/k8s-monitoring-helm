{{/* Inputs: Values (values) metricsOutput, logsOutput, tracesOutput, name */}}
{{- define "feature.applicationObservability.processor.memory_limiter.alloy.target" }}otelcol.processor.memory_limiter.{{ .name | default "default" }}.input{{ end }}
{{- define "feature.applicationObservability.processor.memory_limiter.alloy" }}
otelcol.processor.memory_limiter "{{ .name | default "default" }}" {
  check_interval = {{ .Values.processors.memoryLimiter.checkInterval | quote }}
  limit = {{ .Values.processors.memoryLimiter.limit | quote }}

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