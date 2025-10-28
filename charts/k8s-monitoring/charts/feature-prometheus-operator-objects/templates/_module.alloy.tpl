{{- define "feature.prometheusOperatorObjects.module" }}
declare "prometheus_operator_objects" {
  argument "metrics_destinations" {
    comment = "Must be a list of metric destinations where collected metrics should be forwarded to"
  }

{{- if .Values.podMonitors.enabled }}
  {{- include "feature.prometheusOperatorObjects.podMonitors.alloy" . | nindent 2 }}
{{- end }}
{{- if .Values.probes.enabled }}
  {{- include "feature.prometheusOperatorObjects.probes.alloy" . | nindent 2 }}
{{- end }}
{{- if .Values.scrapeConfigs.enabled }}
  {{- include "feature.prometheusOperatorObjects.scrapeConfigs.alloy" . | nindent 2 }}
{{- end }}
{{- if .Values.serviceMonitors.enabled }}
  {{- include "feature.prometheusOperatorObjects.serviceMonitors.alloy" . | nindent 2 }}
{{- end }}
}
{{- end -}}
