{{- define "feature.integrations.nodeDiscoveryRules" }}
{{- if eq .Values.nodeLabels.nodePool true }}

rule {
  source_labels = [
    "__meta_kubernetes_node_label_karpenter_sh_nodepool",
    "__meta_kubernetes_node_label_cloud_google_com_gke_nodepool",
    "__meta_kubernetes_node_label_eks_amazonaws_com_nodegroup",
    "__meta_kubernetes_node_label_kubernetes_azure_com_agentpool",
    "__meta_kubernetes_node_label_agentpool",
  ]
  regex = "^(?:;*)?([^;]+).*$"
  target_label = "nodepool"
}
{{- end }}
{{- if eq .Values.nodeLabels.region true }}

rule {
  source_labels = [
    "__meta_kubernetes_node_label_topology_kubernetes_io_region",
    "__meta_kubernetes_node_label_failure_domain_beta_kubernetes_io_region",
  ]
  regex = "^(?:;*)?([^;]+).*$"
  target_label = "region"
}
{{- end }}
{{- if eq .Values.nodeLabels.availabilityZone true }}

rule {
  source_labels = [
    "__meta_kubernetes_node_label_topology_kubernetes_io_zone",
    "__meta_kubernetes_node_label_failure_domain_beta_kubernetes_io_zone",
    "__meta_kubernetes_node_label_topology_gke_io_zone",
  ]
  regex = "^(?:;*)?([^;]+).*$"
  target_label = "availability_zone"
}
{{- end }}
{{- if eq .Values.nodeLabels.nodeRole true }}

rule {
  source_labels = [
    "__meta_kubernetes_node_label_kubernetes_io_role",
    "__meta_kubernetes_node_label_node_kubernetes_io_role",
    "__meta_kubernetes_node_label_node_role",
    "__meta_kubernetes_node_label_role",
  ]
  regex = "^(?:;*)?([^;]+).*$"
  target_label = "node_role"
}
{{- end }}
{{- if eq .Values.nodeLabels.nodeOS true }}

rule {
  source_labels = [
    "__meta_kubernetes_node_label_kubernetes_io_os",
    "__meta_kubernetes_node_label_os_kubernetes_io",
    "__meta_kubernetes_node_label_os",
  ]
  regex = "^(?:;*)?([^;]+).*$"
  target_label = "os"
}
{{- end }}
{{- if eq .Values.nodeLabels.nodeArchitecture true }}

rule {
  source_labels = [
    "__meta_kubernetes_node_label_kubernetes_io_arch",
    "__meta_kubernetes_node_label_beta_kubernetes_io_arch",
  ]
  regex = "^(?:;*)?([^;]+).*$"
  target_label = "architecture"
}
{{- end }}
{{- if eq .Values.nodeLabels.instanceType true }}

rule {
  source_labels = [
    "__meta_kubernetes_node_label_node_kubernetes_io_instance_type",
    "__meta_kubernetes_node_label_beta_kubernetes_io_instance_type",
  ]
  regex = "^(?:;*)?([^;]+).*$"
  target_label = "instance_type"
}
{{- end }}
{{- end }}
