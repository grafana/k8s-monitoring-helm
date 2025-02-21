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

  // explicitly set service_name. if not set, loki will automatically try to populate a default.
  // see https://grafana.com/docs/loki/latest/get-started/labels/#default-labels-for-all-users
  //
  // choose the first value found from the following ordered list:
  // - pod.annotation[resource.opentelemetry.io/service.name]
  // - pod.label[app.kubernetes.io/name]
  // - k8s.pod.name
  // - k8s.container.name
  rule {
    action = "replace"
    source_labels = [
      "__meta_kubernetes_pod_annotation_resource_opentelemetry_io_service_name",
      "__meta_kubernetes_pod_label_app_kubernetes_io_name",
      "__meta_kubernetes_pod_name",
      "__meta_kubernetes_pod_container_name",
    ]
    separator = ";"
    regex = "^(?:;*)?([^;]+).*$"
    replacement = "$1"
    target_label = "service_name"
  }

  // set resource attributes
  rule {
    action = "labelmap"
    regex = "__meta_kubernetes_pod_annotation_resource_opentelemetry_io_(.+)"
  }

{{- range $label, $k8sAnnotation := .Values.annotations }}
  rule {
    source_labels = ["{{ include "pod_annotation" $k8sAnnotation }}"]
    regex = "(.+)"
    target_label = {{ $label | quote }}
  }
{{- end }}
{{- range $label, $k8sLabels := .Values.labels }}
  rule {
    source_labels = ["{{ include "pod_label" $k8sLabels }}"]
    regex = "(.+)"
    target_label = {{ $label | quote }}
  }
{{- end }}

{{- if .Values.extraDiscoveryRules }}
{{ .Values.extraDiscoveryRules | indent 2 }}
{{- end }}
}
{{- end }}
