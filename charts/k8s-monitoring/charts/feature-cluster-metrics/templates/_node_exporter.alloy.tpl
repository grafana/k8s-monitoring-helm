{{- define "feature.clusterMetrics.node_exporter.allowList" }}
{{- $allowList := list }}
{{ if (index .Values "node-exporter").metricsTuning.useDefaultAllowList }}
{{- $allowList = concat $allowList (list "up" "scrape_samples_scraped") (.Files.Get "default-allow-lists/node-exporter.yaml" | fromYamlArray) -}}
{{ end }}
{{ if (index .Values "node-exporter").metricsTuning.useIntegrationAllowList }}
{{- $allowList = concat $allowList (list "up" "scrape_samples_scraped") (.Files.Get "default-allow-lists/node-exporter-integration.yaml" | fromYamlArray) -}}
{{ end }}
{{ if (index .Values "node-exporter").metricsTuning.includeMetrics }}
{{- $allowList = concat $allowList (list "up" "scrape_samples_scraped") (index .Values "node-exporter").metricsTuning.includeMetrics -}}
{{ end }}
{{ $allowList | uniq | toYaml }}
{{- end }}

{{- define "feature.clusterMetrics.node_exporter.alloy" }}
{{- if (index .Values "node-exporter").enabled }}
{{- $metricAllowList := include "feature.clusterMetrics.node_exporter.allowList" . | fromYamlArray }}
{{- $metricDenyList := (index .Values "node-exporter").metricsTuning.excludeMetrics }}
{{- include "alloyModules.load" (deepCopy $ | merge (dict "name" "node_exporter" "path" "modules/system/node-exporter/metrics.alloy")) | nindent 0 }}

node_exporter.kubernetes "targets" {
{{- if (index .Values "node-exporter").deploy }}
  namespaces = [{{ .Release.Namespace | quote }}]
{{- else if (index .Values "node-exporter").namespace }}
  namespaces = [{{ (index .Values "node-exporter").namespace | quote }}]
{{- end }}
  port_name = {{ (index .Values "node-exporter").service.portName | quote }}
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
  keep_metrics = {{ $metricAllowList | join "|" | quote }}
{{- end }}
{{- if $metricDenyList }}
  drop_metrics = {{ $metricDenyList | join "|" | quote }}
{{- end }}
  scheme = {{ (index .Values "node-exporter").service.scheme | quote }}
{{- if (index .Values "node-exporter").bearerTokenFile }}
  bearer_token_file = {{ (index .Values "node-exporter").bearerTokenFile | quote }}
{{- end }}
  scrape_interval = {{ (index .Values "node-exporter").scrapeInterval | default .Values.global.scrapeInterval | quote }}
  max_cache_size = {{ (index .Values "node-exporter").maxCacheSize | default .Values.global.maxCacheSize | int }}
{{- if (index .Values "node-exporter").extraMetricProcessingRules }}
  forward_to = [prometheus.relabel.node_exporter.receiver]
}

prometheus.relabel "node_exporter" {
  max_cache_size = {{ (index .Values "node-exporter").maxCacheSize | default .Values.global.maxCacheSize | int }}

{{- if (index .Values "node-exporter").extraMetricProcessingRules }}
  {{ (index .Values "node-exporter").extraMetricProcessingRules | indent 2 }}
{{- end }}

{{- end }}
  forward_to = argument.metrics_destinations.value
}
{{- end }}
{{- end }}
