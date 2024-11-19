{{ define "feature.clusterMetrics.kube_state_metrics.allowList" }}
{{ if (index .Values "kube-state-metrics").metricsTuning.useDefaultAllowList }}
{{ "default-allow-lists/kube-state-metrics.yaml" | .Files.Get }}
{{ end }}
{{ if (index .Values "kube-state-metrics").metricsTuning.includeMetrics }}
{{ (index .Values "kube-state-metrics").metricsTuning.includeMetrics | toYaml }}
{{ end }}
{{ end }}

{{- define "feature.clusterMetrics.kube_state_metrics.alloy" }}
{{- if (index .Values "kube-state-metrics").enabled }}
{{- $metricAllowList := include "feature.clusterMetrics.kube_state_metrics.allowList" . }}
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
  keep_metrics = "up|{{ $metricAllowList | fromYamlArray | join "|" }}"
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
