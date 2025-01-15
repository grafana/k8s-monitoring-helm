{{- define "feature.clusterMetrics.kubeDNS.alloy" }}
{{- if or .Values.kubeDNS.enabled (and .Values.controlPlane.enabled (not (eq .Values.kubeDNS.enabled false))) }}
{{- $metricAllowList := .Values.kubeDNS.metricsTuning.includeMetrics }}
{{- $metricDenyList := .Values.kubeDNS.metricsTuning.excludeMetrics }}

kubernetes.kube_dns "scrape" {
  clustering = true
  job_label = {{ .Values.kubeDNS.jobLabel | quote }}
{{- if $metricAllowList }}
  keep_metrics = "up|{{ $metricAllowList | join "|" }}"
{{- end }}
{{- if $metricDenyList }}
  drop_metrics = {{ $metricDenyList | join "|" | quote }}
{{- end }}
  scrape_interval = {{ .Values.kubeDNS.scrapeInterval | default .Values.global.scrapeInterval | quote }}
  max_cache_size = {{ .Values.kubeDNS.maxCacheSize | default .Values.global.maxCacheSize | int }}
{{- if .Values.kubeDNS.extraMetricProcessingRules }}
  forward_to = [prometheus.relabel.kube_dns.receiver]
}

prometheus.relabel "kube_dns" {
  max_cache_size = {{ .Values.kubeDNS.maxCacheSize | default .Values.global.maxCacheSize | int }}
{{- if .Values.kubeDNS.extraMetricProcessingRules }}
  {{ .Values.kubeDNS.extraMetricProcessingRules | indent 2 }}
{{- end }}
{{- end }}
  forward_to = argument.metrics_destinations.value
}
{{- end }}
{{- end }}
