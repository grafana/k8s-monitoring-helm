{{/* Inputs: Values (values) metricsOutput, logsOutput, tracesOutput */}}
{{- define "feature.applicationObservability.receiver.otlp.alloy" }}
{{- if or .Values.receivers.otlp.grpc.enabled .Values.receivers.otlp.http.enabled }}
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
