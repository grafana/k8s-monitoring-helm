{{- define "sampler.receiver.otlp.alloy" }}
{{ $traces := . }}
otelcol.receiver.otlp "receiver" {
  grpc {
    max_recv_msg_size = "4MB"  # TODO this could be configurable"
  }

  output {
    traces = {{ $traces | toJson }}
  }
}
{{- end }}
