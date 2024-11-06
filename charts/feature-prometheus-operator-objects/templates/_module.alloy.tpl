{{- define "feature.prometheusOperatorObjects.module" }}
declare "prometheus_operator_objects" {
  argument "metrics_destinations" {
    comment = "Must be a list of metric destinations where collected metrics should be forwarded to"
  }

  {{- include "feature.prometheusOperatorObjects.podMonitors.alloy" . | nindent 2 }}
  {{- include "feature.prometheusOperatorObjects.probes.alloy" . | nindent 2 }}
  {{- include "feature.prometheusOperatorObjects.serviceMonitors.alloy" . | nindent 2 }}
}
{{- end -}}

{{- define "feature.prometheusOperatorObjects.alloyModules" }}{{- end }}
