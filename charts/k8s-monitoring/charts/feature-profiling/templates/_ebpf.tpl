{{ define "feature.profiling.ebpf.alloy" }}
{{- if .Values.ebpf.enabled }}
// Profiles: eBPF
discovery.kubernetes "ebpf_pods" {
  selectors {
    role = "pod"
    field = "spec.nodeName=" + sys.env("HOSTNAME")
  }
{{- if .Values.ebpf.namespaces }}
  namespaces {
    names = {{ .Values.ebpf.namespaces | toJson }}
  }
{{- end }}
  role = "pod"
}

discovery.relabel "ebpf_pods" {
  targets = discovery.kubernetes.ebpf_pods.targets
  rule {
    source_labels = ["__meta_kubernetes_pod_phase"]
    regex = "Succeeded|Failed|Completed"
    action = "drop"
  }
  rule {
    source_labels = ["__meta_kubernetes_namespace"]
    target_label = "namespace"
  }
{{- if .Values.ebpf.excludeNamespaces }}
  rule {
    source_labels = ["namespace"]
    regex = "{{ .Values.ebpf.excludeNamespaces | join "|" }}"
    action = "drop"
  }
{{- end }}
  rule {
    source_labels = ["__meta_kubernetes_pod_name"]
    target_label = "pod"
  }
  rule {
    source_labels = ["__meta_kubernetes_pod_node_name"]
    target_label = "node"
  }
  rule {
    source_labels = ["__meta_kubernetes_pod_container_name"]
    target_label = "container"
  }
  // provide arbitrary service_name label, otherwise it will be set to {__meta_kubernetes_namespace}/{__meta_kubernetes_pod_container_name}
  rule {
    source_labels = ["__meta_kubernetes_namespace", "__meta_kubernetes_pod_container_name"]
    separator = "@"
    regex = "(.*)@(.*)"
    replacement = "ebpf/${1}/${2}"
    target_label = "service_name"
  }
{{- if .Values.ebpf.extraDiscoveryRules }}
{{ .Values.ebpf.extraDiscoveryRules | indent 2 }}
{{- end }}
}

pyroscope.ebpf "ebpf_pods" {
  targets = discovery.relabel.ebpf_pods.output
  demangle = {{ .Values.ebpf.demangle | quote }}
  forward_to = argument.profiles_destinations.value
}
{{- end }}
{{- end }}
