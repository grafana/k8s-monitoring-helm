{{/* Inputs: Values (values) metricsOutput, logsOutput, tracesOutput, name */}}
{{- define "feature.applicationObservability.processor.memory_limiter.alloy.target" }}otelcol.processor.memory_limiter.{{ .name | default "default" }}.target{{ end }}
{{- define "feature.applicationObservability.processor.memory_limiter.alloy" }}
otelcol.processor.memory_limiter "{{ .name | default "default" }}" {
  check_interval = {{ .Values.processors.memoryLimiter.checkInterval | quote }}
  limit = {{ .Values.processors.memoryLimiter.limit | quote }}

  output {
{{- if and .metricsOutput .Values.metrics.enabled }}
    metrics = {{ .metricsOutput }}
{{- end }}
{{- if and .logsOutput .Values.logs.enabled }}
    logs = {{ .logsOutput }}
{{- end }}
{{- if and .tracesOutput .Values.traces.enabled }}
    traces = {{ .tracesOutput }}
{{- end }}
  }
}
{{- end }}