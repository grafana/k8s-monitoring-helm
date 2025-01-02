{{ define "feature.clusterMetrics.kubelet.allowList" }}
{{- $allowList := list }}
{{ if .Values.kubelet.metricsTuning.useDefaultAllowList }}
{{- $allowList = concat $allowList (list "up") (.Files.Get "default-allow-lists/kubelet.yaml" | fromYamlArray) -}}
{{ end }}
{{ if .Values.kubelet.metricsTuning.includeMetrics }}
{{- $allowList = concat $allowList (list "up") .Values.kubelet.metricsTuning.includeMetrics -}}
{{ end }}
{{ $allowList | uniq | toYaml }}
{{ end }}

{{- define "feature.clusterMetrics.kubelet.alloy" }}
{{- if .Values.kubelet.enabled }}
{{- $metricAllowList := include "feature.clusterMetrics.kubelet.allowList" . | fromYamlArray }}
{{- $metricDenyList := .Values.kubelet.metricsTuning.excludeMetrics }}

kubernetes.kubelet "scrape" {
  clustering = true
{{- if $metricAllowList }}
  keep_metrics = {{ $metricAllowList | join "|" | quote }}
{{- end }}
{{- if $metricDenyList }}
  drop_metrics = {{ $metricDenyList | join "|" | quote }}
{{- end }}
  scrape_interval = {{ .Values.kubelet.scrapeInterval | default .Values.global.scrapeInterval | quote }}
  max_cache_size = {{ .Values.kubelet.maxCacheSize | default .Values.global.maxCacheSize | int }}
{{- if .Values.kubelet.extraMetricProcessingRules }}
  forward_to = [prometheus.relabel.kubelet.receiver]
}

prometheus.relabel "kubelet" {
  max_cache_size = {{ .Values.kubelet.maxCacheSize | default .Values.global.maxCacheSize | int }}
{{- if .Values.kubelet.extraMetricProcessingRules }}
  {{ .Values.kubelet.extraMetricProcessingRules | indent 2 }}
{{- end }}

{{- end }}
  forward_to = argument.metrics_destinations.value
}
{{- end }}
{{- end }}
