{{- define "feature.annotationAutodiscovery.services" }}

discovery.kubernetes "services" {
  role = "service"
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
{{- range $k, $v := .Values.services.labelSelectors }}
  {{- if kindIs "slice" $v }}
    {{- $labelSelectors = append $labelSelectors (printf "%s in (%s)" $k (join "," $v)) }}
  {{- else }}
    {{- $labelSelectors = append $labelSelectors (printf "%s=%s" $k $v) }}
  {{- end }}
{{- end }}
{{- if $labelSelectors }}
  selectors {
    role = "service"
    label = {{ $labelSelectors | join "," | quote }}
  }
{{- end }}
}

discovery.relabel "annotation_autodiscovery_services" {
  targets = discovery.kubernetes.services.targets
{{- if .Values.excludeNamespaces }}
  rule {
    source_labels = ["__meta_kubernetes_namespace"]
    regex = "{{ join "|" .Values.excludeNamespaces }}"
    action = "drop"
  }
{{- end }}
  rule {
    source_labels = ["{{ include "service_annotation" .Values.annotations.scrape }}"]
    regex = "true"
    action = "keep"
  }
  rule {
    source_labels = ["__meta_kubernetes_service_name"]
    target_label = "service"
  }
  rule {
    source_labels = ["__meta_kubernetes_namespace"]
    target_label = "namespace"
  }
  rule {
    source_labels = ["{{ include "service_annotation" .Values.annotations.job }}"]
    target_label = "job"
  }
  rule {
    source_labels = ["{{ include "service_annotation" .Values.annotations.instance }}"]
    target_label = "instance"
  }

  // Set metrics path
  rule {
    source_labels = ["{{ include "service_annotation" .Values.annotations.metricsPath }}"]
    target_label = "__metrics_path__"
  }

  // Set metrics scraping URL parameters
  rule {
    action = "labelmap"
    regex = "{{ include "service_annotation" .Values.annotations.metricsParam }}_(.+)"
    replacement = "__param_$1"
  }

  // Choose the service port
  rule {
    source_labels = ["__meta_kubernetes_service_port_name"]
    target_label = "__tmp_port"
  }
  rule {
    source_labels = ["{{ include "service_annotation" .Values.annotations.metricsPortName }}"]
    regex = "(.+)"
    target_label = "__tmp_port"
  }
  rule {
    source_labels = ["__meta_kubernetes_service_port_name"]
    action = "keepequal"
    target_label = "__tmp_port"
  }

  rule {
    source_labels = ["__meta_kubernetes_service_port_number"]
    target_label = "__tmp_port"
  }
  rule {
    source_labels = ["{{ include "service_annotation" .Values.annotations.metricsPortNumber }}"]
    regex = "(.+)"
    target_label = "__tmp_port"
  }
  rule {
    source_labels = ["__meta_kubernetes_service_port_number"]
    action = "keepequal"
    target_label = "__tmp_port"
  }
  rule {
    action = "labeldrop"
    regex = "__tmp_port"
  }

  rule {
    source_labels = ["{{ include "service_annotation" .Values.annotations.metricsScheme }}"]
    regex = "(.+)"
    target_label = "__scheme__"
  }

  rule {
    source_labels = ["{{ include "service_annotation" .Values.annotations.metricsScrapeInterval }}"]
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
    source_labels = ["{{ include "service_annotation" .Values.annotations.metricsScrapeTimeout }}"]
    regex = "(.+)"
    target_label = "__scrape_timeout__"
  }
  rule {
    source_labels = ["__scrape_timeout__"]
    regex = ""
    replacement = {{ .Values.scrapeTimeout | default .Values.global.scrapeTimeout | quote }}
    target_label = "__scrape_timeout__"
  }
{{- range $metricLabel, $k8sLabel := .Values.services.labels }}
  rule {
    source_labels = ["{{ include "service_label" $k8sLabel }}"]
    target_label = "{{ $metricLabel }}"
  }
{{- end }}
{{- if or .Values.pods.staticLabels .Values.pods.staticLabelsFrom }}
  rule {
    target_label = "temp_source"
    replacement = "service"
  }
{{- end }}
{{- if .Values.extraDiscoveryRules }}
{{ .Values.extraDiscoveryRules | indent 4 }}
{{- end }}
}
{{- end -}}
