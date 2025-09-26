{{- define "feature.podLogs.kubernetesApi.alloy" }}
{{- $labelSelectors := list }}
{{- range $k, $v := .Values.labelSelectors }}
  {{- if kindIs "slice" $v }}
    {{- $labelSelectors = append $labelSelectors (printf "%s in (%s)" $k (join "," $v)) }}
  {{- else }}
    {{- $labelSelectors = append $labelSelectors (printf "%s=%s" $k $v) }}
  {{- end }}
{{- end }}
{{- $nodeSelectors := list }}
{{- range $k, $v := .Values.nodeSelectors }}
  {{- if kindIs "slice" $v }}
    {{- $nodeSelectors = append $nodeSelectors (printf "%s in (%s)" $k (join "," $v)) }}
  {{- else }}
    {{- $nodeSelectors = append $nodeSelectors (printf "%s=%s" $k $v) }}
  {{- end }}
{{- end }}
discovery.kubernetes "pods" {
  role = "pod"
{{- if .Values.namespaces }}
  namespaces {
    names = {{ .Values.namespaces | toJson }}
  }
{{- end }}
{{- if $labelSelectors }}
    selectors {
      role = "pod"
      label = {{ $labelSelectors | join "," | quote }}
    }
{{- end }}
{{- if $nodeSelectors }}
    selectors {
      role = "node"
      label = {{ $nodeSelectors | join "," | quote }}
    }
{{- end }}
{{- include "feature.podLogs.attachNodeMetadata" . | indent 2 }}
}

loki.source.kubernetes "pod_logs" {
  targets = discovery.relabel.filtered_pods.output
  clustering {
    enabled = true
  }
  forward_to = [loki.process.pod_logs.receiver]
}
{{- end }}
