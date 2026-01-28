{{- define "feature.clusterMetrics.metricEnrichment.pods" }}
{{- if .Values.podLabels }}
discovery.kubernetes "pods" {
  role = "pod"
}


{{- end }}
{{- end }}
