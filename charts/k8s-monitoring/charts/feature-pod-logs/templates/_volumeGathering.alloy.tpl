{{- define "feature.podLogs.volumeGathering.alloy" }}
discovery.kubernetes "volume_gathering_pods" {
  role = "pod"
  selectors {
    role = "pod"
    field = "spec.nodeName=" + sys.env("HOSTNAME")
  }
{{- if .Values.volumeGathering.namespaces }}
  namespaces {
    names = {{ .Values.namespaces | toJson }}
  }
{{- end }}
{{- if or .Values.volumeGathering.labelSelectors .Values.volumeGathering.fieldSelectors }}
  selectors {
    role = "pod"
{{- if .Values.volumeGathering.labelSelectors }}
    label = {{ .Values.volumeGathering.labelSelectors | toJson }}
{{- end }}
{{- if .Values.volumeGathering.fieldSelectors }}
    field = {{ .Values.volumeGathering.fieldSelectors | join "," | quote }}
{{- end }}
  }
{{- end }}
{{- if or .Values.volumeGathering.nodeLabelSelectors .Values.volumeGathering.nodeFieldSelectors }}
  attach_metadata {
    node = true
  }
  selectors {
    role = "node"
{{- if .Values.volumeGathering.nodeLabelSelectors }}
    label = {{ .Values.volumeGathering.nodeLabelSelectors | toJson }}
{{- end }}
{{- if .Values.volumeGathering.nodeFieldSelectors }}
    field = {{ .Values.volumeGathering.nodeFieldSelectors | join "," | quote }}
{{- end }}
  }
{{- end }}
}

discovery.relabel "volume_gathering_pods" {
  targets = discovery.kubernetes.volume_gathering_pods.targets
  rule {
    source_labels = ["__meta_kubernetes_namespace"]
    action = "replace"
    target_label = "namespace"
  }
{{- if .Values.volumeGathering.excludeNamespaces }}
  rule {
    source_labels = ["namespace"]
    regex = "{{ .Values.volumeGathering.excludeNamespaces | join "|" }}"
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

  // set resource attributes
  rule {
    action = "labelmap"
    regex = "__meta_kubernetes_pod_annotation_resource_opentelemetry_io_(.+)"
  }

  rule {
    source_labels = ["__meta_kubernetes_pod_uid", "__meta_kubernetes_pod_container_name"]
    separator = "/"
    replacement = "{{ .Values.volumeGathering.podLogsPath }}/*$1/*.log"
    target_label = "__path__"
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

{{- if .Values.volumeGathering.extraDiscoveryRules }}
{{ .Values.volumeGathering.extraDiscoveryRules | indent 2 }}
{{- end }}
}

local.file_match "volume_gathering_pods" {
  path_targets = discovery.relabel.volume_gathering_pods.output
}

loki.source.file "volume_gathering_pods" {
  targets    = local.file_match.volume_gathering_pods.targets
{{- if .Values.volumeGathering.onlyGatherNewLogLines | default .Values.volumeGatherSettings.onlyGatherNewLogLines }}
  tail_from_end = {{ .Values.volumeGathering.onlyGatherNewLogLines | default .Values.volumeGatherSettings.onlyGatherNewLogLines }}
{{- end }}
  forward_to = [loki.process.pod_log_processor.receiver]
}
{{- end -}}
