{{/* Inputs: Values (values) metricsOutput, logsOutput, tracesOutput */}}
{{- define "feature.applicationObservability.receiver.otlp.alloy" }}
{{- if or .Values.receivers.grpc.enabled .Values.receivers.http.enabled }}
otelcol.receiver.otlp "receiver" {
{{- if .Values.receivers.grpc.enabled }}
  grpc {
    endpoint = "0.0.0.0:{{ .Values.receivers.grpc.port | int }}"
  }
{{- end }}
{{- if .Values.receivers.http.enabled }}
  http {
    endpoint = "0.0.0.0:{{ .Values.receivers.http.port | int }}"
  }
{{- end }}
  debug_metrics {
    disable_high_cardinality_metrics = {{ not (or .Values.receivers.grpc.include_debug_metrics .Values.receivers.http.include_debug_metrics) }}
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
{{- end }}
