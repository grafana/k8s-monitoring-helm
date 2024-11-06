{{- define "feature.clusterMetrics.windows_exporter.allowList" }}
{{ if (index .Values "windows-exporter").metricsTuning.useDefaultAllowList }}
{{ "default-allow-lists/windows-exporter.yaml" | .Files.Get }}
{{ end }}
{{ if (index .Values "windows-exporter").metricsTuning.useIntegrationAllowList }}
{{ "default-allow-lists/windows-exporter-integration.yaml" | .Files.Get }}
{{ end }}
{{ if (index .Values "windows-exporter").metricsTuning.includeMetrics }}
{{ (index .Values "windows-exporter").metricsTuning.includeMetrics | toYaml }}
{{ end }}
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

discovery.kubernetes "windows_exporter_pods" {
  role = "pod"
{{- if (index .Values "windows-exporter").deploy }}
  namespaces {
    names = [{{ .Release.Namespace | quote }}]
  }
{{- end }}
  selectors {
    role = "pod"
    label = {{ $labelSelectors | join "," | quote }}
  }
}

discovery.relabel "windows_exporter" {
  targets = discovery.kubernetes.windows_exporter_pods.output
  rule {
    source_labels = ["__meta_kubernetes_pod_node_name"]
    action = "replace"
    target_label = "instance"
  }
{{- if (index .Values "windows-exporter").extraDiscoveryRules }}
  {{ (index .Values "windows-exporter").extraDiscoveryRules | nindent 2 }}
{{- end }}
}

prometheus.scrape "windows_exporter" {
  job_name   = "integrations/windows-exporter"
  targets  = discovery.relabel.windows_exporter.output
  scrape_interval = {{ (index .Values "windows-exporter").scrapeInterval | default .Values.global.scrapeInterval | quote }}
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
    regex = "up|{{ $metricAllowList | join "|" }}"
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
