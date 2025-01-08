{{ define "feature.clusterMetrics.kube_state_metrics.allowList" }}
{{- $allowList := list }}
{{ if (index .Values "kube-state-metrics").metricsTuning.useDefaultAllowList }}
{{- $allowList = concat $allowList (list "up" "scrape_samples_scraped") (.Files.Get "default-allow-lists/kube-state-metrics.yaml" | fromYamlArray) -}}
{{ end }}
{{ if (index .Values "kube-state-metrics").metricsTuning.includeMetrics }}
{{- $allowList = concat $allowList (list "up" "scrape_samples_scraped") (index .Values "kube-state-metrics").metricsTuning.includeMetrics -}}
{{ end }}
{{ $allowList | uniq | toYaml }}
{{ end }}

{{- define "feature.clusterMetrics.kube_state_metrics.alloy" }}
{{- if (index .Values "kube-state-metrics").enabled }}
{{- $metricAllowList := include "feature.clusterMetrics.kube_state_metrics.allowList" . | fromYamlArray }}
{{- $metricDenyList := (index .Values "kube-state-metrics").metricsTuning.excludeMetrics }}
{{- include "alloyModules.load" (deepCopy $ | merge (dict "name" "kube_state_metrics" "path" "modules/kubernetes/kube-state-metrics/metrics.alloy")) | nindent 0 }}

kube_state_metrics.kubernetes "targets" {
  label_selectors = [
{{- range $label, $value := (index .Values "kube-state-metrics").labelMatchers }}
    {{ printf "%s=%s" $label $value | quote }},
{{- end }}
{{- if (index .Values "kube-state-metrics").deploy }}
    {{ printf "release=%s" .Release.Name | quote }},
{{- end }}
  ]
}
{{- $scrapeTargets := "kube_state_metrics.kubernetes.targets.output" }}
{{- if (index .Values "kube-state-metrics").extraDiscoveryRules }}

discovery.relabel "kube_state_metrics" {
  targets = {{ $scrapeTargets }}
  {{ (index .Values "kube-state-metrics").extraDiscoveryRules | nindent 2 }}
}
{{- $scrapeTargets = "discovery.relabel.kube_state_metrics.output" }}
{{- end }}

kube_state_metrics.scrape "metrics" {
  targets = {{ $scrapeTargets }}
  clustering = true
{{- if $metricAllowList }}
  keep_metrics = {{ $metricAllowList | join "|" | quote }}
{{- end }}
{{- if $metricDenyList }}
  drop_metrics = {{ $metricDenyList | join "|" | quote }}
{{- end }}
  scrape_interval = {{ (index .Values "kube-state-metrics").scrapeInterval | default .Values.global.scrapeInterval | quote }}
  max_cache_size = {{ (index .Values "kube-state-metrics").maxCacheSize | default .Values.global.maxCacheSize | int }}
{{- if (index .Values "kube-state-metrics").extraMetricProcessingRules }}
  forward_to = [prometheus.relabel.kube_state_metrics.receiver]
}

prometheus.relabel "kube_state_metrics" {
  max_cache_size = {{ (index .Values "kube-state-metrics").maxCacheSize | default .Values.global.maxCacheSize | int }}
{{- if (index .Values "kube-state-metrics").extraMetricProcessingRules }}
  {{ (index .Values "kube-state-metrics").extraMetricProcessingRules | nindent 2}}
{{- end }}
{{- end }}
  forward_to = argument.metrics_destinations.value
}
{{- end }}
{{- end }}
