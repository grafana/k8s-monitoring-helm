{{- define "feature.podLogsViaLoki.module" }}
declare "pod_logs_via_loki" {
  argument "logs_destinations" {
    comment = "Must be a list of log destinations where collected logs should be forwarded to"
  }

  {{- include "feature.podLogsViaLoki.discovery.alloy" . | nindent 2 }}
  {{- include "feature.podLogsViaLoki.gathering.alloy" . | nindent 2 }}
  {{- include "feature.podLogsViaLoki.processing.alloy" . | nindent 2 }}
}
{{- end -}}
