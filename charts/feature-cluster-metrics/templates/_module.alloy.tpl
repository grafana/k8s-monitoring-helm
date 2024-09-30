{{- define "feature.clusterMetrics.module" }}
declare "cluster_metrics" {
  argument "metrics_destinations" {
    comment = "Must be a list of metric destinations where collected metrics should be forwarded to"
  }

  {{- if or .Values.cadvisor.enabled .Values.kubelet.enabled (or .Values.apiServer.enabled (and .Values.controlPlane.enabled (not (eq .Values.apiServer.enabled false)))) }}
  import.git "kubernetes" {
    repository = "https://github.com/grafana/alloy-modules.git"
    revision = "main"
    path = "modules/kubernetes/core/metrics.alloy"
    pull_frequency = "15m"
  }
  {{- end }}
  {{- include "feature.clusterMetrics.kubelet.alloy" . | indent 2 }}
  {{- include "feature.clusterMetrics.cadvisor.alloy" . | indent 2 }}
  {{- include "feature.clusterMetrics.apiServer.alloy" . | indent 2 }}
  {{- include "feature.clusterMetrics.kubeControllerManager.alloy" . | indent 2 }}
  {{- include "feature.clusterMetrics.kubeProxy.alloy" . | indent 2 }}
  {{- include "feature.clusterMetrics.kubeScheduler.alloy" . | indent 2 }}
  {{- include "feature.clusterMetrics.kube_state_metrics.alloy" . | indent 2 }}
  {{- include "feature.clusterMetrics.node_exporter.alloy" . | indent 2 }}
  {{- include "feature.clusterMetrics.windows_exporter.alloy" . | indent 2 }}
  {{- include "feature.clusterMetrics.kepler.alloy" . | indent 2 }}
}
{{- end -}}