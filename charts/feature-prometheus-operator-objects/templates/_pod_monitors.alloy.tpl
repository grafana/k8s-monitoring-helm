{{- define "feature.prometheusOperatorObjects.podMonitors.alloy" }}
{{- if .Values.podMonitors.enabled }}
// Prometheus Operator podMonitor objects
prometheus.operator.podmonitors "pod_monitors" {
{{- if .Values.podMonitors.namespaces }}
  namespaces = {{ .Values.podMonitors.namespaces | toJson }}
{{- end }}
{{- if .Values.podMonitors.selector }}
  selector {
{{ .Values.podMonitors.selector | indent 4 }}
  }
{{- end }}
  clustering {
    enabled = true
  }
  scrape {
    default_scrape_interval = {{ .Values.podMonitors.scrapeInterval | default .Values.global.scrapeInterval | quote }}
  }

{{- if .Values.podMonitors.extraDiscoveryRules }}
{{ .Values.podMonitors.extraDiscoveryRules | indent 2 }}
{{- end }}
{{- if .Values.podMonitors.extraMetricProcessingRules }}
  forward_to = [prometheus.relabel.podmonitors.receiver]
}

prometheus.relabel "podmonitors" {
  max_cache_size = {{ .Values.podMonitors.maxCacheSize | default .Values.global.maxCacheSize | int }}
{{- if .Values.podMonitors.extraMetricProcessingRules }}
{{ .Values.podMonitors.extraMetricProcessingRules | indent 2 }}
{{- end }}
{{- end }}
  forward_to = argument.metrics_destinations.value
}
{{- end }}
{{- end }}
