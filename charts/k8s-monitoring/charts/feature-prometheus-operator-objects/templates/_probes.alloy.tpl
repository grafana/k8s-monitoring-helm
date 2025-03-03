{{- define "feature.prometheusOperatorObjects.probes.alloy" }}
{{- if .Values.probes.enabled }}
{{- $metricAllowList := .Values.probes.metricsTuning.includeMetrics }}
{{- $metricDenyList := .Values.probes.metricsTuning.excludeMetrics }}
// Prometheus Operator Probe objects
prometheus.operator.probes "pod_monitors" {
{{- if .Values.probes.namespaces }}
  namespaces = {{ .Values.probes.namespaces | toJson }}
{{- end }}
{{- if or .Values.probes.labelSelectors .Values.probes.labelExpressions }}
  selector {
  {{- if .Values.probes.labelSelectors }}
    match_labels = {
    {{- range $key, $value := .Values.probes.labelSelectors }}
      {{ $key | quote }} = {{ $value | quote }}
    {{- end }}
    }
  {{- end }}
  {{- range $expression := .Values.probes.labelExpressions }}
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
    default_scrape_interval = {{ .Values.probes.scrapeInterval | default .Values.global.scrapeInterval | quote }}
  }

{{- with .Values.probes.excludeNamespaces }}
  rule {
    source_labels = ["__meta_kubernetes_namespace"]
    regex = {{ . | join "|" | quote }}
    action = "drop"
  }
{{- end }}
{{- if .Values.probes.extraDiscoveryRules }}
{{ .Values.probes.extraDiscoveryRules | indent 2 }}
{{- end }}
{{- if or $metricAllowList $metricDenyList .Values.probes.extraMetricProcessingRules }}
  forward_to = [prometheus.relabel.probes.receiver]
}

prometheus.relabel "probes" {
  max_cache_size = {{ .Values.probes.maxCacheSize | default .Values.global.maxCacheSize | int }}
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
{{- if .Values.probes.extraMetricProcessingRules }}
{{ .Values.probes.extraMetricProcessingRules | indent 2 }}
{{- end }}
{{- end }}
  forward_to = argument.metrics_destinations.value
}
{{- end }}
{{- end }}
