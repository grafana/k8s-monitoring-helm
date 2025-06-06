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
discovery.relabel "pprof_pods_{{ $currentType }}_default_name" {
  targets = discovery.relabel.pprof_pods.output
  rule {
    source_labels = [{{ $scrapeAnnotation | quote }}]
    regex         = "true"
    action        = "keep"
  }
  rule {
    source_labels = [{{ $portNameAnnotation | quote }}]
    regex         = ""
    action        = "keep"
  }

  rule {
    source_labels = [{{ $schemeAnnotation | quote }}]
    action        = "replace"
    regex         = "(https?)"
    target_label  = "__scheme__"
    replacement   = "$1"
  }
  rule {
    source_labels = [{{ $pathAnnotation | quote }}]
    action        = "replace"
    regex         = "(.+)"
    target_label  = "__profile_path__"
    replacement   = "$1"
  }
  rule {
    source_labels = ["__address__", {{ $portNumberAnnotation | quote }}]
    action        = "replace"
    regex         = "(.+?)(?::\\d+)?;(\\d+)"
    target_label  = "__address__"
    replacement   = "$1:$2"
  }
}

discovery.relabel "pprof_pods_{{ $currentType }}_custom_name" {
  targets = discovery.relabel.pprof_pods.output
  rule {
    source_labels = [{{ $scrapeAnnotation | quote }}]
    regex         = "true"
    action        = "keep"
  }
  rule {
    source_labels = [{{ $portNameAnnotation | quote }}]
    regex         = ""
    action        = "drop"
  }
  rule {
    source_labels = ["__meta_kubernetes_pod_container_port_name"]
    target_label  = {{ $portNameAnnotation | quote }}
    action        = "keepequal"
  }

  rule {
    source_labels = [{{ $schemeAnnotation | quote }}]
    action        = "replace"
    regex         = "(https?)"
    target_label  = "__scheme__"
    replacement   = "$1"
  }
  rule {
    source_labels = [{{ $pathAnnotation | quote }}]
    action        = "replace"
    regex         = "(.+)"
    target_label  = "__profile_path__"
    replacement   = "$1"
  }
  rule {
    source_labels = ["__address__", {{ $portNumberAnnotation | quote }}]
    action        = "replace"
    regex         = "(.+?)(?::\\d+)?;(\\d+)"
    target_label  = "__address__"
    replacement   = "$1:$2"
  }
}

pyroscope.scrape "pyroscope_scrape_{{ $currentType }}" {
  targets = array.concat(discovery.relabel.pprof_pods_{{ $currentType }}_default_name.output, discovery.relabel.pprof_pods_{{ $currentType }}_custom_name.output)

  bearer_token_file = "/var/run/secrets/kubernetes.io/serviceaccount/token"
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
