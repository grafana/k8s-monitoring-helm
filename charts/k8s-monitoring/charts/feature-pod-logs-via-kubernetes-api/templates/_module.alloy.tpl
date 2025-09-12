{{- define "feature.podLogsViaK8sAPI.module" }}
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
  {{- include "feature.podLogsViaK8sAPI.attachNodeMetadata" . | indent 2 }}
  }
  {{- include "feature.podLogsViaK8sAPI.discovery.alloy" . | nindent 2 }}

  loki.source.kubernetes "pod_logs" {
    targets = discovery.relabel.filtered_pods.output
    clustering {
      enabled = true
    }
    forward_to = [loki.process.pod_logs.receiver]
  }

  {{- include "feature.podLogsViaK8sAPI.processing.alloy" . | nindent 2 }}
}
{{- end -}}
