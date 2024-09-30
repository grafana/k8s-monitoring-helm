{{ define "feature.clusterMetrics.kubelet.allowList" }}
{{ if .Values.kubelet.metricsTuning.useDefaultAllowList }}
{{ "default-allow-lists/kubelet.yaml" | .Files.Get }}
{{ end }}
{{ if .Values.kubelet.metricsTuning.includeMetrics }}
{{ .Values.kubelet.metricsTuning.includeMetrics | toYaml }}
{{ end }}
{{ end }}

{{- define "feature.clusterMetrics.kubelet.alloy" }}
{{- if .Values.kubelet.enabled }}
{{- $metricAllowList := include "feature.clusterMetrics.kubelet.allowList" . }}
{{- $metricDenyList := .Values.kubelet.metricsTuning.excludeMetrics }}

kubernetes.kubelet "scrape" {
  clustering = true
{{- if $metricAllowList }}
  keep_metrics = "up|{{ $metricAllowList | fromYamlArray | join "|" }}"
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

  {{ .Values.kubelet.extraMetricProcessingRules | indent 2 }}

{{- end }}
  forward_to = argument.metrics_destinations.value
}
{{- end }}
{{- end }}
