{{/* Inputs: Values (values) metricsOutput, logsOutput, tracesOutput */}}
{{- define "feature.applicationObservability.receiver.otlp.alloy" }}
otelcol.receiver.otlp "receiver" {
{{- if .Values.receivers.otlp.grpc.enabled }}
  grpc {
    endpoint = "0.0.0.0:{{ .Values.receivers.otlp.grpc.port | int }}"
  }
{{- end }}
{{- if .Values.receivers.otlp.http.enabled }}
  http {
    endpoint = "0.0.0.0:{{ .Values.receivers.otlp.http.port | int }}"
  }
{{- end }}
  debug_metrics {
    disable_high_cardinality_metrics = {{ not .Values.receivers.otlp.includeDebugMetrics }}
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
