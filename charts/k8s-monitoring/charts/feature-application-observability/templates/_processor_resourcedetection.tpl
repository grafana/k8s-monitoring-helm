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