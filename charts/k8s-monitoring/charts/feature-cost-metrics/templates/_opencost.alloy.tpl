{{ define "feature.costMetrics.opencost.allowList" }}
{{- $allowList := list }}
{{ if .Values.opencost.metricsTuning.useDefaultAllowList }}
{{- $allowList = concat $allowList (list "up" "scrape_samples_scraped") (.Files.Get "default-allow-lists/opencost.yaml" | fromYamlArray) -}}
{{ end }}
{{ if .Values.opencost.metricsTuning.includeMetrics }}
{{- $allowList = concat $allowList (list "up" "scrape_samples_scraped") .Values.opencost.metricsTuning.includeMetrics -}}
{{ end }}
{{ $allowList | uniq | toYaml }}
{{ end }}

{{- define "feature.costMetrics.opencost.alloy" }}
{{- $metricAllowList := include "feature.costMetrics.opencost.allowList" . | fromYamlArray }}
{{- $metricDenyList := .Values.opencost.metricsTuning.excludeMetrics }}
{{- $labelSelectors := list }}
{{- if .Values.opencost.labelMatchers }}
  {{- range $label, $value := .Values.opencost.labelMatchers }}
    {{- $labelSelectors = append $labelSelectors (printf "%s=%s" $label $value) }}
  {{- end }}
{{- else if dig "opencost" "deploy" false (.telemetryServices | default dict) }}
  {{- $labelSelectors = append $labelSelectors (printf "app.kubernetes.io/instance=%s" .Release.Name) }}
  {{- $labelSelectors = append $labelSelectors "app.kubernetes.io/name=opencost" }}
{{- end }}

discovery.kubernetes "opencost" {
  role = "pod"
  selectors {
    role = "pod"
    label = {{ $labelSelectors | join "," | quote }}
  }

{{- if .Values.opencost.namespace }}
  namespaces {
    names = [{{ .Values.opencost.namespace | quote }}]
  }
{{- else if dig "opencost" "deploy" false (.telemetryServices | default dict) }}
  namespaces {
    names = [{{ .Release.Namespace | quote }}]
  }
{{- end }}
}

discovery.relabel "opencost" {
  targets = discovery.kubernetes.opencost.targets
  rule {
    source_labels = ["__meta_kubernetes_pod_node_name"]
    action = "replace"
    target_label = "instance"
  }
{{- if .Values.opencost.extraDiscoveryRules }}
{{ .Values.opencost.extraDiscoveryRules | indent 2 }}
{{- end }}
}

prometheus.scrape "opencost" {
  targets      = discovery.relabel.opencost.output
  job_name     = {{ .Values.opencost.jobLabel | quote }}
  honor_labels = true
  scrape_interval = {{ .Values.opencost.scrapeInterval | default .Values.global.scrapeInterval | quote }}
  scrape_timeout = {{ .Values.opencost.scrapeTimeout | default .Values.global.scrapeTimeout | quote }}
  scrape_protocols = {{ .Values.global.scrapeProtocols | toJson }}
  scrape_classic_histograms = {{ .Values.global.scrapeClassicHistograms }}
  scrape_native_histograms = {{ .Values.global.scrapeNativeHistograms }}
  clustering {
    enabled = true
  }
{{- if or $metricAllowList $metricDenyList .Values.opencost.extraMetricProcessingRules }}
  forward_to = [prometheus.relabel.opencost.receiver]
}

prometheus.relabel "opencost" {
  max_cache_size = {{ .Values.opencost.maxCacheSize | default .Values.global.maxCacheSize | int }}
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
{{- if .Values.opencost.extraMetricProcessingRules }}
{{ .Values.opencost.extraMetricProcessingRules | indent 2 }}
{{- end }}
{{- end }}
  forward_to = argument.metrics_destinations.value
}
{{- end }}
