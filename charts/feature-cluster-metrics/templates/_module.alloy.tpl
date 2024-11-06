{{- define "feature.clusterMetrics.module" }}
declare "cluster_metrics" {
  argument "metrics_destinations" {
    comment = "Must be a list of metric destinations where collected metrics should be forwarded to"
  }

  {{- if or .Values.cadvisor.enabled .Values.kubelet.enabled .Values.kubeletResource.enabled (or .Values.apiServer.enabled (and .Values.controlPlane.enabled (not (eq .Values.apiServer.enabled false)))) }}
  {{- include "alloyModules.load" (deepCopy $ | merge (dict "name" "kubernetes" "path" "modules/kubernetes/core/metrics.alloy")) | nindent 2 }}
  {{- end }}
  {{- include "feature.clusterMetrics.kubelet.alloy" . | indent 2 }}
  {{- include "feature.clusterMetrics.kubeletResource.alloy" . | indent 2 }}
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

{{- define "feature.clusterMetrics.alloyModules" }}
{{- if or .Values.cadvisor.enabled .Values.kubelet.enabled .Values.kubeletResource.enabled (or .Values.apiServer.enabled (and .Values.controlPlane.enabled (not (eq .Values.apiServer.enabled false)))) }}
- modules/kubernetes/core/metrics.alloy
{{- end }}
{{- if (index .Values "kube-state-metrics").enabled }}
- modules/kubernetes/kube-state-metrics/metrics.alloy
{{- end }}
{{- if (index .Values "node-exporter").enabled }}
- modules/system/node-exporter/metrics.alloy
{{- end }}
{{- end }}
