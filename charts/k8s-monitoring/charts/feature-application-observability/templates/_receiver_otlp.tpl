{{/* Inputs: Values (values) metricsOutput, logsOutput, tracesOutput */}}
{{- define "feature.applicationObservability.receiver.otlp.alloy" }}
otelcol.receiver.otlp "receiver" {
{{- if .Values.receivers.otlp.grpc.enabled }}
  grpc {
    endpoint = "0.0.0.0:{{ .Values.receivers.otlp.grpc.port | int }}"
    include_metadata = {{ .Values.receivers.otlp.grpc.includeMetadata }}
    max_recv_msg_size = {{ .Values.receivers.otlp.grpc.maxReceivedMessageSize | quote }}
{{- if ne (int .Values.receivers.otlp.grpc.maxConcurrentStreams) 0 }}
    max_concurrent_streams = {{ .Values.receivers.otlp.grpc.maxConcurrentStreams }}
{{- end }}
    read_buffer_size = {{ .Values.receivers.otlp.grpc.readBufferSize | quote }}
    write_buffer_size = {{ .Values.receivers.otlp.grpc.writeBufferSize | quote }}

    server_parameters {
      {{- if .Values.receivers.otlp.grpc.serverParameters.maxConnectionAge }}
      max_connection_age = {{ .Values.receivers.otlp.grpc.serverParameters.maxConnectionAge | quote }}
      {{- end }}
      {{- if .Values.receivers.otlp.grpc.serverParameters.maxConnectionAgeGrace }}
      max_connection_age_grace = {{ .Values.receivers.otlp.grpc.serverParameters.maxConnectionAgeGrace | quote }}
      {{- end }}
      {{- if .Values.receivers.otlp.grpc.serverParameters.maxConnectionIdle }}
      max_connection_idle = {{ .Values.receivers.otlp.grpc.serverParameters.maxConnectionIdle | quote }}
      {{- end }}
      time = {{ .Values.receivers.otlp.grpc.serverParameters.time | quote }}
      timeout = {{ .Values.receivers.otlp.grpc.serverParameters.timeout | quote }}
    }

    enforcement_policy {
      min_time = {{ .Values.receivers.otlp.grpc.enforcementPolicy.minTime | quote }}
      permit_without_stream = {{ .Values.receivers.otlp.grpc.enforcementPolicy.permitWithoutStream }}
    }
  }
{{- end }}
{{- if .Values.receivers.otlp.http.enabled }}
  http {
    endpoint = "0.0.0.0:{{ .Values.receivers.otlp.http.port | int }}"
    include_metadata = {{ .Values.receivers.otlp.http.includeMetadata }}
    max_request_body_size = {{ .Values.receivers.otlp.http.maxRequestBodySize | quote }}
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
