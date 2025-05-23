{{- define "sampler.receiver.otlp.alloy" }}
otelcol.receiver.otlp {{ .name | default "default" | quote }} {
  grpc {
    max_recv_msg_size = {{  .receiver.otlp.grpc.maxReceivedMessageSize | quote }}
  }

  output {
    traces = [{{ .traces }}]
  }
}
{{ end }}
