{{- define "feature.podLogs.kubernetesApi.alloy" }}
discovery.kubernetes "pods" {
  role = "pod"
{{- if .Values.namespaces }}
  namespaces {
    names = {{ .Values.namespaces | toJson }}
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
