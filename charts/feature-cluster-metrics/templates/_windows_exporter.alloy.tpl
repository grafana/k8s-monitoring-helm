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
{{- $metricAllowList := include "feature.clusterMetrics.windows_exporter.allowList" . }}
{{- $metricDenyList := (index .Values "windows-exporter").metricsTuning.excludeMetrics }}

import.git "windows_exporter" {
  repository = "https://github.com/grafana/alloy-modules.git"
  revision = "main"
  path = "modules/system/node-exporter/metrics.alloy"
  pull_frequency = "15m"
}

windows_exporter.kubernetes "targets" {
  label_selectors = [
{{- range $label, $value := (index .Values "windows-exporter").labelMatchers }}
    {{ printf "%s=%s" $label $value | quote }},
{{- end }}
{{- if (index .Values "windows-exporter").deploy }}
    {{ printf "release=%s" .Release.Name | quote }},
{{- end }}
  ]
}

discovery.relabel "windows_exporter" {
  targets = windows_exporter.kubernetes.targets.output
  rule {
    source_labels = ["__meta_kubernetes_pod_node_name"]
    action = "replace"
    target_label = "instance"
  }
{{- if (index .Values "windows-exporter").extraDiscoveryRules }}
  {{ (index .Values "windows-exporter").extraDiscoveryRules | nindent 2 }}
{{- end }}
}

windows_exporter.scrape "metrics" {
  targets = discovery.relabel.windows_exporter.output
  clustering = true
{{- if $metricAllowList }}
  keep_metrics = "up|{{ $metricAllowList | fromYamlArray | join "|" }}"
{{- end }}
{{- if $metricDenyList }}
  drop_metrics = {{ $metricDenyList | join "|" | quote }}
{{- end }}
  scrape_interval = {{ (index .Values "windows-exporter").scrapeInterval | default .Values.global.scrapeInterval | quote }}
  max_cache_size = {{ (index .Values "windows-exporter").maxCacheSize | default .Values.global.maxCacheSize | int }}
{{- if (index .Values "windows-exporter").extraMetricProcessingRules }}
  forward_to = [prometheus.relabel.windows_exporter.receiver]
}

prometheus.relabel "windows_exporter" {
  max_cache_size = {{ (index .Values "windows-exporter").maxCacheSize | default .Values.global.maxCacheSize | int }}

  {{(index .Values "windows-exporter").extraMetricProcessingRules}}

{{- end }}
  forward_to = argument.metrics_destinations.value
}
{{- end }}
{{- end }}
