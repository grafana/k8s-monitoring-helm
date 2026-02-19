{{- define "feature.hostMetrics.windowsHosts.allowList" }}
{{- $allowList := list }}
{{ if .Values.windowsHosts.metricsTuning.useDefaultAllowList }}
{{- $allowList = concat $allowList (list "up" "scrape_samples_scraped") (.Files.Get "default-allow-lists/windows-exporter.yaml" | fromYamlArray) -}}
{{ end }}
{{ if .Values.windowsHosts.metricsTuning.useIntegrationAllowList }}
{{- $allowList = concat $allowList (list "up" "scrape_samples_scraped") (.Files.Get "default-allow-lists/windows-exporter-integration.yaml" | fromYamlArray) -}}
{{ end }}
{{ if .Values.windowsHosts.metricsTuning.includeMetrics }}
{{- $allowList = concat $allowList (list "up" "scrape_samples_scraped") .Values.windowsHosts.metricsTuning.includeMetrics -}}
{{ end }}
{{ $allowList | uniq | toYaml }}
{{- end }}

{{- define "feature.hostMetrics.windowsHosts.alloy" }}
{{- if .Values.windowsHosts.enabled }}
{{- $metricAllowList := include "feature.hostMetrics.windowsHosts.allowList" . | fromYamlArray }}
{{- $metricDenyList := .Values.windowsHosts.metricsTuning.excludeMetrics }}
{{- $labelSelectors := list }}
{{- if .Values.windowsHosts.labelMatchers }}
  {{- range $label, $value := .Values.windowsHosts.labelMatchers }}
    {{- $labelSelectors = append $labelSelectors (printf "%s=%s" $label $value) }}
  {{- end }}
{{- else if dig "windows-exporter" "deploy" false (.telemetryServices | default dict) }}
  {{- $labelSelectors = append $labelSelectors (printf "release=%s" .Release.Name) }}
  {{- $labelSelectors = append $labelSelectors "app.kubernetes.io/name=windows-exporter" }}
{{- end }}

// Windows hosts via Windows Exporter
discovery.kubernetes "windows_exporter_pods" {
  role = "pod"
  selectors {
    role = "pod"
    label = {{ $labelSelectors | join "," | quote }}
  }

{{- if .Values.windowsHosts.namespace }}
  namespaces {
    names = [{{ .Values.windowsHosts.namespace | quote }}]
  }
{{- else if dig "windows-exporter" "deploy" false (.telemetryServices | default dict) }}
  namespaces {
    names = [{{ .Release.Namespace | quote }}]
  }
{{- end }}
}

discovery.relabel "windows_exporter" {
  targets = discovery.kubernetes.windows_exporter_pods.targets

  // keep only the specified metrics port name, and pods that are Running and ready
  rule {
    source_labels = [
      "__meta_kubernetes_pod_container_init",
      "__meta_kubernetes_pod_phase",
      "__meta_kubernetes_pod_ready",
    ]
    separator = "@"
    regex = "false@Running@true"
    action = "keep"
  }

  // Set the instance label to the node name
  rule {
    source_labels = ["__meta_kubernetes_pod_node_name"]
    target_label = "instance"
  }
{{- if .Values.windowsHosts.extraDiscoveryRules }}
  {{ .Values.windowsHosts.extraDiscoveryRules | nindent 2 }}
{{- end }}
}

prometheus.scrape "windows_exporter" {
  targets  = discovery.relabel.windows_exporter.output
  job_name   = {{ .Values.windowsHosts.jobLabel | quote }}
  scrape_interval = {{ .Values.windowsHosts.scrapeInterval | default .Values.global.scrapeInterval | quote }}
  scrape_timeout = {{ .Values.windowsHosts.scrapeTimeout | default .Values.global.scrapeTimeout | quote }}
  scrape_protocols = {{ .Values.global.scrapeProtocols | toJson }}
  scrape_classic_histograms = {{ .Values.global.scrapeClassicHistograms }}
  scrape_native_histograms = {{ .Values.global.scrapeNativeHistograms }}
  clustering {
    enabled = true
  }
{{- if or $metricAllowList $metricDenyList .Values.windowsHosts.extraMetricProcessingRules }}
  forward_to = [prometheus.relabel.windows_exporter.receiver]
}

prometheus.relabel "windows_exporter" {
  max_cache_size = {{ .Values.windowsHosts.maxCacheSize | default .Values.global.maxCacheSize | int }}
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
{{- if .Values.windowsHosts.extraMetricProcessingRules }}
{{ .Values.windowsHosts.extraMetricProcessingRules | indent 2 }}
{{- end }}
{{- end }}
  forward_to = argument.metrics_destinations.value
}
{{- end }}
{{- end }}
