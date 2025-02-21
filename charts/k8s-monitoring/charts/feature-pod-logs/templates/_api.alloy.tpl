{{- define "feature.podLogs.kubernetesApi.alloy" }}
{{- $labelSelectors := list }}
{{- range $k, $v := .Values.kubernetesApiGathering.labelSelectors }}
  {{- if kindIs "slice" $v }}
    {{- $labelSelectors = append $labelSelectors (printf "%s in (%s)" $k (join "," $v)) }}
  {{- else }}
    {{- $labelSelectors = append $labelSelectors (printf "%s=%s" $k $v) }}
  {{- end }}
{{- end }}
{{- $nodeLabelSelectors := list }}
{{- range $k, $v := .Values.kubernetesApiGathering.nodeLabelSelectors }}
  {{- if kindIs "slice" $v }}
    {{- $nodeLabelSelectors = append $nodeLabelSelectors (printf "%s in (%s)" $k (join "," $v)) }}
  {{- else }}
    {{- $nodeLabelSelectors = append $nodeLabelSelectors (printf "%s=%s" $k $v) }}
  {{- end }}
{{- end }}
discovery.kubernetes "kubernetes_api_pods" {
  role = "pod"
{{- if .Values.kubernetesApiGathering.namespaces }}
  namespaces {
    names = {{ .Values.namespaces | toJson }}
  }
{{- end }}
{{- if or $labelSelectors .Values.kubernetesApiGathering.fieldSelectors }}
  selectors {
    role = "pod"
{{- if $labelSelectors }}
    label = {{ $labelSelectors | join "," | quote }}
{{- end }}
{{- if .Values.kubernetesApiGathering.fieldSelectors }}
    field = {{ .Values.kubernetesApiGathering.fieldSelectors | join "," | quote }}
{{- end }}
  }
{{- end }}
{{- if or $nodeLabelSelectors .Values.kubernetesApiGathering.nodeFieldSelectors }}
  attach_metadata {
    node = true
  }
  selectors {
    role = "node"
{{- if $nodeLabelSelectors }}
    label = {{ $nodeLabelSelectors | join "," | quote }}
{{- end }}
{{- if .Values.kubernetesApiGathering.nodeFieldSelectors }}
    field = {{ .Values.kubernetesApiGathering.nodeFieldSelectors | join "," | quote }}
{{- end }}
  }
{{- end }}
}

discovery.relabel "kubernetes_api_pods" {
  targets = discovery.kubernetes.kubernetes_api_pods.targets
  rule {
    source_labels = ["__meta_kubernetes_namespace"]
    action = "replace"
    target_label = "namespace"
  }
{{- if .Values.kubernetesApiGathering.excludeNamespaces }}
  rule {
    source_labels = ["namespace"]
    regex = "{{ .Values.kubernetesApiGathering.excludeNamespaces | join "|" }}"
    action = "drop"
  }
{{- end }}
  rule {
    source_labels = ["__meta_kubernetes_pod_name"]
    target_label = "pod"
  }
  rule {
    source_labels = ["__meta_kubernetes_pod_container_name"]
    target_label = "container"
  }

  rule {
    source_labels = ["__meta_kubernetes_namespace", "__meta_kubernetes_pod_container_name"]
    separator = "/"
    replacement = "$1"
    target_label = "job"
  }

  // set the container runtime as a label
  rule {
    source_labels = ["__meta_kubernetes_pod_container_id"]
    regex = "^(\\S+):\\/\\/.+$"
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

{{- range $label, $k8sAnnotation := .Values.annotations }}
  rule {
    source_labels = ["{{ include "pod_annotation" $k8sAnnotation }}"]
    target_label = {{ $label | quote }}
  }
{{- end }}
{{- range $label, $k8sLabels := .Values.labels }}
  rule {
    source_labels = ["{{ include "pod_label" $k8sLabels }}"]
    target_label = {{ $label | quote }}
  }
{{- end }}

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

  // set service_namespace
  rule {
    action = "replace"
    source_labels = ["__meta_kubernetes_pod_annotation_resource_opentelemetry_io_service_namespace"]
    target_label = "service_namespace"
  }

  // set deployment_environment and deployment_environment_name
  rule {
    action = "replace"
    source_labels = ["__meta_kubernetes_pod_annotation_resource_opentelemetry_io_deployment_environment_name"]
    target_label = "deployment_environment_name"
  }
  rule {
    action = "replace"
    source_labels = ["__meta_kubernetes_pod_annotation_resource_opentelemetry_io_deployment_environment"]
    target_label = "deployment_environment"
  }

{{- if .Values.kubernetesApiGathering.extraDiscoveryRules }}
{{ .Values.kubernetesApiGathering.extraDiscoveryRules | indent 2 }}
{{- end }}
}

loki.source.kubernetes "kubernetes_api_pods" {
  targets = discovery.relabel.kubernetes_api_pods.output
  forward_to = [loki.process.pod_log_processor.receiver]
}
{{- end }}
