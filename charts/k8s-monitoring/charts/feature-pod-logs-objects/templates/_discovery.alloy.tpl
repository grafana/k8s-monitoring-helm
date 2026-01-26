{{- define "feature.podLogsObjects.discovery.alloy" }}
loki.source.podlogs "default" {
  preserve_discovered_labels = {{ .Values.includePodMetadataLabels }}
  tail_from_end = {{ .Values.onlyGatherNewLogLines }}

{{- if .Values.labelSelectors }}
  selector {
    {{- range $label, $value := .Values.labelSelectors }}
    match_expression {
      key = {{ $label | quote }}
      operator = "In"
      {{- if kindIs "slice" $value }}
      values = {{ $value | toJson }}
      {{- else }}
      values = [{{ $value | quote }}]
      {{- end }}
    }
    {{- end }}
  }
{{- end }}
{{- if or .Values.namespaces .Values.excludeNamespaces }}
  namespace_selector {
  {{- if .Values.namespaces }}
    match_expression {
      key = "kubernetes.io/metadata.name"
      operator = "In"
      values = {{ .Values.namespaces | toJson }}
    }
  {{- end }}
  {{- if .Values.excludeNamespaces }}
    match_expression {
      key = "kubernetes.io/metadata.name"
      operator = "NotIn"
      values = {{ .Values.excludeNamespaces | toJson }}
    }
  {{- end }}
  }
{{- end }}

  clustering {
    enabled = true
  }
  forward_to = [loki.relabel.pod_logs_objects.receiver]
}
{{- end -}}
