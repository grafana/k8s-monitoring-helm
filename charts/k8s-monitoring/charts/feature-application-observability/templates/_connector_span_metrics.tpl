{{/* Inputs: Values (values) metricsOutput, name */}}
{{/* https://grafana.com/docs/alloy/latest/reference/components/otelcol/otelcol.connector.spanmetrics/ */}}
{{- define "feature.applicationObservability.connector.spanmetrics.alloy.target" }}otelcol.processor.filter.span_metrics_prefilter.input{{- end }}
{{- define "feature.applicationObservability.connector.spanmetrics.alloy" }}
otelcol.processor.filter "span_metrics_prefilter" {
  error_mode = "silent"
{{- if .Values.connectors.spanMetrics.skipBeyla }}
  traces {
    span = [
      `resource.attributes["span.metrics.skip"] != nil`,
    ]
  }
{{- end }}
  output {
    traces = [otelcol.connector.spanmetrics.{{ .name | default "default" }}.input]
  }
}

otelcol.connector.spanmetrics "{{ .name | default "default" }}" {
{{- range $dimension := .Values.connectors.spanMetrics.dimensions }}
  dimension {
    name = {{ $dimension.name | quote }}
{{- if $dimension.default }}
    default = {{ $dimension.default | quote }}
{{- end }}
  }
{{- end }}
  exclude_dimensions = {{ .Values.connectors.spanMetrics.excludeDimensions }}
  dimensions_cache_size = {{ .Values.connectors.spanMetrics.dimensionsCacheSize }}
  aggregation_cardinality_limit = {{ .Values.connectors.spanMetrics.aggregationCardinalityLimit }}
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
    metrics = [otelcol.processor.transform.span_metrics_transform.input]
  }
}

otelcol.processor.transform "span_metrics_transform" {
   metric_statements {
    context = "datapoint"
    statements = [
      `set(attributes["collector.id"], "` + constants.hostname + `")`,
    ]
  }

  output {
{{- if and .metrics .Values.metrics.enabled }}
    metrics = {{ .metrics }}
{{- end }}
  }
}
{{- end }}
