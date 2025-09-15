{{/* https://grafana.com/docs/alloy/latest/reference/components/otelcol/otelcol.connector.spanmetrics/ */}}
{{/* Inputs: Values (values) metricsOutput, name */}}
{{- define "feature.applicationObservability.connector.spanmetrics.alloy.target" }}otelcol.processor.filter.span_metrics_prefilter.input{{- end }}
{{- define "feature.applicationObservability.connector.spanmetrics.alloy" }}
otelcol.processor.filter "span_metrics_prefilter" {
  error_mode = "silent"
{{- $spanFilters := list }}
{{- if .Values.connectors.spanMetrics.skipBeyla }}
{{- $spanFilters = append $spanFilters "`resource.attributes[\"span.metrics.skip\"] != nil or attributes[\"span.metrics.skip\"] != nil`" }}
{{- end }}
{{- if .Values.connectors.spanMetrics.skipInternal }}
{{- $spanFilters = append $spanFilters "`kind == 1`" }}
{{- end }}
{{- if gt (len $spanFilters) 0 }}
  traces {
    span = [
{{- range $spanFilters }}
{{ . | indent 6 }},
{{- end }}
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
{{- if .Values.connectors.spanMetrics.transforms.resource }}
   metric_statements {
    context = "resource"
    statements = [
{{- range $transform := .Values.connectors.spanMetrics.transforms.resource }}
{{ $transform | quote | indent 6 }},
{{- end }}
    ]
  }
{{- end }}
{{- if .Values.connectors.spanMetrics.transforms.metric }}
   metric_statements {
    context = "metric"
    statements = [
{{- range $transform := .Values.connectors.spanMetrics.transforms.metric }}
{{ $transform | quote | indent 6 }},
{{- end }}
    ]
  }
{{- end }}
   metric_statements {
    context = "datapoint"
    statements = [
      `set(attributes["collector.id"], "` + constants.hostname + `")`,
      `set(resource.attributes["service.instance.id"], resource.attributes["k8s.pod.name"]) where resource.attributes["service.instance.id"] == nil and resource.attributes["k8s.pod.name"] != nil`,
      `set(resource.attributes["service.instance.id"], resource.attributes["k8s.pod.uid"]) where resource.attributes["service.instance.id"] == nil and resource.attributes["k8s.pod.uid"] != nil`,
{{- if .Values.connectors.spanMetrics.transforms.datapoint }}
{{- range $transform := .Values.connectors.spanMetrics.transforms.datapoint }}
{{ $transform | quote | indent 6 }},
{{- end }}
{{- end }}
    ]
  }

  output {
{{- if and .metrics .Values.metrics.enabled }}
    metrics = {{ .metrics }}
{{- end }}
  }
}
{{- end }}
