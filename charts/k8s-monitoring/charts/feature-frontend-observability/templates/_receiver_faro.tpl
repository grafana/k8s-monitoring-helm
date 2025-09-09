{{/* Inputs: Values (values) logsOutput, tracesOutput */}}
{{- define "feature.frontendObservability.receiver.faro.alloy" }}
otelcol.receiver.faro "receiver" {
  endpoint = "0.0.0.0:{{ .Values.receivers.faro.port }}"
  include_metadata = {{ .Values.receivers.faro.includeMetadata }}
  cors {
{{- if .Values.cors.allowedOrigins }}
    allowed_origins = [
{{- range .Values.cors.allowedOrigins }}
      {{ . | quote }},
{{- end }}
    ]
{{- end }}
{{- if .Values.cors.allowedHeaders }}
    allowed_headers = [
{{- range .Values.cors.allowedHeaders }}
      {{ . | quote }},
{{- end }}
    ]
{{- end }}
{{- if .Values.cors.maxAge }}
    max_age = {{ .Values.cors.maxAge }}
{{- end}}
  }
  output {
    logs = {{ .logs }}
    traces = {{ .traces }}
  }
}
{{- end }}
