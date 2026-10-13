{{- define "feature.prometheusOperatorObjects.probes.alloy" }}
{{- if .Values.probes.enabled }}
{{- $metricAllowList := .Values.probes.metricsTuning.includeMetrics }}
{{- $metricDenyList := .Values.probes.metricsTuning.excludeMetrics }}
{{- $namespacesHaveRegex := "" }}
{{- if .Values.probes.namespaces }}
  {{- $namespacesHaveRegex = include "feature.prometheusOperatorObjects.namespaces.hasRegex" .Values.probes.namespaces }}
{{- end }}
// Prometheus Operator Probe objects
prometheus.operator.probes "probes" {
{{- if and .Values.probes.namespaces (ne $namespacesHaveRegex "true") }}
  namespaces = {{ .Values.probes.namespaces | toJson }}
{{- end }}
{{- if or .Values.probes.labelSelectors .Values.probes.labelExpressions }}
  selector {
  {{- if .Values.probes.labelSelectors }}
    match_labels = {
    {{- range $key, $value := .Values.probes.labelSelectors }}
      {{ $key | quote }} = {{ $value | quote }},
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
    default_scrape_timeout = {{ .Values.probes.scrapeTimeout | default .Values.global.scrapeTimeout | quote }}
    scrape_classic_histograms = {{ .Values.global.scrapeClassicHistograms }}
    scrape_native_histograms = {{ .Values.global.scrapeNativeHistograms }}
    convert_classic_histograms_to_nhcb = {{ .Values.global.convertClassicHistogramsToNhcb }}
    native_histogram_bucket_limit = {{ .Values.global.nativeHistogramBucketLimit | int }}
    native_histogram_min_bucket_factor = {{ .Values.global.nativeHistogramMinBucketFactor | float64 }}
  }

{{- if eq $namespacesHaveRegex "true" }}
  rule {  // namespaces contains a regex, so Probes cannot be pre-filtered by the component; keep only matching namespaces here
    source_labels = ["job"]
    regex = "probe/({{ .Values.probes.namespaces | join "|" }})/.*"
    action = "keep"
  }
{{- end }}
{{- with .Values.probes.excludeNamespaces }}
  rule {
    source_labels = ["job"]
    regex = "probe/({{ . | join "|" }})/.*"
    action = "drop"
  }
{{- end }}
{{- if .Values.probes.extraDiscoveryRules }}
{{ .Values.probes.extraDiscoveryRules | indent 2 }}
{{- end }}
{{- if or $metricAllowList $metricDenyList .Values.probes.extraMetricProcessingRules }}
  forward_to = [prometheus.relabel.probes.receiver]
} // prometheus.operator.probes "probes"

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
  forward_to = argument.metrics_destinations.value
} // prometheus.relabel "probes"
{{- else }}
  forward_to = argument.metrics_destinations.value
} // prometheus.operator.probes "probes"
{{- end }}
{{- end }}
{{- end }}
