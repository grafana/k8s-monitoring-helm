{{/* Inputs: Values (values) metricsOutput, logsOutput, tracesOutput, name */}}
{{- define "feature.applicationObservability.processor.interval.alloy.target" }}otelcol.processor.interval.{{ .name | default "default" }}.input{{ end }}
{{- define "feature.applicationObservability.processor.interval.alloy" }}
otelcol.processor.interval {{ .name | default "default" | quote }} {
  interval = {{ .Values.processors.interval.interval | quote }}
  passthrough {
    gauge = {{ .Values.processors.interval.passthrough.gauge }}
    summary = {{ .Values.processors.interval.passthrough.summary }}
  }

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