{{- define "feature.clusterMetrics.node_exporter.allowList" }}
{{ if (index .Values "node-exporter").metricsTuning.useDefaultAllowList }}
{{ "default-allow-lists/node-exporter.yaml" | .Files.Get }}
{{ end }}
{{ if (index .Values "node-exporter").metricsTuning.useIntegrationAllowList }}
{{ "default-allow-lists/node-exporter-integration.yaml" | .Files.Get }}
{{ end }}
{{ if (index .Values "node-exporter").metricsTuning.includeMetrics }}
{{ (index .Values "node-exporter").metricsTuning.includeMetrics | toYaml }}
{{ end }}
{{- end }}

{{- define "feature.clusterMetrics.node_exporter.alloy" }}
{{- if (index .Values "node-exporter").enabled }}
{{- $metricAllowList := include "feature.clusterMetrics.node_exporter.allowList" . }}
{{- $metricDenyList := (index .Values "node-exporter").metricsTuning.excludeMetrics }}

import.git "node_exporter" {
  repository = "https://github.com/grafana/alloy-modules.git"
  revision = "main"
  path = "modules/system/node-exporter/metrics.alloy"
  pull_frequency = "15m"
}

node_exporter.kubernetes "targets" {
  label_selectors = [
{{- range $label, $value := (index .Values "node-exporter").labelMatchers }}
    {{ printf "%s=%s" $label $value | quote }},
{{- end }}
{{- if (index .Values "node-exporter").deploy }}
    {{ printf "release=%s" .Release.Name | quote }},
{{- end }}
  ]
}

discovery.relabel "node_exporter" {
  targets = node_exporter.kubernetes.targets.output
  rule {
    source_labels = ["__meta_kubernetes_pod_node_name"]
    action = "replace"
    target_label = "instance"
  }
{{- if (index .Values "node-exporter").extraDiscoveryRules }}
  {{ (index .Values "node-exporter").extraDiscoveryRules | nindent 2 }}
{{- end }}
}

node_exporter.scrape "metrics" {
  targets = discovery.relabel.node_exporter.output
  job_label = "integrations/node_exporter"
  clustering = true
{{- if $metricAllowList }}
  keep_metrics = "up|{{ $metricAllowList | fromYamlArray | join "|" }}"
{{- end }}
{{- if $metricDenyList }}
  drop_metrics = {{ $metricDenyList | join "|" | quote }}
{{- end }}
  scrape_interval = {{ (index .Values "node-exporter").scrapeInterval | default .Values.global.scrapeInterval | quote }}
  max_cache_size = {{ (index .Values "node-exporter").maxCacheSize | default .Values.global.maxCacheSize | int }}
{{- if (index .Values "node-exporter").extraMetricProcessingRules }}
  forward_to = [prometheus.relabel.node_exporter.receiver]
}

prometheus.relabel "node_exporter" {
  max_cache_size = {{ (index .Values "node-exporter").maxCacheSize | default .Values.global.maxCacheSize | int }}

  {{(index .Values "node-exporter").extraMetricProcessingRules}}

{{- end }}
  forward_to = argument.metrics_destinations.value
}
{{- end }}
{{- end }}
