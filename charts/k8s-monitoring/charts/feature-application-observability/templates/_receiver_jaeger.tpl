{{/* Inputs: Values (values) tracesOutput */}}
{{- define "feature.applicationObservability.receiver.jaeger.alloy" }}
otelcol.receiver.jaeger "receiver" {
  protocols {
{{- if .Values.receivers.jaeger.grpc.enabled }}
    grpc {
      endpoint = "0.0.0.0:{{ .Values.receivers.jaeger.grpc.port | int }}"
    }
{{- end }}
{{- if .Values.receivers.jaeger.thriftBinary.enabled }}
    thrift_binary {
      endpoint = "0.0.0.0:{{ .Values.receivers.jaeger.thriftBinary.port | int }}"
    }
{{- end }}
{{- if .Values.receivers.jaeger.thriftCompact.enabled }}
    thrift_compact {
      endpoint = "0.0.0.0:{{ .Values.receivers.jaeger.thriftCompact.port | int }}"
    }
{{- end }}
{{- if .Values.receivers.jaeger.thriftHttp.enabled }}
    thrift_http {
      endpoint = "0.0.0.0:{{ .Values.receivers.jaeger.thriftHttp.port | int }}"
    }
{{- end }}
  }

  debug_metrics {
    disable_high_cardinality_metrics = {{ not .Values.receivers.jaeger.includeDebugMetrics }}
  }
  output {
{{- if and .traces .Values.traces.enabled }}
    traces = {{ .traces }}
{{- end }}
  }
}
{{- end }}
