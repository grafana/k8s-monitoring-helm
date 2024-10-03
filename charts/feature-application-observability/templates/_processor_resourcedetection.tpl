{{/* Inputs: Values (values) metricsOutput, logsOutput, tracesOutput, name */}}
{{/* https://grafana.com/docs/alloy/latest/reference/components/otelcol/otelcol.processor.resourcedetection/ */}}
{{- define "feature.applicationObservability.processor.resourcedetection.alloy.target" }}otelcol.processor.resourcedetection.{{ .name | default "default" }}.input{{ end }}
{{- define "feature.applicationObservability.processor.resourcedetection.alloy" }}
otelcol.processor.resourcedetection "{{ .name | default "default" }}" {
  detectors = ["env", "system"]
  system {
    hostname_sources = ["os"]
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