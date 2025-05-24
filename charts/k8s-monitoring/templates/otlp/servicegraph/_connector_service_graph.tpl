{{- define "servicegraph.connector.serviceGraphMetrics.alloy.target" }}otelcol.connector.servicegraph.{{ .name | default "default" }}.input{{ end }}
{{- define "servicegraph.connector.serviceGraphMetrics.alloy" }}
otelcol.connector.servicegraph {{ .name | default "default" | quote }} {
  // https://grafana.com/docs/alloy/latest/reference/components/otelcol/otelcol.connector.servicegraph/

  cache_loop = {{ .cacheLoop | quote }}

  database_name_attribute = {{ .databaseNameAttribute | quote }}

  dimensions = [
    {{- range $dimension := .dimensions }}
      {{ $dimension | quote }},
    {{- end }}
  ]

  latency_histogram_buckets = [
    {{- range $bucket := .latencyHistogramBuckets }}
      {{ $bucket | quote }},
    {{- end }}
  ]

  metrics_flush_interval = {{ .metricsFlushInterval | quote }}

  store_expiration_loop = {{ .storeExpirationLoop | quote }}

  output {
      metrics = [
      {{- range $target := .metrics }}
        {{ $target }},
      {{- end }}
      ]
  }
}
{{ end }}
