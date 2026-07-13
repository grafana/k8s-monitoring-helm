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
{{- $attachNodeMetadata := false -}}
{{- $attachNodeMetadata = or $attachNodeMetadata (not (empty .Values.nodeSelectors)) -}}
{{- $attachNodeMetadata = or $attachNodeMetadata .Values.nodeLabels.nodePool -}}
{{- $attachNodeMetadata = or $attachNodeMetadata .Values.nodeLabels.region -}}
{{- $attachNodeMetadata = or $attachNodeMetadata .Values.nodeLabels.availabilityZone -}}
{{- $attachNodeMetadata = or $attachNodeMetadata .Values.nodeLabels.nodeRole -}}
{{- $attachNodeMetadata = or $attachNodeMetadata .Values.nodeLabels.nodeOS -}}
{{- $attachNodeMetadata = or $attachNodeMetadata .Values.nodeLabels.nodeArchitecture -}}
{{- $attachNodeMetadata = or $attachNodeMetadata .Values.nodeLabels.instanceType -}}
{{- if or .Values.attachNamespaceMetadata $attachNodeMetadata }}
    attach_metadata {
  {{- if .Values.attachNamespaceMetadata }}
      namespace = true
  {{- end }}
  {{- if $attachNodeMetadata }}
      node = true
  {{- end }}
    }
{{- end }}
  } // discovery.kubernetes "pods"

  {{- include "feature.podLogsViaKubernetesApi.discovery.alloy" . | nindent 2 }}

  loki.source.kubernetes "pod_logs" {
    targets = discovery.relabel.filtered_pods.output
    clustering {
      enabled = true
    }
    forward_to = [loki.process.pod_logs.receiver]
  } // loki.source.kubernetes "pod_logs"

  {{- include "feature.podLogsViaKubernetesApi.processing.alloy" . | nindent 2 }}
} // declare "pod_logs_via_kubernetes_api"
{{- end -}}
