{{- define "feature.prometheusOperatorObjects.podMonitors.alloy" }}
{{- if .Values.podMonitors.enabled }}
{{- $metricAllowList := .Values.podMonitors.metricsTuning.includeMetrics }}
{{- $metricDenyList := .Values.podMonitors.metricsTuning.excludeMetrics }}
// Prometheus Operator PodMonitor objects
prometheus.operator.podmonitors "pod_monitors" {
{{- if .Values.podMonitors.namespaces }}
  namespaces = {{ .Values.podMonitors.namespaces | toJson }}
{{- end }}
{{- if or .Values.podMonitors.labelSelectors .Values.podMonitors.labelExpressions }}
  selector {
  {{- if .Values.podMonitors.labelSelectors }}
    match_labels = {
    {{- range $key, $value := .Values.podMonitors.labelSelectors }}
      {{ $key | quote }} = {{ $value | quote }},
    {{- end }}
    }
  {{- end }}
  {{- range $expression := .Values.podMonitors.labelExpressions }}
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
    default_scrape_interval = {{ .Values.podMonitors.scrapeInterval | default .Values.global.scrapeInterval | quote }}
  }

{{- with .Values.podMonitors.excludeNamespaces }}
  rule {
    source_labels = ["__meta_kubernetes_namespace"]
    regex = {{ . | join "|" | quote }}
    action = "drop"
  }
{{- end }}
{{- if .Values.podMonitors.extraDiscoveryRules }}
{{ .Values.podMonitors.extraDiscoveryRules | indent 2 }}
{{- end }}
{{- if or $metricAllowList $metricDenyList .Values.podMonitors.extraMetricProcessingRules }}
  forward_to = [prometheus.relabel.podmonitors.receiver]
}

prometheus.relabel "podmonitors" {
  max_cache_size = {{ .Values.podMonitors.maxCacheSize | default .Values.global.maxCacheSize | int }}
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
{{- if .Values.podMonitors.extraMetricProcessingRules }}
{{ .Values.podMonitors.extraMetricProcessingRules | indent 2 }}
{{- end }}
{{- end }}
  forward_to = argument.metrics_destinations.value
}
{{- end }}
{{- end }}
