{{/* Inputs: Values (values) metricsOutput, name */}}
{{/* https://grafana.com/docs/alloy/latest/reference/components/otelcol/otelcol.connector.host_info/ */}}
{{- define "feature.applicationObservability.connector.host_info.alloy.target" }}otelcol.connector.host_info.{{ .name | default "default" }}.input{{- end }}
{{- define "feature.applicationObservability.connector.host_info.alloy" }}
otelcol.connector.host_info "{{ .name | default "default" }}" {
  host_identifiers = [ "k8s.node.name" ]

  output {
{{- if and .metrics .Values.metrics.enabled }}
    metrics = {{ .metrics }}
{{- end }}
  }
}
{{- end }}