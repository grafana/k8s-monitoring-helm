{{- define "feature.costMetrics.module" }}
declare "cost_metrics" {
  argument "metrics_destinations" {
    comment = "Must be a list of metric destinations where collected metrics should be forwarded to"
  }

  {{- include "feature.costMetrics.opencost.alloy" . | indent 2 }}
}
{{- end -}}
