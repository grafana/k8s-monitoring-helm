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

  // set the container runtime as a label
  rule {
    action = "replace"
    source_labels = ["__meta_kubernetes_pod_container_id"]
    regex = "^(\\S+):\\/\\/.+$"
    replacement = "$1"
    target_label = "tmp_container_runtime"
  }

  // set the job label from the k8s.grafana.com/logs.job annotation if it exists
  rule {
    source_labels = ["{{ include "pod_annotation" .Values.annotations.job }}"]
    regex = "(.+)"
    target_label = "job"
  }

  // make all labels on the pod available to the pipeline as labels,
  // they are omitted before write to loki via stage.label_keep unless explicitly set
  rule {
    action = "labelmap"
    regex = "__meta_kubernetes_pod_label_(.+)"
  }

  // make all annotations on the pod available to the pipeline as labels,
  // they are omitted before write to loki via stage.label_keep unless explicitly set
  rule {
    action = "labelmap"
    regex = "__meta_kubernetes_pod_annotation_(.+)"
  }

{{- if .Values.extraDiscoveryRules }}
{{ .Values.extraDiscoveryRules | indent 2 }}
{{- end }}
}
{{- end }}
