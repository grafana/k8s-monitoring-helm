{{ define "feature.profiling.java.alloy" }}
{{- if .Values.java.enabled }}
{{- $scrapeAnnotation := include "pod_annotation" (printf "%s/java.%s" $.Values.annotations.prefix $.Values.java.annotations.enable) }}
{{- $labelSelectors := list }}
{{- range $k, $v := .Values.java.labelSelectors }}
  {{- if kindIs "slice" $v }}
    {{- $labelSelectors = append $labelSelectors (printf "%s in (%s)" $k (join "," $v)) }}
  {{- else }}
    {{- $labelSelectors = append $labelSelectors (printf "%s=%s" $k $v) }}
  {{- end }}
{{- end }}
// Profiles: Java
discovery.kubernetes "java_pods" {
  role = "pod"
  selectors {
    role = "pod"
{{- if $labelSelectors }}
    label = {{ $labelSelectors | join "," | quote }}
{{- end }}
    field = "spec.nodeName=" + sys.env("HOSTNAME")
  }
{{- if .Values.java.namespaces }}
  namespaces {
    names = {{ .Values.java.namespaces | toJson }}
  }
{{- end }}
}

discovery.relabel "potential_java_pods" {
  targets = discovery.kubernetes.java_pods.targets
  rule {
    source_labels = ["__meta_kubernetes_pod_phase"]
    regex         = "Succeeded|Failed|Completed"
    action        = "drop"
  }
{{- if eq .Values.java.targetingScheme "annotation" }}
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
}

discovery.process "java_pods" {
  join = discovery.relabel.potential_java_pods.output
}

discovery.relabel "java_pods" {
  targets = discovery.process.java_pods.targets
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
{{- range $k, $v := .Values.java.annotationSelectors }}
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
  rule {
    replacement = "alloy/pyroscope.java"
    target_label = "source"
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
