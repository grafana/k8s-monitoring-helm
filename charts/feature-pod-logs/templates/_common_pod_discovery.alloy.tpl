{{- define "feature.podLogs.discovery.alloy" }}
discovery.relabel "filtered_pods" {
  targets = discovery.kubernetes.pods.targets
  rule {
    source_labels = ["__meta_kubernetes_namespace"]
    action = "replace"
    target_label = "namespace"
  }
{{- if .Values.excludeNamespaces }}
  rule {
    source_labels = ["namespace"]
    regex = "{{ .Values.excludeNamespaces | join "|" }}"
    action = "drop"
  }
{{- end }}
  rule {
    source_labels = ["__meta_kubernetes_pod_name"]
    action = "replace"
    target_label = "pod"
  }
  rule {
    source_labels = ["__meta_kubernetes_pod_container_name"]
    action = "replace"
    target_label = "container"
  }
  rule {
    source_labels = ["__meta_kubernetes_namespace", "__meta_kubernetes_pod_container_name"]
    separator = "/"
    action = "replace"
    replacement = "$1"
    target_label = "job"
  }
{{- range $label, $podLabel := .Values.labels }}
  rule {
    source_labels = ["{{ include "pod_label" $podLabel }}"]
    regex         = "(.+)"
    target_label  = {{ $label | quote }}
  }
{{- end }}
{{- range $label, $podAnnotation := .Values.annotations }}
  rule {
    source_labels = ["{{ include "pod_annotation" $podAnnotation }}"]
    regex         = "(.+)"
    target_label  = {{ $label | quote }}
  }
{{- end }}

  // set the container runtime as a label
  rule {
    action = "replace"
    source_labels = ["__meta_kubernetes_pod_container_id"]
    regex = "^(\\S+):\\/\\/.+$"
    replacement = "$1"
    target_label = "tmp_container_runtime"
  }

{{- if .Values.extraDiscoveryRules }}
{{ .Values.extraDiscoveryRules | indent 2 }}
{{- end }}
}
{{- end }}
