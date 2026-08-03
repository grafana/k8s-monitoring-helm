{{- define "feature.hostMetrics.module" }}
{{- $discoverNodes := false }}
declare "host_metrics" {
  argument "metrics_destinations" {
    comment = "Must be a list of metric destinations where collected metrics should be forwarded to"
  }

  {{- include "feature.hostMetrics.linuxHosts.alloy" . | indent 2 }}
  {{- include "feature.hostMetrics.windowsHosts.alloy" . | indent 2 }}
  {{- include "feature.hostMetrics.energyMetrics.alloy" . | indent 2 }}
} // declare "host_metrics"
{{- end -}}

{{- define "feature.hostMetrics.linuxHosts.module" }}
{{- $discoverNodes := false }}
declare "linux_host_metrics" {
  argument "metrics_destinations" {
    comment = "Must be a list of metric destinations where collected metrics should be forwarded to"
  }

  {{- include "feature.hostMetrics.linuxHosts.alloy" . | indent 2 }}
} // declare "linux_host_metrics"
{{- end -}}

{{- define "feature.hostMetrics.windowsHosts.module" }}
{{- $discoverNodes := false }}
declare "windows_host_metrics" {
  argument "metrics_destinations" {
    comment = "Must be a list of metric destinations where collected metrics should be forwarded to"
  }

  {{- include "feature.hostMetrics.windowsHosts.alloy" . | indent 2 }}
} // declare "windows_host_metrics"
{{- end -}}

{{- define "feature.hostMetrics.energyMetrics.module" }}
{{- $discoverNodes := false }}
declare "energy_metrics" {
  argument "metrics_destinations" {
    comment = "Must be a list of metric destinations where collected metrics should be forwarded to"
  }

  {{- include "feature.hostMetrics.energyMetrics.alloy" . | indent 2 }}
} // declare "energy_metrics"
{{- end -}}
