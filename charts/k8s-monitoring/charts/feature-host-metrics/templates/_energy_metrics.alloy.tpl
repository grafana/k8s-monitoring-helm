{{ define "feature.hostMetrics.energyMetrics.allowList" }}
{{- $allowList := list }}
{{ if .Values.energyMetrics.metricsTuning.useDefaultAllowList }}
{{- $allowList = concat $allowList (list "up" "scrape_samples_scraped") (.Files.Get "default-allow-lists/kepler.yaml" | fromYamlArray) -}}
{{ end }}
{{ if .Values.energyMetrics.metricsTuning.includeMetrics }}
{{- $allowList = concat $allowList (list "up" "scrape_samples_scraped") .Values.energyMetrics.metricsTuning.includeMetrics -}}
{{ end }}
{{ $allowList | uniq | toYaml }}
{{ end }}

{{- define "feature.hostMetrics.energyMetrics.alloy" }}
{{- if .Values.energyMetrics.enabled }}
{{- $metricAllowList := include "feature.hostMetrics.energyMetrics.allowList" . | fromYamlArray }}
{{- $metricDenyList := .Values.energyMetrics.metricsTuning.excludeMetrics }}
{{- $labelSelectors := list }}
{{- if .Values.energyMetrics.labelMatchers }}
  {{- range $k, $v := .Values.energyMetrics.labelMatchers }}
    {{- $labelSelectors = append $labelSelectors (printf "%s=%s" $k $v) }}
  {{- end }}
{{- else if dig "kepler" "deploy" false (.telemetryServices | default dict) }}
  {{- $labelSelectors = append $labelSelectors "app.kubernetes.io/name=kepler" }}
{{- end }}

// Energy metrics via Kepler
discovery.kubernetes "kepler" {
  role = "pod"
  selectors {
    role = "pod"
    label = {{ $labelSelectors | join "," | quote }}
  }

{{- if .Values.energyMetrics.namespace }}
  namespaces {
    names = [{{ .Release.Namespace | quote }}]
  }
{{- else if dig "kepler" "deploy" false (.telemetryServices | default dict) }}
  namespaces {
    names = [{{ .Values.energyMetrics.namespace | quote }}]
  }
{{- end }}
}

discovery.relabel "kepler" {
  targets = discovery.kubernetes.kepler.targets
  rule {
    source_labels = ["__meta_kubernetes_pod_node_name"]
    action = "replace"
    target_label = "instance"
  }
{{- if .Values.energyMetrics.extraDiscoveryRules }}
{{ .Values.energyMetrics.extraDiscoveryRules | indent 2 }}
{{- end }}
}

prometheus.scrape "kepler" {
  targets      = discovery.relabel.kepler.output
  job_name     = {{ .Values.energyMetrics.jobLabel | quote }}
  honor_labels = true
  scrape_interval = {{ .Values.energyMetrics.scrapeInterval | default .Values.global.scrapeInterval | quote }}
  scrape_timeout = {{ .Values.energyMetrics.scrapeTimeout | default .Values.global.scrapeTimeout | quote }}
  scrape_protocols = {{ .Values.global.scrapeProtocols | toJson }}
  scrape_classic_histograms = {{ .Values.global.scrapeClassicHistograms }}
  scrape_native_histograms = {{ .Values.global.scrapeNativeHistograms }}
  clustering {
    enabled = true
  }
{{- if or $metricAllowList $metricDenyList .Values.energyMetrics.extraMetricProcessingRules }}
  forward_to = [prometheus.relabel.kepler.receiver]
}

prometheus.relabel "kepler" {
  max_cache_size = {{ .Values.energyMetrics.maxCacheSize | default .Values.global.maxCacheSize | int }}
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
{{- if .Values.energyMetrics.extraMetricProcessingRules }}
{{ .Values.energyMetrics.extraMetricProcessingRules | indent 2 }}
{{- end }}
{{- end }}
  forward_to = argument.metrics_destinations.value
}
{{- end }}
{{- end }}
