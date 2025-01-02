{{ define "feature.clusterMetrics.kubeletResource.allowList" }}
{{- $allowList := list }}
{{ if .Values.kubeletResource.metricsTuning.useDefaultAllowList }}
{{- $allowList = concat $allowList (list "up") (.Files.Get "default-allow-lists/kubelet_resource.yaml" | fromYamlArray) -}}
{{ end }}
{{ if .Values.kubeletResource.metricsTuning.includeMetrics }}
{{- $allowList = concat $allowList (list "up") .Values.kubeletResource.metricsTuning.includeMetrics -}}
{{ end }}
{{ $allowList | uniq | toYaml }}
{{ end }}

{{- define "feature.clusterMetrics.kubeletResource.alloy" }}
{{- if .Values.kubeletResource.enabled }}
{{- $metricAllowList := include "feature.clusterMetrics.kubeletResource.allowList" . | fromYamlArray }}
{{- $metricDenyList := .Values.kubeletResource.metricsTuning.excludeMetrics }}

kubernetes.resources "scrape" {
  clustering = true
  job_label = "integrations/kubernetes/resources"
{{- if $metricAllowList }}
  keep_metrics = {{ $metricAllowList | join "|" | quote }}
{{- end }}
{{- if $metricDenyList }}
  drop_metrics = {{ $metricDenyList | join "|" | quote }}
{{- end }}
  scrape_interval = {{ .Values.kubeletResource.scrapeInterval | default .Values.global.scrapeInterval | quote }}
  max_cache_size = {{ .Values.kubeletResource.maxCacheSize | default .Values.global.maxCacheSize | int }}
{{- if .Values.kubeletResource.extraMetricProcessingRules }}
  forward_to = [prometheus.relabel.kubelet_resources.receiver]
}

prometheus.relabel "kubelet_resources" {
  max_cache_size = {{ .Values.kubeletResource.maxCacheSize | default .Values.global.maxCacheSize | int }}

{{- if .Values.kubeletResource.extraMetricProcessingRules }}
  {{ .Values.kubeletResource.extraMetricProcessingRules | indent 2 }}
{{- end }}

{{- end }}
  forward_to = argument.metrics_destinations.value
}
{{- end }}
{{- end }}
