{{- define "feature.prometheusOperatorObjects.podMonitors.alloy" }}
{{- if .Values.podMonitors.enabled }}
{{- $metricAllowList := .Values.podMonitors.metricsTuning.includeMetrics }}
{{- $metricDenyList := .Values.podMonitors.metricsTuning.excludeMetrics }}
{{- $namespacesHaveRegex := "" }}
{{- if .Values.podMonitors.namespaces }}
  {{- $namespacesHaveRegex = include "feature.prometheusOperatorObjects.namespaces.hasRegex" .Values.podMonitors.namespaces }}
{{- end }}
// Prometheus Operator PodMonitor objects
prometheus.operator.podmonitors "pod_monitors" {
{{- if and .Values.podMonitors.namespaces (ne $namespacesHaveRegex "true") }}
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
    default_scrape_timeout = {{ .Values.podMonitors.scrapeTimeout | default .Values.global.scrapeTimeout | quote }}
    scrape_classic_histograms = {{ .Values.global.scrapeClassicHistograms }}
    scrape_native_histograms = {{ .Values.global.scrapeNativeHistograms }}
    convert_classic_histograms_to_nhcb = {{ .Values.global.convertClassicHistogramsToNhcb }}
    native_histogram_bucket_limit = {{ .Values.global.nativeHistogramBucketLimit | int }}
    native_histogram_min_bucket_factor = {{ .Values.global.nativeHistogramMinBucketFactor | float64 }}
  }

{{- if or (eq $namespacesHaveRegex "true") .Values.podMonitors.excludeNamespaces }}
  rule {  // extract the namespace from the job label (podMonitor/<namespace>/<name>/<index>) so the regexes below are matched against the namespace alone, and can't accidentally span into the name
    source_labels = ["job"]
    regex = "podMonitor/([^/]+)/.*"
    target_label = "__tmp_namespace"
  }
{{- end }}
{{- if eq $namespacesHaveRegex "true" }}
  rule {  // namespaces contains a regex, so PodMonitors cannot be pre-filtered by the component; keep only matching namespaces here
    source_labels = ["__tmp_namespace"]
    regex = {{ .Values.podMonitors.namespaces | join "|" | quote }}
    action = "keep"
  }
{{- end }}
{{- with .Values.podMonitors.excludeNamespaces }}
  rule {
    source_labels = ["__tmp_namespace"]
    regex = {{ . | join "|" | quote }}
    action = "drop"
  }
{{- end }}
{{- if .Values.podMonitors.extraDiscoveryRules }}
{{ .Values.podMonitors.extraDiscoveryRules | indent 2 }}
{{- end }}
{{- if or $metricAllowList $metricDenyList .Values.podMonitors.extraMetricProcessingRules }}
  forward_to = [prometheus.relabel.podmonitors.receiver]
} // prometheus.operator.podmonitors "pod_monitors"

prometheus.relabel "podmonitors" {
  {{- include "helper.relabelCacheArguments" (dict "maxCacheSize" .Values.podMonitors.maxCacheSize "cacheTTL" .Values.podMonitors.cacheTTL "global" .Values.global) | nindent 2 }}
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
  forward_to = argument.metrics_destinations.value
} // prometheus.relabel "podmonitors"
{{- else }}
  forward_to = argument.metrics_destinations.value
} // prometheus.operator.podmonitors "pod_monitors"
{{- end }}
{{- end }}
{{- end }}
