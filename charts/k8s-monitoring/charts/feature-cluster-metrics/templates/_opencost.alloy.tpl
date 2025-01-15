{{ define "feature.clusterMetrics.opencost.allowList" }}
{{- $allowList := list }}
{{ if .Values.opencost.metricsTuning.useDefaultAllowList }}
{{- $allowList = concat $allowList (list "up" "scrape_samples_scraped") (.Files.Get "default-allow-lists/opencost.yaml" | fromYamlArray) -}}
{{ end }}
{{ if .Values.opencost.metricsTuning.includeMetrics }}
{{- $allowList = concat $allowList (list "up" "scrape_samples_scraped") .Values.opencost.metricsTuning.includeMetrics -}}
{{ end }}
{{ $allowList | uniq | toYaml }}
{{ end }}

{{- define "feature.clusterMetrics.opencost.alloy" }}
{{- if .Values.opencost.enabled }}
{{- $metricAllowList := include "feature.clusterMetrics.opencost.allowList" . | fromYamlArray }}
{{- $metricDenyList := .Values.opencost.metricsTuning.excludeMetrics }}
{{- $labelSelectors := list }}
{{- range $k, $v := .Values.opencost.labelMatchers }}
{{- $labelSelectors = append $labelSelectors (printf "%s=%s" $k $v) }}
{{- end }}

discovery.kubernetes "opencost" {
  role = "pod"
  namespaces {
    own_namespace = true
  }
  selectors {
    role = "pod"
    label = {{ $labelSelectors | join "," | quote }}
  }
}

discovery.relabel "opencost" {
  targets = discovery.kubernetes.opencost.targets
  rule {
    source_labels = ["__meta_kubernetes_pod_node_name"]
    action = "replace"
    target_label = "instance"
  }
{{- if .Values.opencost.extraDiscoveryRules }}
{{ .Values.opencost.extraDiscoveryRules | indent 2 }}
{{- end }}
}

prometheus.scrape "opencost" {
  targets      = discovery.relabel.opencost.output
  job_name     = {{ .Values.opencost.jobLabel | quote }}
  honor_labels = true
  scrape_interval = {{ .Values.opencost.scrapeInterval | default .Values.global.scrapeInterval | quote }}
  clustering {
    enabled = true
  }
{{- if or $metricAllowList $metricDenyList .Values.opencost.extraMetricProcessingRules }}
  forward_to = [prometheus.relabel.opencost.receiver]
}

prometheus.relabel "opencost" {
  max_cache_size = {{ .Values.opencost.maxCacheSize | default .Values.global.maxCacheSize | int }}
{{- if $metricAllowList }}
  rule {
    source_labels = ["__name__"]
    regex = {{ $metricAllowList | join "|" | quote }}
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
{{- if .Values.opencost.extraMetricProcessingRules }}
{{ .Values.opencost.extraMetricProcessingRules | indent 2 }}
{{- end }}
{{- end }}
  forward_to = argument.metrics_destinations.value
}
{{- end }}
{{- end }}
