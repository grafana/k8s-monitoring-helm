{{- define "feature.podLogs.module" }}
declare "pod_logs" {
  argument "logs_destinations" {
    comment = "Must be a list of log destinations where collected logs should be forwarded to"
  }

{{- if .Values.volumeGathering.enabled }}
  {{- include "feature.podLogs.volumeGathering.alloy" . | nindent 2 }}
{{- end }}

{{- if .Values.kubernetesApiGathering.enabled }}
  {{- include "feature.podLogs.kubernetesApi.alloy" . | nindent 2 }}
{{- end }}

{{- if .Values.lokiReceiver.enabled }}
  {{- include "feature.podLogs.lokiReceiver.alloy" . | nindent 2 }}
{{- end }}

  {{- include "feature.podLogs.processing.alloy" . | nindent 2 }}
}
{{- end -}}

{{- define "feature.podLogs.alloyModules" }}{{- end }}
