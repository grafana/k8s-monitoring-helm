{{- define "feature.lokiLogsReceiver.module" }}
declare "loki_logs_receiver" {
  argument "logs_destinations" {
    comment = "Must be a list of log destinations where received logs should be forwarded to"
  }

  loki.source.api "default" {
    http {
      listen_address = "0.0.0.0"
      listen_port = {{ .Values.port }}
    }
    use_incoming_timestamp = {{ .Values.useIncomingTimestamp }}
{{- if .Values.labels }}
    labels = {
{{- range $key, $value := .Values.labels }}
      {{ $key }} = {{ $value | quote }},
{{- end }}
    }
{{- end }}
{{ if .Values.logProcessingRules }}
    forward_to = [loki.relabel.default.receiver]
  } // loki.source.api "default"

  loki.relabel "default" {
{{ .Values.logProcessingRules | indent 4 }}
    forward_to = argument.logs_destinations.value
  } // loki.relabel "default"
{{- else }}
    forward_to = argument.logs_destinations.value
  } // loki.source.api "default"
{{- end }}
} // declare "loki_logs_receiver"
{{- end }}
