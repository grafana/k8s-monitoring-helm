{{- define "feature.clusterMetrics.apiServer.alloy" }}
{{- if or .Values.apiServer.enabled (and .Values.controlPlane.enabled (not (eq .Values.apiServer.enabled false))) }}
{{- $metricAllowList := .Values.apiServer.metricsTuning.includeMetrics }}
{{- $metricDenyList := .Values.apiServer.metricsTuning.excludeMetrics }}

kubernetes.apiserver "scrape" {
  clustering = true
  job_label = {{ .Values.apiServer.jobLabel | quote }}
{{- if $metricAllowList }}
  keep_metrics = "up|{{ $metricAllowList | join "|" }}"
{{- end }}
{{- if $metricDenyList }}
  drop_metrics = {{ $metricDenyList | join "|" | quote }}
{{- end }}
  scrape_interval = {{ .Values.apiServer.scrapeInterval | default .Values.global.scrapeInterval | quote }}
  max_cache_size = {{ .Values.apiServer.maxCacheSize | default .Values.global.maxCacheSize | int }}
{{- if .Values.apiServer.extraMetricProcessingRules }}
  forward_to = [prometheus.relabel.apiServer.receiver]
}

prometheus.relabel "apiServer" {
  max_cache_size = {{ .Values.apiServer.maxCacheSize | default .Values.global.maxCacheSize | int }}

{{- if .Values.apiServer.extraMetricProcessingRules }}
  {{ .Values.apiServer.extraMetricProcessingRules | indent 2 }}
{{- end }}

{{- end }}
  forward_to = argument.metrics_destinations.value
}
{{- end }}
{{- end }}
