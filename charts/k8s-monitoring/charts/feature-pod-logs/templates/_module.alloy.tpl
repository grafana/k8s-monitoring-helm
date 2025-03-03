{{- define "feature.podLogs.module" }}
declare "pod_logs" {
  argument "logs_destinations" {
    comment = "Must be a list of log destinations where collected logs should be forwarded to"
  }

{{- if or (eq .Values.gatherMethod "volumes") (eq .Values.gatherMethod "kubernetesApi") }}
  {{- include "feature.podLogs.discovery.alloy" . | nindent 2 }}
{{- end }}

{{- if eq .Values.gatherMethod "volumes" }}
  {{- include "feature.podLogs.volumes.alloy" . | nindent 2 }}
{{- else if eq .Values.gatherMethod "filelog" }}
  {{- include "feature.podLogs.filelog.alloy" . | nindent 2 }}
{{- else if eq .Values.gatherMethod "kubernetesApi" }}
  {{- include "feature.podLogs.kubernetesApi.alloy" . | nindent 2 }}
{{- else if eq .Values.gatherMethod "OpenShiftClusterLogForwarder" }}
  {{- include "feature.podLogs.logReceiver.alloy" . | nindent 2 }}
{{- end }}

  {{- include "feature.podLogs.processing.alloy" . | nindent 2 }}
}
{{- end -}}

{{- define "feature.podLogs.alloyModules" }}{{- end }}
