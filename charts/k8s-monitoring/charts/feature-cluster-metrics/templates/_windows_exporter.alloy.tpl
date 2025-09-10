{{- define "feature.clusterMetrics.windows_exporter.allowList" }}
{{- $allowList := list }}
{{ if (index .Values "windows-exporter").metricsTuning.useDefaultAllowList }}
{{- $allowList = concat $allowList (list "up" "scrape_samples_scraped") (.Files.Get "default-allow-lists/windows-exporter.yaml" | fromYamlArray) -}}
{{ end }}
{{ if (index .Values "windows-exporter").metricsTuning.useIntegrationAllowList }}
{{- $allowList = concat $allowList (list "up" "scrape_samples_scraped") (.Files.Get "default-allow-lists/windows-exporter-integration.yaml" | fromYamlArray) -}}
{{ end }}
{{ if (index .Values "windows-exporter").metricsTuning.includeMetrics }}
{{- $allowList = concat $allowList (list "up" "scrape_samples_scraped") (index .Values "windows-exporter").metricsTuning.includeMetrics -}}
{{ end }}
{{ $allowList | uniq | toYaml }}
{{- end }}

{{- define "feature.clusterMetrics.windows_exporter.alloy" }}
{{- if (index .Values "windows-exporter").enabled }}
{{- $metricAllowList := include "feature.clusterMetrics.windows_exporter.allowList" . | fromYamlArray }}
{{- $metricDenyList := (index .Values "windows-exporter").metricsTuning.excludeMetrics }}
{{- $labelSelectors := list }}
{{- range $label, $value := (index .Values "windows-exporter").labelMatchers }}
  {{- $labelSelectors = append $labelSelectors (printf "%s=%s" $label $value) }}
{{- end }}
{{- if (index .Values "windows-exporter").deploy }}
  {{- $labelSelectors = append $labelSelectors (printf "release=%s" .Release.Name) }}
{{- end }}

// Windows Exporter
discovery.kubernetes "windows_exporter_pods" {
  role = "pod"
  selectors {
    role = "pod"
    label = {{ $labelSelectors | join "," | quote }}
  }

{{- if (index .Values "windows-exporter").deploy }}
  namespaces {
    names = [{{ .Release.Namespace | quote }}]
  }
{{- else if (index .Values "windows-exporter").namespace }}
  namespaces {
    names = [{{ (index .Values "windows-exporter").namespace | quote }}]
  }
{{- end }}
{{- include "feature.clusterMetrics.attachNodeMetadata" . | indent 2 }}
}

discovery.relabel "windows_exporter" {
  targets = discovery.kubernetes.windows_exporter_pods.targets

  // keep only the specified metrics port name, and pods that are Running and ready
  rule {
    source_labels = [
      "__meta_kubernetes_pod_container_port_name",
      "__meta_kubernetes_pod_container_init",
      "__meta_kubernetes_pod_phase",
      "__meta_kubernetes_pod_ready",
    ]
    separator = "@"
    regex = "{{ (index .Values "windows-exporter").service.portName }}@false@Running@true"
    action = "keep"
  }

  // Set the instance label to the node name
  rule {
    source_labels = ["__meta_kubernetes_pod_node_name"]
    target_label = "instance"
  }
{{- include "feature.clusterMetrics.nodeDiscoveryRules" . | indent 2 }}
{{- if (index .Values "windows-exporter").extraDiscoveryRules }}
  {{ (index .Values "windows-exporter").extraDiscoveryRules | nindent 2 }}
{{- end }}
}

prometheus.scrape "windows_exporter" {
  targets  = discovery.relabel.windows_exporter.output
  job_name   = {{ (index .Values "windows-exporter").jobLabel | quote }}
  scrape_interval = {{ (index .Values "windows-exporter").scrapeInterval | default .Values.global.scrapeInterval | quote }}
  scrape_timeout = {{ (index .Values "windows-exporter").scrapeTimeout | default .Values.global.scrapeTimeout | quote }}
  scrape_protocols = {{ .Values.global.scrapeProtocols | toJson }}
  scrape_classic_histograms = {{ .Values.global.scrapeClassicHistograms }}
  clustering {
    enabled = true
  }
{{- if or $metricAllowList $metricDenyList (index .Values "windows-exporter").extraMetricProcessingRules }}
  forward_to = [prometheus.relabel.windows_exporter.receiver]
}

prometheus.relabel "windows_exporter" {
  max_cache_size = {{ (index .Values "windows-exporter").maxCacheSize | default .Values.global.maxCacheSize | int }}
{{- if $metricAllowList }}
  rule {
    source_labels = ["__name__"]
    regex = {{ $metricAllowList | join "|" | quote }}
    action = "keep"
  }
{{- end }}
{{- if $metricDenyList }}
  rule {
    source_labels = ["__name__"]
    regex = {{ $metricDenyList | join "|" | quote }}
    action = "drop"
  }
{{- end }}
{{- if (index .Values "windows-exporter").extraMetricProcessingRules }}
{{ (index .Values "windows-exporter").extraMetricProcessingRules | indent 2 }}
{{- end }}
{{- end }}
  forward_to = argument.metrics_destinations.value
}
{{- end }}
{{- end }}
