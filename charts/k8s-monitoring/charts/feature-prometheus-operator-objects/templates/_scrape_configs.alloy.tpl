{{- define "feature.prometheusOperatorObjects.scrapeConfigs.alloy" }}
{{- if .Values.scrapeConfigs.enabled }}
{{- $metricAllowList := .Values.scrapeConfigs.metricsTuning.includeMetrics }}
{{- $metricDenyList := .Values.scrapeConfigs.metricsTuning.excludeMetrics }}
{{- $namespacesHaveRegex := "" }}
{{- if .Values.scrapeConfigs.namespaces }}
  {{- $namespacesHaveRegex = include "feature.prometheusOperatorObjects.namespaces.hasRegex" .Values.scrapeConfigs.namespaces }}
{{- end }}
// Prometheus Operator ScrapeConfig objects
prometheus.operator.scrapeconfigs "scrapeConfigs" {
{{- if and .Values.scrapeConfigs.namespaces (ne $namespacesHaveRegex "true") }}
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
    scrape_native_histograms = {{ .Values.global.scrapeNativeHistograms }}
  }

{{- if or (eq $namespacesHaveRegex "true") .Values.scrapeConfigs.excludeNamespaces }}
  rule {  // extract the namespace from the job label (scrapeConfig/<namespace>/<name>/...) so the regexes below are matched against the namespace alone, and can't accidentally span into the name
    source_labels = ["job"]
    regex = "scrapeConfig/([^/]+)/.*"
    target_label = "__tmp_namespace"
  }
{{- end }}
{{- if eq $namespacesHaveRegex "true" }}
  rule {  // namespaces contains a regex, so ScrapeConfigs cannot be pre-filtered by the component; keep only matching namespaces here
    source_labels = ["__tmp_namespace"]
    regex = {{ .Values.scrapeConfigs.namespaces | join "|" | quote }}
    action = "keep"
  }
{{- end }}
{{- with .Values.scrapeConfigs.excludeNamespaces }}
  rule {
    source_labels = ["__tmp_namespace"]
    regex = {{ . | join "|" | quote }}
    action = "drop"
  }
{{- end }}
{{- if .Values.scrapeConfigs.extraDiscoveryRules }}
{{ .Values.scrapeConfigs.extraDiscoveryRules | indent 2 }}
{{- end }}
{{- if or $metricAllowList $metricDenyList .Values.scrapeConfigs.extraMetricProcessingRules }}
  forward_to = [prometheus.relabel.scrapeConfigs.receiver]
} // prometheus.operator.scrapeconfigs "scrapeConfigs"

prometheus.relabel "scrapeConfigs" {
  {{- include "helper.relabelCacheArguments" (dict "maxCacheSize" .Values.scrapeConfigs.maxCacheSize "cacheTTL" .Values.scrapeConfigs.cacheTTL "global" .Values.global) | nindent 2 }}
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
  forward_to = argument.metrics_destinations.value
} // prometheus.relabel "scrapeConfigs"
{{- else }}
  forward_to = argument.metrics_destinations.value
} // prometheus.operator.scrapeconfigs "scrapeConfigs"
{{- end }}
{{- end }}
{{- end }}
