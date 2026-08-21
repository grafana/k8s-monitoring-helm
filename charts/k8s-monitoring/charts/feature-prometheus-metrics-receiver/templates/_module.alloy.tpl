{{- define "feature.prometheusMetricsReceiver.module" }}
declare "prometheus_metrics_receiver" {
  argument "metrics_destinations" {
    comment = "Must be a list of metric destinations where collected metrics should be forwarded to"
  }

  prometheus.receive_http "default" {
    http {
      listen_address = "0.0.0.0"
      listen_port = {{ .Values.port | quote }}
    }
{{ if .Values.metricProcessingRules }}
    forward_to = [prometheus.relabel.default.receiver]
  } // prometheus.receive_http "default"

  prometheus.relabel "default" {
{{ .Values.metricProcessingRules | indent 4 }}
    forward_to = argument.metrics_destinations.value
  } // prometheus.relabel "default"
{{- else }}
    forward_to = argument.metrics_destinations.value
  } // prometheus.receive_http "default"
{{- end }}
} // declare "prometheus_metrics_receiver"
{{- end }}
