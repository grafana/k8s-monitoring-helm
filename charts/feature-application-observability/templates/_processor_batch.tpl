{{/* Inputs: Values (values) metricsOutput, logsOutput, tracesOutput, name */}}
{{- define "feature.applicationObservability.processor.batch.alloy.target" }}otelcol.processor.batch.{{ .name | default "default" }}.input{{ end }}
{{- define "feature.applicationObservability.processor.batch.alloy" }}
otelcol.processor.batch "{{ .name | default "default" }}" {
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