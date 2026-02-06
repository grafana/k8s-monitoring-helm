{{- define "feature.profilesReceiver.module" }}
declare "profiles_receiver" {
  argument "profiles_destinations" {
    comment = "Must be a list of profile destinations where collected profiles should be forwarded to"
  }
{{- if .Values.enrich.enabled }}
{{- $labelSelectors := list }}
{{- range $k, $v := .Values.enrich.kubernetes.labelSelectors }}
  {{- if kindIs "slice" $v }}
    {{- $labelSelectors = append $labelSelectors (printf "%s in (%s)" $k (join "," $v)) }}
  {{- else }}
    {{- $labelSelectors = append $labelSelectors (printf "%s=%s" $k $v) }}
  {{- end }}
{{- end }}

  // Profiles: Kubernetes pod discovery for enrichment
  discovery.kubernetes "kubernetes_pods" {
    role = "pod"
{{- if $labelSelectors }}
    selectors {
      role = "pod"
      label = {{ $labelSelectors | join "," | quote }}
    }
{{- end }}
{{- if .Values.enrich.kubernetes.namespaces }}
    namespaces {
      names = {{ .Values.enrich.kubernetes.namespaces | toJson }}
    }
{{- end }}
  }

  discovery.relabel "kubernetes_pods" {
    targets = discovery.kubernetes.kubernetes_pods.targets
    rule {
      source_labels = ["__meta_kubernetes_pod_phase"]
      regex = "Succeeded|Failed|Completed"
      action = "drop"
    }
    rule {
      source_labels = ["__meta_kubernetes_namespace"]
      target_label = "namespace"
    }
{{- if .Values.enrich.kubernetes.excludeNamespaces }}
    rule {
      source_labels = ["namespace"]
      regex = "{{ .Values.enrich.kubernetes.excludeNamespaces | join "|" }}"
      action = "drop"
    }
{{- end }}
{{- range $k, $v := .Values.enrich.kubernetes.annotationSelectors }}
    rule {
      source_labels = [{{ include "feature.profilesReceiver.pod_annotation" $k | quote }}]
    {{- if kindIs "slice" $v }}
      regex = {{ $v | join "|" | quote }}
    {{- else }}
      regex = {{ $v | quote }}
    {{- end }}
      action = "keep"
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
    rule {
      source_labels = ["__meta_kubernetes_pod_ip"]
      target_label = "pod_ip"
    }

    // Set service_name by choosing the first value found from the following ordered list:
    // - pod.annotation[resource.opentelemetry.io/service.name]
    // - pod.label[app.kubernetes.io/instance]
    // - pod.label[app.kubernetes.io/name]
    // - k8s.container.name
    rule {
      action = "replace"
      source_labels = [
        {{ include "feature.profilesReceiver.pod_annotation" "resource.opentelemetry.io/service.name" | quote }},
        {{ include "feature.profilesReceiver.pod_label" "app.kubernetes.io/instance" | quote }},
        {{ include "feature.profilesReceiver.pod_label" "app.kubernetes.io/name" | quote }},
        "container",
      ]
      separator = ";"
      regex = "^(?:;*)?([^;]+).*$"
      replacement = "$1"
      target_label = "service_name"
    }

    // Set service_namespace by choosing the first value found from the following ordered list:
    // - pod.annotation[resource.opentelemetry.io/service.namespace]
    // - pod.namespace
    rule {
      action = "replace"
      source_labels = [
        {{ include "feature.profilesReceiver.pod_annotation" "resource.opentelemetry.io/service.namespace" | quote }},
        "namespace",
      ]
      separator = ";"
      regex = "^(?:;*)?([^;]+).*$"
      replacement = "$1"
      target_label = "service_namespace"
    }

    // Set service_instance_id by choosing the first value found from the following ordered list:
    // - pod.annotation[resource.opentelemetry.io/service.instance.id]
    // - concat([k8s.namespace.name, k8s.pod.name, k8s.container.name], '.')
    rule {
      source_labels = [{{ include "feature.profilesReceiver.pod_annotation" "resource.opentelemetry.io/service.instance.id" | quote }}]
      target_label = "service_instance_id"
    }
    rule {
      source_labels = ["service_instance_id", "namespace", "pod", "container"]
      separator = "."
      regex = "^\\.([^.]+\\.[^.]+\\.[^.]+)$"
      target_label = "service_instance_id"
    }

    rule {
      replacement = "alloy/pyroscope.receive_http"
      target_label = "source"
    }
{{- if .Values.enrich.kubernetes.extraDiscoveryRules }}
{{ .Values.enrich.kubernetes.extraDiscoveryRules | indent 4 }}
{{- end }}
  }
{{- end }}

  pyroscope.receive_http "default" {
    http {
      listen_address = "0.0.0.0"
      listen_port = {{ .Values.port | quote }}
    }
{{- if .Values.enrich.enabled }}
    forward_to = [pyroscope.enrich.metadata.receiver]
{{- else if .Values.profileProcessingRules }}
    forward_to = [pyroscope.relabel.default.receiver]
{{- else }}
    forward_to = argument.profiles_destinations.value
{{- end }}
  }
{{- if .Values.enrich.enabled }}

  pyroscope.enrich "metadata" {
    targets = discovery.relabel.kubernetes_pods.output
    target_match_label = {{ .Values.enrich.targetMatchLabel | quote }}
{{- if .Values.enrich.profilesMatchLabel }}
    profiles_match_label = {{ .Values.enrich.profilesMatchLabel | quote }}
{{- end }}
{{- if .Values.enrich.labelsToCopy }}
    labels_to_copy = {{ .Values.enrich.labelsToCopy | toJson }}
{{- end }}
{{- if .Values.profileProcessingRules }}
    forward_to = [pyroscope.relabel.default.receiver]
{{- else }}
    forward_to = argument.profiles_destinations.value
{{- end }}
  }
{{- end }}
{{- if .Values.profileProcessingRules }}

  pyroscope.relabel "default" {
{{ .Values.profileProcessingRules | indent 4 }}
    forward_to = argument.profiles_destinations.value
  }
{{- end }}
}
{{- end }}
