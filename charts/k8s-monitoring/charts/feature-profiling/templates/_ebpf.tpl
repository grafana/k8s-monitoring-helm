{{ define "feature.profiling.ebpf.alloy" }}
{{- if .Values.ebpf.enabled }}
{{- $scrapeAnnotation := include "pod_annotation" (printf "%s/cpu.ebpf.%s" $.Values.annotations.prefix $.Values.ebpf.annotations.enable) }}
{{- $labelSelectors := list }}
{{- range $k, $v := .Values.ebpf.labelSelectors }}
  {{- if kindIs "slice" $v }}
    {{- $labelSelectors = append $labelSelectors (printf "%s in (%s)" $k (join "," $v)) }}
  {{- else }}
    {{- $labelSelectors = append $labelSelectors (printf "%s=%s" $k $v) }}
  {{- end }}
{{- end }}
// Profiles: eBPF
discovery.kubernetes "ebpf_pods" {
  role = "pod"
  selectors {
    role = "pod"
{{- if $labelSelectors }}
    label = {{ $labelSelectors | join "," | quote }}
{{- end }}
    field = "spec.nodeName=" + sys.env("HOSTNAME")
  }
{{- if .Values.ebpf.namespaces }}
  namespaces {
    names = {{ .Values.ebpf.namespaces | toJson }}
  }
{{- end }}
}

discovery.relabel "ebpf_pods" {
  targets = discovery.kubernetes.ebpf_pods.targets
  rule {
    source_labels = ["__meta_kubernetes_pod_phase"]
    regex = "Succeeded|Failed|Completed"
    action = "drop"
  }
{{- if eq .Values.ebpf.targetingScheme "annotation" }}
  rule {
    source_labels = [{{ $scrapeAnnotation | quote }}]
    regex         = "true"
    action        = "keep"
  }
{{- else }}
  rule {
    source_labels = [{{ $scrapeAnnotation | quote }}]
    regex         = "false"
    action        = "drop"
  }
{{- end }}
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
{{- range $k, $v := .Values.ebpf.annotationSelectors }}
  rule {
    source_labels = [{{ include "pod_annotation" $k | quote }}]
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
  // provide arbitrary service_name label, otherwise it will be set to {__meta_kubernetes_namespace}/{__meta_kubernetes_pod_container_name}
  rule {
    source_labels = ["__meta_kubernetes_namespace", "__meta_kubernetes_pod_container_name"]
    separator = "@"
    regex = "(.*)@(.*)"
    replacement = "ebpf/${1}/${2}"
    target_label = "service_name"
  }
  rule {
    replacement = "alloy/pyroscope.ebpf"
    target_label = "source"
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
