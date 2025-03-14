{{- define "feature.annotationAutodiscovery.pods" }}

discovery.kubernetes "pods" {
  role = "pod"
{{- if .Values.namespaces }}
  namespaces {
    names = {{ .Values.namespaces | toJson }}
  }
{{- end }}
{{- $labelSelectors := list }}
{{- range $k, $v := .Values.labelSelectors }}
  {{- if kindIs "slice" $v }}
    {{- $labelSelectors = append $labelSelectors (printf "%s in (%s)" $k (join "," $v)) }}
  {{- else }}
    {{- $labelSelectors = append $labelSelectors (printf "%s=%s" $k $v) }}
  {{- end }}
{{- end }}
{{- range $k, $v := .Values.pods.labelSelectors }}
  {{- if kindIs "slice" $v }}
    {{- $labelSelectors = append $labelSelectors (printf "%s in (%s)" $k (join "," $v)) }}
  {{- else }}
    {{- $labelSelectors = append $labelSelectors (printf "%s=%s" $k $v) }}
  {{- end }}
{{- end }}
{{- if $labelSelectors }}
  selectors {
    role = "pod"
    label = {{ $labelSelectors | join "," | quote }}
  }
{{- end }}
}

discovery.relabel "annotation_autodiscovery_pods" {
  targets = discovery.kubernetes.pods.targets
{{- if .Values.excludeNamespaces }}
  rule {
    source_labels = ["__meta_kubernetes_namespace"]
    regex = "{{ join "|" .Values.excludeNamespaces }}"
    action = "drop"
  }
{{- end }}
  rule {
    source_labels = ["{{ include "pod_annotation" .Values.annotations.scrape }}"]
    regex = "true"
    action = "keep"
  }
  // Only keep pods that are running, ready, and not init containers.
  rule {
    source_labels = [
      "__meta_kubernetes_pod_phase",
      "__meta_kubernetes_pod_ready",
      "__meta_kubernetes_pod_container_init",
    ]
    regex = "Running;true;false"
    action = "keep"
  }
  rule {
    source_labels = ["__meta_kubernetes_pod_name"]
    target_label = "pod"
  }
  rule {
    source_labels = ["__meta_kubernetes_pod_container_name"]
    target_label = "container"
  }
  rule {
    source_labels = ["__meta_kubernetes_namespace"]
    target_label = "namespace"
  }
  rule {
    source_labels = ["{{ include "pod_annotation" .Values.annotations.job }}"]
    target_label = "job"
  }
  rule {
    source_labels = ["{{ include "pod_annotation" .Values.annotations.instance }}"]
    target_label = "instance"
  }

  // Rules to choose the right container
  rule {
    source_labels = ["container"]
    target_label = "__tmp_container"
  }
  rule {
    source_labels = ["{{ include "pod_annotation" .Values.annotations.metricsContainer }}"]
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

  // Set metrics path
  rule {
    source_labels = ["{{ include "pod_annotation" .Values.annotations.metricsPath }}"]
    regex = "(.+)"
    target_label = "__metrics_path__"
  }

  // Set metrics scraping URL parameters
  rule {
    action = "labelmap"
    regex = "{{ include "pod_annotation" .Values.annotations.metricsParam }}_(.+)"
    replacement = "__param_$1"
  }

  // Choose the pod port
  // The discovery generates a target for each declared container port of the pod.
  // If the metricsPortName annotation has value, keep only the target where the port name matches the one of the annotation.
  rule {
    source_labels = ["__meta_kubernetes_pod_container_port_name"]
    target_label = "__tmp_port"
  }
  rule {
    source_labels = ["{{ include "pod_annotation" .Values.annotations.metricsPortName }}"]
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

  // If the metrics port number annotation has a value, override the target address to use it, regardless whether it is
  // one of the declared ports on that Pod.
  rule {
    source_labels = ["{{ include "pod_annotation" .Values.annotations.metricsPortNumber }}", "__meta_kubernetes_pod_ip"]
    regex = "(\\d+);(([A-Fa-f0-9]{1,4}::?){1,7}[A-Fa-f0-9]{1,4})"
    replacement = "[$2]:$1" // IPv6
    target_label = "__address__"
  }
  rule {
    source_labels = ["{{ include "pod_annotation" .Values.annotations.metricsPortNumber }}", "__meta_kubernetes_pod_ip"]
    regex = "(\\d+);((([0-9]+?)(\\.|$)){4})" // IPv4, takes priority over IPv6 when both exists
    replacement = "$2:$1"
    target_label = "__address__"
  }

  rule {
    source_labels = ["{{ include "pod_annotation" .Values.annotations.metricsScheme }}"]
    regex = "(.+)"
    target_label = "__scheme__"
  }

  rule {
    source_labels = ["{{ include "pod_annotation" .Values.annotations.metricsScrapeInterval }}"]
    regex = "(.+)"
    target_label = "__scrape_interval__"
  }
  rule {
    source_labels = ["__scrape_interval__"]
    regex = ""
    replacement = {{ .Values.scrapeInterval | default .Values.global.scrapeInterval | quote }}
    target_label = "__scrape_interval__"
  }
  rule {
    source_labels = ["{{ include "pod_annotation" .Values.annotations.metricsScrapeTimeout }}"]
    regex = "(.+)"
    target_label = "__scrape_timeout__"
  }
  rule {
    source_labels = ["__scrape_timeout__"]
    regex = ""
    replacement = {{ .Values.scrapeTimeout | default .Values.global.scrapeTimeout | quote }}
    target_label = "__scrape_timeout__"
  }
{{- range $metricLabel, $k8sLabel := .Values.pods.labels }}
  rule {
    source_labels = ["{{ include "pod_label" $k8sLabel }}"]
    target_label = "{{ $metricLabel }}"
  }
{{- end }}
{{- if or .Values.pods.staticLabels .Values.pods.staticLabelsFrom }}
  rule {
    target_label = "temp_source"
    replacement = "pod"
  }
{{- end }}
{{- if .Values.extraDiscoveryRules }}
{{ .Values.extraDiscoveryRules | indent 4 }}
{{- end }}
}
{{- end -}}
