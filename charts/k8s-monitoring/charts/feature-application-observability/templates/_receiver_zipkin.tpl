{{/* Inputs: Values (values) tracesOutput */}}
{{- define "feature.applicationObservability.receiver.zipkin.alloy" }}
{{- if .Values.receivers.zipkin.enabled }}
otelcol.receiver.zipkin "receiver" {
  endpoint = "0.0.0.0:{{ .Values.receivers.zipkin.port | int }}"
  debug_metrics {
    disable_high_cardinality_metrics = {{ not .Values.receivers.zipkin.includeDebugMetrics }}
  }
  output {
{{- if and .tracesOutput .Values.traces.enabled }}
    traces = {{ .tracesOutput }}
{{- end }}
  }
}
{{- end }}
{{- end }}
