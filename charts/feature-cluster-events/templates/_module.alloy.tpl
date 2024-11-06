{{- define "feature.clusterEvents.module" }}
declare "cluster_events" {
  argument "logs_destinations" {
    comment = "Must be a list of log destinations where collected logs should be forwarded to"
  }

  loki.source.kubernetes_events "cluster_events" {
    job_name   = "integrations/kubernetes/eventhandler"
    log_format = "{{ .Values.logFormat }}"
  {{- if .Values.namespaces }}
    namespaces = {{ .Values.namespaces | toJson }}
  {{- end }}
{{- if .Values.extraProcessingStages }}
    forward_to = loki.process.cluster_events.receiver
  }

  loki.process "cluster_events" {
{{ .Values.extraProcessingStages | indent 4 }}
{{- end }}
    forward_to = argument.logs_destinations.value
  }
}
{{- end -}}

{{- define "feature.clusterEvents.alloyModules" }}{{- end }}
