{{- define "feature.prometheusOperatorObjects.probes.alloy" }}
{{- if .Values.probes.enabled }}
// Prometheus Operator podMonitor objects
prometheus.operator.probes "pod_monitors" {
{{- if .Values.probes.namespaces }}
  namespaces = {{ .Values.probes.namespaces | toJson }}
{{- end }}
{{- if .Values.probes.selector }}
  selector {
{{ .Values.probes.selector | indent 4 }}
  }
{{- end }}
  clustering {
    enabled = true
  }
  scrape {
    default_scrape_interval = {{ .Values.probes.scrapeInterval | default .Values.global.scrapeInterval | quote }}
  }

{{- if .Values.probes.extraDiscoveryRules }}
{{ .Values.probes.extraDiscoveryRules | indent 2 }}
{{- end }}
{{- if .Values.probes.extraMetricProcessingRules }}
  forward_to = [prometheus.relabel.probes.receiver]
}

prometheus.relabel "probes" {
  max_cache_size = {{ .Values.probes.maxCacheSize | default .Values.global.maxCacheSize | int }}
{{- if .Values.probes.extraMetricProcessingRules }}
{{ .Values.probes.extraMetricProcessingRules | indent 2 }}
{{- end }}
{{- end }}
  forward_to = argument.metrics_destinations.value
}
{{- end }}
{{- end }}
