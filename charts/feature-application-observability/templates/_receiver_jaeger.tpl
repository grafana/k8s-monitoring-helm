{{/* Inputs: Values (values) tracesOutput */}}
{{- define "feature.applicationObservability.receiver.jaeger.alloy" }}
{{- if or .Values.receivers.jaeger.grpc.enabled .Values.receivers.jaeger.thriftBinary.enabled .Values.receivers.jaeger.thriftCompact.enabled .Values.receivers.jaeger.thriftBinary.enabled }}
otelcol.receiver.jaeger "receiver" {
  protocols {
{{- if .Values.receivers.jaeger.grpc.enabled -}}
    grpc {
      endpoint = "0.0.0.0:{{ .Values.receivers.jaeger.grpc | int }}"
    }
{{- end }}
{{- if .Values.receivers.jaeger.thriftBinary.enabled }}
    thrift_binary {
      endpoint = "0.0.0.0:{{ .Values.receivers.jaeger.thriftBinary | int }}"
    }
{{- end }}
{{- if .Values.receivers.jaeger.thriftCompact.enabled }}
    thrift_compact {
      endpoint = "0.0.0.0:{{ .Values.receivers.jaeger.thriftCompact | int }}"
    }
{{- end }}
{{- if .Values.receivers.jaeger.thriftHttp.enabled }}
    thrift_http {
      endpoint = "0.0.0.0:{{ .Values.receivers.jaeger.thriftHttp | int }}"
    }
{{- end }}
  }

  debug_metrics {
    disable_high_cardinality_metrics = {{ not .Values.receivers.jaeger.include_debug_metrics }}
  }
  output {
{{- if and .tracesOutput .Values.traces.enabled }}
    traces = {{ .tracesOutput }}
{{- end }}
  }
}
{{- end }}
{{- end }}
