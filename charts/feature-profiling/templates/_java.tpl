{{ define "feature.profiling.java.alloy" }}
{{- if .Values.java.enabled }}
// Profiles: Java
discovery.kubernetes "java_pods" {
  selectors {
    role = "pod"
    field = "spec.nodeName=" + sys.env("HOSTNAME")
  }
{{- if .Values.java.namespaces }}
  namespaces {
    names = {{ .Values.java.namespaces | toJson }}
  }
{{- end }}
  role = "pod"
}

discovery.process "java_pods" {
  join = discovery.kubernetes.java_pods.targets
}

discovery.relabel "java_pods" {
  targets = discovery.process.java_pods.targets
  rule {
    source_labels = ["__meta_kubernetes_pod_phase"]
    regex = "Succeeded|Failed|Completed"
    action = "drop"
  }
  rule {
    source_labels = ["__meta_kubernetes_pod_name"]
    regex = "^$"
    action = "drop"
  }
  rule {
    source_labels = ["__meta_process_exe"]
    action = "keep"
    regex = ".*/java$"
  }
  rule {
    source_labels = ["__meta_kubernetes_namespace"]
    target_label = "namespace"
  }
{{- if .Values.java.excludeNamespaces }}
  rule {
    source_labels = ["namespace"]
    regex = "{{ .Values.java.excludeNamespaces | join "|" }}"
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
{{- if .Values.java.extraDiscoveryRules }}
{{ .Values.java.extraDiscoveryRules | indent 2 }}
{{- end }}
}

pyroscope.java "java_pods" {
  targets = discovery.relabel.java_pods.output
  profiling_config {
    interval = {{ .Values.java.profilingConfig.interval | quote }}
    alloc = {{ .Values.java.profilingConfig.alloc | quote }}
    cpu = {{ .Values.java.profilingConfig.cpu }}
    sample_rate = {{ .Values.java.profilingConfig.sampleRate }}
    lock = {{ .Values.java.profilingConfig.lock | quote }}
  }
  forward_to = argument.profiles_destinations.value
}
{{- end }}
{{- end }}
