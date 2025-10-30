{{- define "feature.prometheusOperatorObjects.scrapeConfigs.alloy" }}
{{- if .Values.scrapeConfigs.enabled }}
{{- $metricAllowList := .Values.scrapeConfigs.metricsTuning.includeMetrics }}
{{- $metricDenyList := .Values.scrapeConfigs.metricsTuning.excludeMetrics }}
// Prometheus Operator Probe objects
prometheus.operator.scrapeconfigs "scrapeConfigs" {
{{- if .Values.scrapeConfigs.namespaces }}
  namespaces = {{ .Values.scrapeConfigs.namespaces | toJson }}
{{- end }}
{{- if or .Values.scrapeConfigs.labelSelectors .Values.scrapeConfigs.labelExpressions }}
  selector {
  {{- if .Values.scrapeConfigs.labelSelectors }}
    match_labels = {
    {{- range $key, $value := .Values.scrapeConfigs.labelSelectors }}
      {{ $key | quote }} = {{ $value | quote }},
    {{- end }}
    }
  {{- end }}
  {{- range $expression := .Values.scrapeConfigs.labelExpressions }}
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
    default_scrape_interval = {{ .Values.scrapeConfigs.scrapeInterval | default .Values.global.scrapeInterval | quote }}
    default_scrape_timeout = {{ .Values.scrapeConfigs.scrapeTimeout | default .Values.global.scrapeTimeout | quote }}
  }

{{- with .Values.scrapeConfigs.excludeNamespaces }}
  rule {
    source_labels = ["job"]
    regex = "probe/({{ . | join "|" }})/.*"
    action = "drop"
  }
{{- end }}
{{- if .Values.scrapeConfigs.extraDiscoveryRules }}
{{ .Values.scrapeConfigs.extraDiscoveryRules | indent 2 }}
{{- end }}
{{- if or $metricAllowList $metricDenyList .Values.scrapeConfigs.extraMetricProcessingRules }}
  forward_to = [prometheus.relabel.scrapeConfigs.receiver]
}

prometheus.relabel "scrapeConfigs" {
  max_cache_size = {{ .Values.scrapeConfigs.maxCacheSize | default .Values.global.maxCacheSize | int }}
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
{{- if .Values.scrapeConfigs.extraMetricProcessingRules }}
{{ .Values.scrapeConfigs.extraMetricProcessingRules | indent 2 }}
{{- end }}
{{- end }}
  forward_to = argument.metrics_destinations.value
}
{{- end }}
{{- end }}
