{{ define "feature.clusterMetrics.kepler.allowList" }}
{{- $allowList := list }}
{{ if .Values.kepler.metricsTuning.useDefaultAllowList }}
{{- $allowList = concat $allowList (list "up" "scrape_samples_scraped") (.Files.Get "default-allow-lists/kepler.yaml" | fromYamlArray) -}}
{{ end }}
{{ if .Values.kepler.metricsTuning.includeMetrics }}
{{- $allowList = concat $allowList (list "up" "scrape_samples_scraped") .Values.kepler.metricsTuning.includeMetrics -}}
{{ end }}
{{ $allowList | uniq | toYaml }}
{{ end }}

{{- define "feature.clusterMetrics.kepler.alloy" }}
{{- if .Values.kepler.enabled }}
{{- $metricAllowList := include "feature.clusterMetrics.kepler.allowList" . | fromYamlArray }}
{{- $metricDenyList := .Values.kepler.metricsTuning.excludeMetrics }}
{{- $labelSelectors := list }}
{{- range $k, $v := .Values.kepler.labelMatchers }}
{{- $labelSelectors = append $labelSelectors (printf "%s=%s" $k $v) }}
{{- end }}

discovery.kubernetes "kepler" {
  role = "pod"
  namespaces {
    own_namespace = true
  }
  selectors {
    role = "pod"
    label = {{ $labelSelectors | join "," | quote }}
  }
}

discovery.relabel "kepler" {
  targets = discovery.kubernetes.kepler.targets
  rule {
    source_labels = ["__meta_kubernetes_pod_node_name"]
    action = "replace"
    target_label = "instance"
  }
{{- if .Values.kepler.extraDiscoveryRules }}
{{ .Values.kepler.extraDiscoveryRules | indent 2 }}
{{- end }}
}

prometheus.scrape "kepler" {
  targets      = discovery.relabel.kepler.output
  job_name     = {{ .Values.kepler.jobLabel | quote }}
  honor_labels = true
  scrape_interval = {{ .Values.kepler.scrapeInterval | default .Values.global.scrapeInterval | quote }}
  clustering {
    enabled = true
  }
{{- if or $metricAllowList $metricDenyList .Values.kepler.extraMetricProcessingRules }}
  forward_to = [prometheus.relabel.kepler.receiver]
}

prometheus.relabel "kepler" {
  max_cache_size = {{ .Values.kepler.maxCacheSize | default .Values.global.maxCacheSize | int }}
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
{{- if .Values.kepler.extraMetricProcessingRules }}
{{ .Values.kepler.extraMetricProcessingRules | indent 2 }}
{{- end }}
{{- end }}
  forward_to = argument.metrics_destinations.value
}
{{- end }}
{{- end }}
