{{/* Inputs: Values (values) metricsOutput, name */}}
{{/* https://grafana.com/docs/alloy/latest/reference/components/otelcol/otelcol.connector.servicegraph/ */}}
{{- define "feature.applicationObservability.connector.serviceGraphs.alloy.target" }}otelcol.connector.servicegraph.{{ .name | default "default" }}.input{{- end }}
{{- define "feature.applicationObservability.connector.serviceGraphs.alloy" }}
otelcol.connector.servicegraph "{{ .name | default "default" }}" {
{{- range $dimension := .Values.connectors.serviceGraphs.dimensions }}
  dimension {
    name = {{ $dimension.name | quote }}
{{- if $dimension.default }}
    default = {{ $dimension.default | quote }}
{{- end }}
  }
{{- end }}
  cache_loop = {{ .Values.connectors.serviceGraphs.cacheLoop | quote }}
  store_expiration_loop = {{ .Values.connectors.serviceGraphs.storeExpirationLoop | quote }}
  metrics_flush_interval = {{ .Values.connectors.serviceGraphs.metricsFlushInterval | quote }}
  database_name_attribute = {{ .Values.connectors.serviceGraphs.databaseNameAttribute | quote }}
  latency_histogram_buckets = {{ .Values.connectors.serviceGraphs.histogramBuckets | toJson }}

  store {
    max_items = {{ .Values.connectors.serviceGraphs.store.maxItems }}
    ttl = {{ .Values.connectors.serviceGraphs.store.ttl | quote }}
  }

    output {
{{- if and .metrics .Values.metrics.enabled }}
      metrics = {{ .metrics }}
{{- end }}
    }
}
{{- end }}
