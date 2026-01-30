{{- define "feature.podLogsObjects.module" }}
declare "pod_logs_objects" {
  argument "logs_destinations" {
    comment = "Must be a list of log destinations where collected logs should be forwarded to"
  }
  {{ include "feature.podLogsObjects.discovery.alloy" . | nindent 2 }}
  {{ include "feature.podLogsObjects.processing.alloy" . | nindent 2 }}
}
{{- end -}}
