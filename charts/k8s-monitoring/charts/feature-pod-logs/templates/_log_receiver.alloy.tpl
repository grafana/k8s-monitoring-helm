{{- define "feature.podLogs.lokiReceiver.alloy" }}
loki.source.api "loki_receiver" {
  http {
    listen_address = "0.0.0.0"
    listen_port = {{ .Values.lokiReceiver.port }}
  }

  forward_to = [loki.process.pod_log_processor.receiver]
}
{{- end }}
