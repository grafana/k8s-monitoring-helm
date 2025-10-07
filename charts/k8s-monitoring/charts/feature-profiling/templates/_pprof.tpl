{{ define "feature.profiling.pprof.alloy" }}
{{- if .Values.pprof.enabled }}
{{- $labelSelectors := list }}
{{- range $k, $v := .Values.pprof.labelSelectors }}
  {{- if kindIs "slice" $v }}
    {{- $labelSelectors = append $labelSelectors (printf "%s in (%s)" $k (join "," $v)) }}
  {{- else }}
    {{- $labelSelectors = append $labelSelectors (printf "%s=%s" $k $v) }}
  {{- end }}
{{- end }}
// Profiles: pprof
discovery.kubernetes "pprof_pods" {
  role = "pod"
  selectors {
    role = "pod"
{{- if $labelSelectors }}
    label = {{ $labelSelectors | join "," | quote }}
{{- end }}
    field = "spec.nodeName=" + sys.env("HOSTNAME")
  }
{{- if .Values.pprof.namespaces }}
  namespaces {
    names = {{ .Values.pprof.namespaces | toJson }}
  }
{{- end }}
}

discovery.relabel "pprof_pods" {
  targets = discovery.kubernetes.pprof_pods.targets
  rule {
    action        = "drop"
    source_labels = ["__meta_kubernetes_pod_phase"]
    regex         = "Pending|Succeeded|Failed|Completed"
  }

  rule {
    regex  = "__meta_kubernetes_pod_label_(.+)"
    action = "labelmap"
  }
  rule {
    source_labels = ["__meta_kubernetes_namespace"]
    target_label  = "namespace"
  }
{{- if .Values.pprof.excludeNamespaces }}
  rule {
    source_labels = ["namespace"]
    regex = "{{ .Values.pprof.excludeNamespaces | join "|" }}"
    action = "drop"
  }
{{- end }}
{{- range $k, $v := .Values.pprof.annotationSelectors }}
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
    target_label  = "pod"
  }
  rule {
    source_labels = ["__meta_kubernetes_pod_container_name"]
    target_label  = "container"
  }

  // Set service_name by choosing the first value found from the following ordered list:
  // - pod.annotation[resource.opentelemetry.io/service.name]
  // - pod.label[app.kubernetes.io/instance]
  // - pod.label[app.kubernetes.io/name]
  // - k8s.container.name
  rule {
    action = "replace"
    source_labels = [
      {{ include "pod_annotation" "resource.opentelemetry.io/service.name" | quote }},
      {{ include "pod_label" "app.kubernetes.io/instance" | quote }},
      {{ include "pod_label" "app.kubernetes.io/name" | quote }},
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
      {{ include "pod_annotation" "resource.opentelemetry.io/service.namespace" | quote }},
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
    source_labels = [{{ include "pod_annotation" "resource.opentelemetry.io/service.instance.id" | quote }}]
    target_label = "service_instance_id"
  }
  rule {
    source_labels = ["service_instance_id", "namespace", "pod", "container"]
    separator = "."
    regex = "^\\.([^.]+\\.[^.]+\\.[^.]+)$"
    target_label = "service_instance_id"
  }

  rule {
    replacement = "alloy/pyroscope.pprof"
    target_label = "source"
  }
{{- if .Values.pprof.extraDiscoveryRules }}
{{ .Values.pprof.extraDiscoveryRules | indent 2 }}
{{- end }}
}

{{- $allProfileTypes := keys .Values.pprof.types | sortAlpha }}
{{ range $currentType := $allProfileTypes }}
{{- if get $.Values.pprof.types $currentType }}
  {{- $scrapeAnnotation := include "pod_annotation" (printf "%s/%s.%s" $.Values.annotations.prefix $currentType $.Values.pprof.annotations.enable) }}
  {{- $portNameAnnotation := include "pod_annotation" (printf "%s/%s.%s" $.Values.annotations.prefix $currentType $.Values.pprof.annotations.portName) }}
  {{- $portNumberAnnotation := include "pod_annotation" (printf "%s/%s.%s" $.Values.annotations.prefix $currentType $.Values.pprof.annotations.portNumber) }}
  {{- $schemeAnnotation := include "pod_annotation" (printf "%s/%s.%s" $.Values.annotations.prefix $currentType $.Values.pprof.annotations.scheme) }}
  {{- $pathAnnotation := include "pod_annotation" (printf "%s/%s.%s" $.Values.annotations.prefix $currentType $.Values.pprof.annotations.path) }}
  {{- $containerAnnotation := include "pod_annotation" (printf "%s/%s.%s" $.Values.annotations.prefix $currentType $.Values.pprof.annotations.container) }}
discovery.relabel "pprof_pods_{{ $currentType }}" {
  targets = discovery.relabel.pprof_pods.output

  // Keep only pods with the scrape annotation set
  rule {
    source_labels = [{{ $scrapeAnnotation | quote }}]
    regex         = "true"
    action        = "keep"
  }

  // Rules to choose the right container
  rule {
    source_labels = ["container"]
    target_label = "__tmp_container"
  }
  rule {
    source_labels = ["{{ $containerAnnotation }}"]
    regex = "(.+)"
    target_label = "__tmp_container"
  }
  rule {
    source_labels = ["container"]
    action = "keepequal"
    target_label = "__tmp_container"
  }
  rule {
    action = "labeldrop"
    regex = "__tmp_container"
  }

  // Rules to choose the right port by name
  // The discovery generates a target for each declared container port of the pod.
  // If the portName annotation has value, keep only the target where the port name matches the one of the annotation.
  rule {
    source_labels = ["__meta_kubernetes_pod_container_port_name"]
    target_label = "__tmp_port"
  }
  rule {
    source_labels = ["{{ $portNameAnnotation }}"]
    regex = "(.+)"
    target_label = "__tmp_port"
  }
  rule {
    source_labels = ["__meta_kubernetes_pod_container_port_name"]
    action = "keepequal"
    target_label = "__tmp_port"
  }
  rule {
    action = "labeldrop"
    regex = "__tmp_port"
  }

  // If the portNumber annotation has a value, override the target address to use it, regardless whether it is
  // one of the declared ports on that Pod.
  rule {
    source_labels = ["{{ $portNumberAnnotation }}", "__meta_kubernetes_pod_ip"]
    regex = "(\\d+);(([A-Fa-f0-9]{1,4}::?){1,7}[A-Fa-f0-9]{1,4})"
    replacement = "[$2]:$1" // IPv6
    target_label = "__address__"
  }
  rule {
    source_labels = ["{{ $portNumberAnnotation }}", "__meta_kubernetes_pod_ip"]
    regex = "(\\d+);((([0-9]+?)(\\.|$)){4})" // IPv4, takes priority over IPv6 when both exists
    replacement = "$2:$1"
    target_label = "__address__"
  }

  rule {
    source_labels = [{{ $schemeAnnotation | quote }}]
    regex         = "(https?)"
    target_label  = "__scheme__"
  }
  rule {
    source_labels = [{{ $pathAnnotation | quote }}]
    regex         = "(.+)"
    target_label  = "__profile_path__"
  }
}

pyroscope.scrape "pyroscope_scrape_{{ $currentType }}" {
  targets = discovery.relabel.pprof_pods_{{ $currentType }}.output
{{ if $.Values.pprof.bearerTokenFile }}
  bearer_token_file = {{ $.Values.pprof.bearerTokenFile | quote }}
{{- end }}
  profiling_config {
    {{- range $type := $allProfileTypes }}
    profile.{{ if eq $type "cpu" }}process_cpu{{ else }}{{ $type }}{{ end }} {
      enabled = {{ if eq $type $currentType }}true{{ else }}false{{ end }}
    }
    {{- end }}
  }

  scrape_interval = {{ $.Values.pprof.scrapeInterval | quote }}
  scrape_timeout = {{ $.Values.pprof.scrapeTimeout | quote }}

  forward_to = argument.profiles_destinations.value
}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
