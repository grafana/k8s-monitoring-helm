{{- define "feature.prometheusOperatorObjects.serviceMonitors.alloy" }}
{{- if .Values.serviceMonitors.enabled }}
{{- $metricAllowList := .Values.serviceMonitors.metricsTuning.includeMetrics }}
{{- $metricDenyList := .Values.serviceMonitors.metricsTuning.excludeMetrics }}
// Prometheus Operator ServiceMonitor objects
prometheus.operator.servicemonitors "service_monitors" {
{{- if .Values.serviceMonitors.namespaces }}
  namespaces = {{ .Values.serviceMonitors.namespaces | toJson }}
{{- end }}
{{- if or .Values.serviceMonitors.labelSelectors .Values.serviceMonitors.labelExpressions }}
  selector {
  {{- if .Values.serviceMonitors.labelSelectors }}
    match_labels = {
    {{- range $key, $value := .Values.serviceMonitors.labelSelectors }}
      {{ $key | quote }} = {{ $value | quote }},
    {{- end }}
    }
  {{- end }}
  {{- range $expression := .Values.serviceMonitors.labelExpressions }}
    match_expression {
      key = {{ $expression.key | quote }}
      operator = {{ $expression.operator | quote }}
      {{ if $expression.values }}values = {{ $expression.values | toJson }}{{ end }}
    }
  {{- end }}
  }
{{- end }}
  clustering {
    enabled = true
  }
  scrape {
    default_scrape_interval = {{ .Values.serviceMonitors.scrapeInterval | default .Values.global.scrapeInterval | quote }}
  }

{{- with .Values.serviceMonitors.excludeNamespaces }}
  rule {
    source_labels = ["__meta_kubernetes_namespace"]
    regex = {{ . | join "|" | quote }}
    action = "drop"
  }
{{- end }}
{{- if .Values.serviceMonitors.extraDiscoveryRules }}
{{ .Values.serviceMonitors.extraDiscoveryRules | indent 2 }}
{{- end }}
{{- if or $metricAllowList $metricDenyList .Values.serviceMonitors.extraMetricProcessingRules }}
  forward_to = [prometheus.relabel.servicemonitors.receiver]
}

prometheus.relabel "servicemonitors" {
  max_cache_size = {{ .Values.serviceMonitors.maxCacheSize | default .Values.global.maxCacheSize | int }}
{{- if $metricAllowList }}
  rule {
    source_labels = ["__name__"]
    regex = "up|scrape_samples_scraped|{{ $metricAllowList | join "|" }}"
    action = "keep"
  }
{{- end }}
{{- if $metricDenyList }}
  rule {
    source_labels = ["__name__"]
    regex = {{ $metricDenyList | join "|" | quote }}
    action = "drop"
  }
{{- end }}
{{- if .Values.serviceMonitors.extraMetricProcessingRules }}
{{ .Values.serviceMonitors.extraMetricProcessingRules | indent 2 }}
{{- end }}
{{- end }}
  forward_to = argument.metrics_destinations.value
}
{{- end }}
{{- end }}
