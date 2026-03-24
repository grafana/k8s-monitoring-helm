{{- define "feature.clusterMetrics.module" }}
{{- $discoverNodes := false }}
{{- $discoverNodes = or $discoverNodes .Values.cadvisor.enabled }}
{{- $discoverNodes = or $discoverNodes .Values.kubelet.enabled }}
{{- $discoverNodes = or $discoverNodes .Values.kubeletResource.enabled }}
{{- $discoverNodes = or $discoverNodes .Values.kubeletProbes.enabled }}
declare "cluster_metrics" {
  argument "metrics_destinations" {
    comment = "Must be a list of metric destinations where collected metrics should be forwarded to"
  }

  {{- if $discoverNodes }}
  discovery.kubernetes "nodes" {
    role = "node"
  }

  discovery.relabel "nodes" {
    targets = discovery.kubernetes.nodes.targets
    rule {
      source_labels = ["__meta_kubernetes_node_name"]
      target_label  = "node"
    }

    rule {
      replacement = "kubernetes"
      target_label = "source"
    }
  }
  {{- end }}
  {{- include "feature.clusterMetrics.kubelet.alloy" . | indent 2 }}
  {{- include "feature.clusterMetrics.kubeletResource.alloy" . | indent 2 }}
  {{- include "feature.clusterMetrics.kubeletProbes.alloy" . | indent 2 }}
  {{- include "feature.clusterMetrics.cadvisor.alloy" . | indent 2 }}
  {{- include "feature.clusterMetrics.apiServer.alloy" . | indent 2 }}
  {{- include "feature.clusterMetrics.kubeControllerManager.alloy" . | indent 2 }}
  {{- include "feature.clusterMetrics.kubeDNS.alloy" . | indent 2 }}
  {{- include "feature.clusterMetrics.kubeProxy.alloy" . | indent 2 }}
  {{- include "feature.clusterMetrics.kubeScheduler.alloy" . | indent 2 }}
  {{- include "feature.clusterMetrics.kube_state_metrics.alloy" . | indent 2 }}
}
{{- end -}}
