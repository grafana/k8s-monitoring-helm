{{ define "feature.clusterMetrics.kepler.allowList" }}
{{ if .Values.kepler.metricsTuning.useDefaultAllowList }}
{{ "default-allow-lists/kepler.yaml" | .Files.Get }}
{{ end }}
{{ if .Values.kepler.metricsTuning.includeMetrics }}
{{ .Values.kepler.metricsTuning.includeMetrics | toYaml }}
{{ end }}
{{ end }}

{{- define "feature.clusterMetrics.kepler.alloy" }}
{{- if .Values.kepler.enabled }}
{{- $metricAllowList := include "feature.clusterMetrics.kepler.allowList" . }}
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
  job_name     = "integrations/kepler"
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
    regex = "up|{{ $metricAllowList | fromYamlArray | join "|" }}"
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
