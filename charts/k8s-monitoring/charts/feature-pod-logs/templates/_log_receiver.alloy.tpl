{{- define "feature.podLogs.logReceiver.alloy" }}
loki.source.api "logs_receiver" {
  http {
    listen_address = "0.0.0.0"
    listen_port = 3100
  }

  forward_to = [loki.process.pod_logs.receiver]
}
{{- end }}
