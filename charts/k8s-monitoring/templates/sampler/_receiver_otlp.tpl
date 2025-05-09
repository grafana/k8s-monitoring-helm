{{- define "sampler.receiver.otlp.alloy" }}
otelcol.receiver.otlp {{ .name | default "default" | quote }} {
  grpc {
    max_recv_msg_size = "4MB"
  }

  output {
    traces = [{{ .traces }}]
  }
}
{{ end }}
