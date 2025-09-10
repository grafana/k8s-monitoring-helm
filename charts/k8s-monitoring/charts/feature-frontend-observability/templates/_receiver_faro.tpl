{{/* Inputs: Values (values) logsOutput, tracesOutput */}}
{{- define "feature.frontendObservability.receiver.faro.alloy" }}
otelcol.receiver.faro "receiver" {
  endpoint = "0.0.0.0:{{ .Values.receivers.faro.port }}"
  include_metadata = {{ .Values.receivers.faro.includeMetadata }}
  cors {
{{- if .Values.receivers.faro.cors.allowedOrigins }}
    allowed_origins = [
{{- range .Values.receivers.faro.cors.allowedOrigins }}
      {{ . | quote }},
{{- end }}
    ]
{{- end }}
{{- if .Values.receivers.faro.cors.allowedHeaders }}
    allowed_headers = [
{{- range .Values.receivers.faro.cors.allowedHeaders }}
      {{ . | quote }},
{{- end }}
    ]
{{- end }}
{{- if .Values.receivers.faro.cors.maxAge }}
    max_age = {{ .Values.receivers.faro.cors.maxAge }}
{{- end}}
  }
  output {
{{- if .logs }}
    logs = {{ .logs }}
{{- end }}
{{- if .traces }}
    traces = {{ .traces }}
{{- end }}
  }
}
{{- end }}
