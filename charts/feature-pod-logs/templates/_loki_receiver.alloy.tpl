{{- define "feature.podLogs.lokiReceiver" }}
loki.source.api "receiver" {
  http {
    listen_address = "0.0.0.0"
    listen_port = {{ .Values.receiver.port | int }}
  }
  forward_to = [loki.process.pod_logs.receiver]
}

{{- end }}
