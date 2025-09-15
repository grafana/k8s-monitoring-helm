{{- define "feature.podLogsViaKubernetesApi.module" }}
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
declare "pod_logs_via_kubernetes_api" {
  argument "logs_destinations" {
    comment = "Must be a list of log destinations where collected logs should be forwarded to"
  }

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
  {{- include "feature.podLogsViaKubernetesApi.attachNodeMetadata" . | indent 4 }}
  }

  {{- include "feature.podLogsViaKubernetesApi.discovery.alloy" . | nindent 2 }}

  loki.source.kubernetes "pod_logs" {
    targets = discovery.relabel.filtered_pods.output
    clustering {
      enabled = true
    }
    forward_to = [loki.process.pod_logs.receiver]
  }

  {{- include "feature.podLogsViaKubernetesApi.processing.alloy" . | nindent 2 }}
}
{{- end -}}
