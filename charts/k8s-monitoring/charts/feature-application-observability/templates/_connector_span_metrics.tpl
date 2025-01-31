{{/* Inputs: Values (values) metricsOutput, name */}}
{{/* https://grafana.com/docs/alloy/latest/reference/components/otelcol/otelcol.connector.spanmetrics/ */}}
{{- define "feature.applicationObservability.connector.spanmetrics.alloy.target" }}otelcol.connector.spanmetrics.{{ .name | default "default" }}.input{{- end }}
{{- define "feature.applicationObservability.connector.spanmetrics.alloy" }}
otelcol.connector.spanmetrics "{{ .name | default "default" }}" {
{{- range $dimension := .Values.connectors.spanMetrics.dimensions }}
  dimension {
    name = {{ $dimension.name | quote }}
{{- if $dimension.default }}
    default = {{ $dimension.default | quote }}
{{- end }}
  }
{{- end }}
  dimensions_cache_size = {{ .Values.connectors.spanMetrics.dimensionsCacheSize }}
  namespace = {{ .Values.connectors.spanMetrics.namespace | quote }}
{{- if .Values.connectors.spanMetrics.events.enabled }}
  events {
    enabled = true
  }
{{- end }}
{{ if .Values.connectors.spanMetrics.exemplars.enabled }}
  exemplars {
    enabled = true
{{- if .Values.connectors.spanMetrics.exemplars.maxPerDataPoint }}
    max_per_data_point = {{ .Values.connectors.spanMetrics.exemplars.maxPerDataPoint }}
{{- end }}
  }
{{- end }}
{{- if .Values.connectors.spanMetrics.histogram.enabled }}
  histogram {
    disable = false
    unit = {{ .Values.connectors.spanMetrics.histogram.unit | quote }}
{{- if eq .Values.connectors.spanMetrics.histogram.type "explicit" }}
    explicit {
      buckets = {{ .Values.connectors.spanMetrics.histogram.explicit.buckets | toJson }}
    }
{{- else if eq .Values.connectors.spanMetrics.histogram.type "exponential" }}
    exponential {
      max_size = {{ .Values.connectors.spanMetrics.histogram.exponential.maxSize }}
    }
{{- end }}
  }
{{- end }}

  output {
{{- if and .metrics .Values.metrics.enabled }}
    metrics = {{ .metrics }}
{{- end }}
  }
}
{{- end }}