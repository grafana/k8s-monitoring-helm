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

    {{- $hasServerParameters := and .Values.receivers.otlp.grpc.keepalive.serverParameters (or .Values.receivers.otlp.grpc.keepalive.serverParameters.maxConnectionAge .Values.receivers.otlp.grpc.keepalive.serverParameters.maxConnectionAgeGrace .Values.receivers.otlp.grpc.keepalive.serverParameters.maxConnectionIdle) }}
    {{- $hasEnforcementPolicy := and .Values.receivers.otlp.grpc.keepalive.enforcementPolicy (or .Values.receivers.otlp.grpc.keepalive.enforcementPolicy.minTime .Values.receivers.otlp.grpc.keepalive.enforcementPolicy.permitWithoutStream) }}
    {{- if or $hasServerParameters $hasEnforcementPolicy }}
    keepalive {
      {{- if $hasServerParameters }}
      server_parameters {
        {{- if .Values.receivers.otlp.grpc.keepalive.serverParameters.maxConnectionAge }}
        max_connection_age = {{ .Values.receivers.otlp.grpc.keepalive.serverParameters.maxConnectionAge | quote }}
        {{- end }}
        {{- if .Values.receivers.otlp.grpc.keepalive.serverParameters.maxConnectionAgeGrace }}
        max_connection_age_grace = {{ .Values.receivers.otlp.grpc.keepalive.serverParameters.maxConnectionAgeGrace | quote }}
        {{- end }}
        {{- if .Values.receivers.otlp.grpc.keepalive.serverParameters.maxConnectionIdle }}
        max_connection_idle = {{ .Values.receivers.otlp.grpc.keepalive.serverParameters.maxConnectionIdle | quote }}
        {{- end }}
        {{- if .Values.receivers.otlp.grpc.keepalive.serverParameters.time }}
        time = {{ .Values.receivers.otlp.grpc.keepalive.serverParameters.time | quote }}
        {{- end }}
        {{- if .Values.receivers.otlp.grpc.keepalive.serverParameters.timeout }}
        timeout = {{ .Values.receivers.otlp.grpc.keepalive.serverParameters.timeout | quote }}
        {{- end }}
      }
      {{- end }}
      {{- if $hasEnforcementPolicy }}
      enforcement_policy {
        {{- if .Values.receivers.otlp.grpc.keepalive.enforcementPolicy.maxConnectionAge }}
        min_time = {{ .Values.receivers.otlp.grpc.keepalive.enforcementPolicy.minTime | quote }}
        {{- end }}
        {{- if .Values.receivers.otlp.grpc.keepalive.enforcementPolicy.permitWithoutStream }}
        permit_without_stream = {{ .Values.receivers.otlp.grpc.keepalive.enforcementPolicy.permitWithoutStream }}
        {{- end }}
      }
      {{- end }}
    }
    {{- end }}
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
