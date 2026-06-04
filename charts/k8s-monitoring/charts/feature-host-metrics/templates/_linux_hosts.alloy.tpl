{{- define "feature.hostMetrics.linuxHosts.allowList" }}
{{- $allowList := list }}
{{ if .Values.linuxHosts.metricsTuning.useDefaultAllowList }}
{{- $allowList = concat $allowList (list "up" "scrape_samples_scraped") (.Files.Get "default-allow-lists/node-exporter.yaml" | fromYamlArray) -}}
{{ end }}
{{ if .Values.linuxHosts.metricsTuning.useIntegrationAllowList }}
{{- $allowList = concat $allowList (list "up" "scrape_samples_scraped") (.Files.Get "default-allow-lists/node-exporter-integration.yaml" | fromYamlArray) -}}
{{ end }}
{{ if .Values.linuxHosts.metricsTuning.includeMetrics }}
{{- $allowList = concat $allowList (list "up" "scrape_samples_scraped") .Values.linuxHosts.metricsTuning.includeMetrics -}}
{{ end }}
{{ $allowList | uniq | toYaml }}
{{- end }}

{{- define "feature.hostMetrics.linuxHosts.alloy" }}
{{- if .Values.linuxHosts.enabled }}
{{- $source := .Values.linuxHosts.source | default "node-exporter" }}
{{- $metricAllowList := include "feature.hostMetrics.linuxHosts.allowList" . | fromYamlArray }}
{{- $metricDenyList := .Values.linuxHosts.metricsTuning.excludeMetrics }}
{{- /* The only difference between the two sources is how the targets are discovered: an external Node Exporter
       deployment, or an internal prometheus.exporter.unix run by Alloy. Both expose their targets as
       discovery.relabel.node_exporter.output, which the shared scrape and metrics tuning below consume. */}}
{{- if eq $source "alloy" }}
{{- include "feature.hostMetrics.linuxHosts.discovery.viaAlloy" . }}
{{- else }}
{{- include "feature.hostMetrics.linuxHosts.discovery.viaNodeExporter" . }}
{{- end }}

prometheus.scrape "node_exporter" {
  targets = discovery.relabel.node_exporter.output
  job_name = {{ .Values.linuxHosts.jobLabel | quote }}
  scrape_interval = {{ .Values.linuxHosts.scrapeInterval | default .Values.global.scrapeInterval | quote }}
  scrape_timeout = {{ .Values.linuxHosts.scrapeTimeout | default .Values.global.scrapeTimeout | quote }}
  scrape_protocols = {{ include "helper.scrapeProtocols" . }}
  scrape_classic_histograms = {{ .Values.global.scrapeClassicHistograms }}
  scrape_native_histograms = {{ .Values.global.scrapeNativeHistograms }}
  convert_classic_histograms_to_nhcb = {{ .Values.global.convertClassicHistogramsToNhcb }}
{{- if ne $source "alloy" }}
  scheme = {{ .Values.linuxHosts.scheme | quote }}
  {{- if .Values.linuxHosts.bearerTokenFile }}
  bearer_token_file = {{ .Values.linuxHosts.bearerTokenFile | quote }}
  {{- end }}
  tls_config {
    insecure_skip_verify = true
  }

  clustering {
    enabled = true
  }
{{- end }}

{{- if or $metricAllowList $metricDenyList .Values.linuxHosts.metricsTuning.dropMetricsForFilesystem .Values.linuxHosts.extraMetricProcessingRules }}
  forward_to = [prometheus.relabel.node_exporter.receiver]
} // prometheus.scrape "node_exporter"

prometheus.relabel "node_exporter" {
  max_cache_size = {{ .Values.linuxHosts.maxCacheSize | default .Values.global.maxCacheSize | int }}

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
{{- if .Values.linuxHosts.metricsTuning.dropMetricsForFilesystem }}
  // Drop metrics for certain file systems
  rule {
    source_labels = ["__name__", "fstype"]
    separator = "@"
    regex = "node_filesystem.*@({{ join "|" .Values.linuxHosts.metricsTuning.dropMetricsForFilesystem }})"
    action = "drop"
  }
{{- end }}

{{- if .Values.linuxHosts.extraMetricProcessingRules }}
  {{- .Values.linuxHosts.extraMetricProcessingRules | nindent 2}}
{{- end }}
{{- end }}
  forward_to = argument.metrics_destinations.value
} // prometheus.relabel "node_exporter"
{{- end }}
{{- end }}
