{{- define "feature.prometheusOperatorObjects.serviceMonitors.alloy" }}
{{- if .Values.serviceMonitors.enabled }}
// Prometheus Operator ServiceMonitor objects
prometheus.operator.servicemonitors "service_monitors" {
{{- if .Values.serviceMonitors.namespaces }}
  namespaces = {{ .Values.serviceMonitors.namespaces | toJson }}
{{- end }}
{{- if .Values.serviceMonitors.selector }}
  selector {
{{ .Values.serviceMonitors.selector | indent 4 }}
  }
{{- end }}
  clustering {
    enabled = true
  }
  scrape {
    default_scrape_interval = {{ .Values.serviceMonitors.scrapeInterval | default .Values.global.scrapeInterval | quote }}
  }

{{- if .Values.serviceMonitors.extraDiscoveryRules }}
{{ .Values.serviceMonitors.extraDiscoveryRules | indent 2 }}
{{- end }}
{{- if .Values.serviceMonitors.extraMetricProcessingRules }}
  forward_to = [prometheus.relabel.servicemonitors.receiver]
}

prometheus.relabel "servicemonitors" {
  max_cache_size = {{ .Values.serviceMonitors.maxCacheSize | default .Values.global.maxCacheSize | int }}
{{- if .Values.serviceMonitors.extraMetricProcessingRules }}
{{ .Values.serviceMonitors.extraMetricProcessingRules | indent 2 }}
{{- end }}
{{- end }}
  forward_to = argument.metrics_destinations.value
}
{{- end }}
{{- end }}
