{{- define "feature.hostMetrics.module" }}
{{- $discoverNodes := false }}
declare "host_metrics" {
  argument "metrics_destinations" {
    comment = "Must be a list of metric destinations where collected metrics should be forwarded to"
  }

  {{- include "feature.hostMetrics.linuxHosts.alloy" . | indent 2 }}
  {{- include "feature.hostMetrics.windowsHosts.alloy" . | indent 2 }}
  {{- include "feature.hostMetrics.energyMetrics.alloy" . | indent 2 }}
}
{{- end -}}
