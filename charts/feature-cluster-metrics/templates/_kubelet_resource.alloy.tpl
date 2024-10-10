{{ define "feature.clusterMetrics.kubeletResource.allowList" }}
{{ if .Values.kubeletResource.metricsTuning.useDefaultAllowList }}
{{ "default-allow-lists/kubelet_resource.yaml" | .Files.Get }}
{{ end }}
{{ if .Values.kubeletResource.metricsTuning.includeMetrics }}
{{ .Values.kubeletResource.metricsTuning.includeMetrics | toYaml }}
{{ end }}
{{ end }}

{{- define "feature.clusterMetrics.kubeletResource.alloy" }}
{{- if .Values.kubeletResource.enabled }}
{{- $metricAllowList := include "feature.clusterMetrics.kubeletResource.allowList" . }}
{{- $metricDenyList := .Values.kubeletResource.metricsTuning.excludeMetrics }}

kubernetes.resources "scrape" {
  clustering = true
  job_label = "integrations/kubernetes/resources"
{{- if $metricAllowList }}
  keep_metrics = "up|{{ $metricAllowList | fromYamlArray | join "|" }}"
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

  {{ .Values.kubeletResource.extraMetricProcessingRules | indent 2 }}

{{- end }}
  forward_to = argument.metrics_destinations.value
}
{{- end }}
{{- end }}
