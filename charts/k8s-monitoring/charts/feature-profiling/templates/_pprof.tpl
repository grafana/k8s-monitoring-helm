{{ define "feature.profiling.pprof.alloy" }}
{{- if .Values.pprof.enabled }}
// Profiles: pprof
discovery.kubernetes "pprof_pods" {
  selectors {
    role = "pod"
    field = "spec.nodeName=" + sys.env("HOSTNAME")
  }
{{- if .Values.pprof.namespaces }}
  namespaces {
    names = {{ .Values.pprof.namespaces | toJson }}
  }
{{- end }}
  role = "pod"
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
  rule {
    source_labels = ["__meta_kubernetes_pod_name"]
    target_label  = "pod"
  }
  rule {
    source_labels = ["__meta_kubernetes_pod_container_name"]
    target_label  = "container"
  }
{{- if .Values.pprof.extraDiscoveryRules }}
{{ .Values.pprof.extraDiscoveryRules | indent 2 }}
{{- end }}
}

{{- $allProfileTypes := keys .Values.pprof.types | sortAlpha }}
{{ range $currentType := $allProfileTypes }}
{{- if get $.Values.pprof.types $currentType }}
discovery.relabel "pprof_pods_{{ $currentType }}_default_name" {
  targets = discovery.relabel.pprof_pods.output
  rule {
    source_labels = ["__meta_kubernetes_pod_annotation_profiles_grafana_com_{{ $currentType }}_scrape"]
    regex         = "true"
    action        = "keep"
  }
  rule {
    source_labels = ["__meta_kubernetes_pod_annotation_profiles_grafana_com_{{ $currentType }}_port_name"]
    regex         = ""
    action        = "keep"
  }

  rule {
    source_labels = ["__meta_kubernetes_pod_annotation_profiles_grafana_com_{{ $currentType }}_scheme"]
    action        = "replace"
    regex         = "(https?)"
    target_label  = "__scheme__"
    replacement   = "$1"
  }
  rule {
    source_labels = ["__meta_kubernetes_pod_annotation_profiles_grafana_com_{{ $currentType }}_path"]
    action        = "replace"
    regex         = "(.+)"
    target_label  = "__profile_path__"
    replacement   = "$1"
  }
  rule {
    source_labels = ["__address__", "__meta_kubernetes_pod_annotation_profiles_grafana_com_{{ $currentType }}_port"]
    action        = "replace"
    regex         = "(.+?)(?::\\d+)?;(\\d+)"
    target_label  = "__address__"
    replacement   = "$1:$2"
  }
}

discovery.relabel "pprof_pods_{{ $currentType }}_custom_name" {
  targets = discovery.relabel.pprof_pods.output
  rule {
    source_labels = ["__meta_kubernetes_pod_annotation_profiles_grafana_com_{{ $currentType }}_scrape"]
    regex         = "true"
    action        = "keep"
  }
  rule {
    source_labels = ["__meta_kubernetes_pod_annotation_profiles_grafana_com_{{ $currentType }}_port_name"]
    regex         = ""
    action        = "drop"
  }
  rule {
    source_labels = ["__meta_kubernetes_pod_container_port_name"]
    target_label  = "__meta_kubernetes_pod_annotation_profiles_grafana_com_{{ $currentType }}_port_name"
    action        = "keepequal"
  }

  rule {
    source_labels = ["__meta_kubernetes_pod_annotation_profiles_grafana_com_{{ $currentType }}_scheme"]
    action        = "replace"
    regex         = "(https?)"
    target_label  = "__scheme__"
    replacement   = "$1"
  }
  rule {
    source_labels = ["__meta_kubernetes_pod_annotation_profiles_grafana_com_{{ $currentType }}_path"]
    action        = "replace"
    regex         = "(.+)"
    target_label  = "__profile_path__"
    replacement   = "$1"
  }
  rule {
    source_labels = ["__address__", "__meta_kubernetes_pod_annotation_profiles_grafana_com_{{ $currentType }}_port"]
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

  forward_to = argument.profiles_destinations.value
}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
