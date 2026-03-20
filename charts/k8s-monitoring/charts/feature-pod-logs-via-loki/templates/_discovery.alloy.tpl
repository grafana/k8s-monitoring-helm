{{- define "feature.podLogsViaLoki.discovery.alloy" }}
{{- $labelSelectors := list }}
{{- range $k, $v := .Values.labelSelectors }}
  {{- if kindIs "slice" $v }}
    {{- $labelSelectors = append $labelSelectors (printf "%s in (%s)" $k (join "," $v)) }}
  {{- else }}
    {{- $labelSelectors = append $labelSelectors (printf "%s=%s" $k $v) }}
  {{- end }}
{{- end }}
{{- $nodeSelectors := list }}
{{- range $k, $v := .Values.nodeSelectors }}
  {{- if kindIs "slice" $v }}
    {{- $nodeSelectors = append $nodeSelectors (printf "%s in (%s)" $k (join "," $v)) }}
  {{- else }}
    {{- $nodeSelectors = append $nodeSelectors (printf "%s=%s" $k $v) }}
  {{- end }}
{{- end }}
discovery.kubernetes "pods" {
  role = "pod"
  selectors {
    role = "pod"
    field = "spec.nodeName=" + sys.env("HOSTNAME")
  }
{{- if .Values.namespaces }}
  namespaces {
    names = {{ .Values.namespaces | toJson }}
  }
{{- end }}
{{- if $labelSelectors }}
    selectors {
      role = "pod"
      label = {{ $labelSelectors | join "," | quote }}
    }
{{- end }}
{{- if $nodeSelectors }}
    selectors {
      role = "node"
      label = {{ $nodeSelectors | join "," | quote }}
    }
{{- end }}
{{- include "feature.podLogsViaLoki.attachNodeMetadata" . | indent 2 }}
}

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

  // explicitly set service_name. if not set, loki will automatically try to populate a default.
  // see https://grafana.com/docs/loki/latest/get-started/labels/#default-labels-for-all-users
  //
  // choose the first value found from the following ordered list:
  // - pod.annotation[resource.opentelemetry.io/service.name]
  // - pod.label[app.kubernetes.io/name]
  // - k8s.container.name
  rule {
    action = "replace"
    source_labels = [
      {{ include "pod_annotation" "resource.opentelemetry.io/service.name" | quote }},
      {{ include "pod_label" "app.kubernetes.io/name" | quote }},
      "__meta_kubernetes_pod_container_name",
    ]
    separator = ";"
    regex = "^(?:;*)?([^;]+).*$"
    replacement = "$1"
    target_label = "service_name"
  }

  // explicitly set service_namespace.
  //
  // choose the first value found from the following ordered list:
  // - pod.annotation[resource.opentelemetry.io/service.namespace]
  // - pod.namespace
  rule {
    action = "replace"
    source_labels = [
      {{ include "pod_annotation" "resource.opentelemetry.io/service.namespace" | quote }},
      "namespace",
    ]
    separator = ";"
    regex = "^(?:;*)?([^;]+).*$"
    replacement = "$1"
    target_label = "service_namespace"
  }

  // explicitly set service_instance_id.
  //
  // choose the first value found from the following ordered list:
  // - pod.annotation[resource.opentelemetry.io/service.instance.id]
  // - concat([k8s.namespace.name, k8s.pod.name, k8s.container.name], '.')
  rule {
    source_labels = [{{ include "pod_annotation" "resource.opentelemetry.io/service.instance.id" | quote }}]
    target_label = "service_instance_id"
  }
  rule {
    source_labels = ["service_instance_id", "namespace", "pod", "container"]
    separator = "."
    regex = "^\\.([^.]+\\.[^.]+\\.[^.]+)$"
    target_label = "service_instance_id"
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

  // Set the pod log path.
  rule {
    source_labels = ["__meta_kubernetes_pod_uid", "__meta_kubernetes_pod_container_name"]
    separator = "/"
    action = "replace"
    replacement = "/var/log/pods/*$1/*.log"
    target_label = "__path__"
  }

  // If kubernetes.io/config.mirror is set, this is a static pod, created by the kubelet.
  // It's logs live on a different path.
  rule {
    source_labels = ["__meta_kubernetes_pod_annotation_kubernetes_io_config_mirror", "__meta_kubernetes_pod_container_name"]
    separator = "/"
    regex = "(.+/.+)"
    action = "replace"
    replacement = "/var/log/pods/*$1/*.log"
    target_label = "__path__"
  }

{{- include "feature.podLogsViaLoki.nodeDiscoveryRules" . | indent 2 }}

{{- if .Values.extraDiscoveryRules }}
{{ .Values.extraDiscoveryRules | indent 2 }}
{{- end }}
}
{{- end }}
