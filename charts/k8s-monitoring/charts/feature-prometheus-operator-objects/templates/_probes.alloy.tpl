{{- define "feature.prometheusOperatorObjects.probes.alloy" }}
{{- if .Values.probes.enabled }}
{{- $metricAllowList := .Values.probes.metricsTuning.includeMetrics }}
{{- $metricDenyList := .Values.probes.metricsTuning.excludeMetrics }}
// Prometheus Operator Probe objects
prometheus.operator.probes "pod_monitors" {
{{- if .Values.probes.namespaces }}
  namespaces = {{ .Values.probes.namespaces | toJson }}
{{- end }}
{{- if .Values.probes.selector }}
  selector {
{{ .Values.probes.selector | indent 4 }}
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
