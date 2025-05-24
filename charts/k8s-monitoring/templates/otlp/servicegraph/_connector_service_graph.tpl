{{- define "servicegraph.connector.serviceGraphMetrics.alloy.target" }}otelcol.connector.servicegraph.{{ .name | default "default" }}.input{{ end }}
{{- define "servicegraph.connector.serviceGraphMetrics.alloy" }}
otelcol.connector.servicegraph {{ .name | default "default" | quote }} {
  // https://grafana.com/docs/alloy/latest/reference/components/otelcol/otelcol.connector.servicegraph/

  // TODO configs

  output {
      metrics = [
      {{- range $target := .metrics }}
        {{ $target }},
      {{- end }}
      ] 
  }
}
{{ end }}
