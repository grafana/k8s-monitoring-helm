{{/* Inputs: Values (values) logsOutput, tracesOutput, name */}}
{{- define "feature.frontendObservability.processor.memory_limiter.alloy.target" }}otelcol.processor.memory_limiter.{{ .name | default "default" }}.input{{ end }}
{{- define "feature.frontendObservability.processor.memory_limiter.alloy" }}
otelcol.processor.memory_limiter "{{ .name | default "default" }}" {
  check_interval = {{ .Values.processors.memoryLimiter.checkInterval | quote }}
  limit = {{ .Values.processors.memoryLimiter.limit | quote }}

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
