{{ define "feature.clusterMetrics.kube_state_metrics.allowList" }}
{{- $allowList := list }}
{{ if (index .Values "kube-state-metrics").metricsTuning.useDefaultAllowList }}
{{- $allowList = concat $allowList (list "up" "scrape_samples_scraped") (.Files.Get "default-allow-lists/kube-state-metrics.yaml" | fromYamlArray) -}}
{{ end }}
{{ if (index .Values "kube-state-metrics").metricsTuning.includeMetrics }}
{{- $allowList = concat $allowList (list "up" "scrape_samples_scraped") (index .Values "kube-state-metrics").metricsTuning.includeMetrics -}}
{{ end }}
{{ $allowList | uniq | toYaml }}
{{ end }}

{{- define "feature.clusterMetrics.kube_state_metrics.alloy" }}
{{- if (index .Values "kube-state-metrics").enabled }}
{{- $metricAllowList := include "feature.clusterMetrics.kube_state_metrics.allowList" . | fromYamlArray }}
{{- $metricDenyList := (index .Values "kube-state-metrics").metricsTuning.excludeMetrics }}
{{- $labelSelectors := list }}
{{- range $label, $value := (index .Values "kube-state-metrics").labelMatchers }}
  {{- $labelSelectors = append $labelSelectors (printf "%s=%s" $label $value) }}
{{- end }}
{{- if (index .Values "kube-state-metrics").deploy }}
  {{- $labelSelectors = append $labelSelectors (printf "release=%s" .Release.Name) }}
{{- end }}
discovery.kubernetes "kube_state_metrics" {
  role = "endpoints"

  selectors {
    role = "endpoints"
    label = {{ $labelSelectors | join "," | quote }}
  }
{{- if (index .Values "kube-state-metrics").deploy }}
  namespaces {
    names = [{{ .Release.Namespace | quote }}]
  }
{{- else if (index .Values "kube-state-metrics").namespace }}
  namespaces {
    names = [{{ (index .Values "kube-state-metrics").namespace | quote }}]
  }
{{- end }}
}

discovery.relabel "kube_state_metrics" {
  targets = discovery.kubernetes.kube_state_metrics.targets

  // only keep targets with a matching port name
  rule {
    source_labels = ["__meta_kubernetes_endpoint_port_name"]
    regex = {{ (index .Values "kube-state-metrics").service.portName | quote }}
    action = "keep"
  }

  rule {
    action = "replace"
    replacement = "kubernetes"
    target_label = "source"
  }
  {{- (index .Values "kube-state-metrics").extraDiscoveryRules | nindent 2 }}
}

prometheus.scrape "kube_state_metrics" {
  targets = discovery.relabel.kube_state_metrics.output
  job_name = {{ (index .Values "kube-state-metrics").jobLabel | quote }}
  scrape_interval = {{ (index .Values "kube-state-metrics").scrapeInterval | default .Values.global.scrapeInterval | quote }}
  scheme = {{ (index .Values "kube-state-metrics").service.scheme | quote }}
  bearer_token_file = {{ (index .Values "kube-state-metrics").bearerTokenFile | quote }}
  tls_config {
    insecure_skip_verify = true
  }

  clustering {
    enabled = true
  }

{{- if or $metricAllowList $metricDenyList (index .Values "kube-state-metrics").extraMetricProcessingRules }}
  forward_to = [prometheus.relabel.kube_state_metrics.receiver]
}

prometheus.relabel "kube_state_metrics" {
  max_cache_size = {{ (index .Values "kube-state-metrics").maxCacheSize | default .Values.global.maxCacheSize | int }}

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

{{- if (index .Values "kube-state-metrics").extraMetricProcessingRules }}
  {{ (index .Values "kube-state-metrics").extraMetricProcessingRules | nindent 2}}
{{- end }}
{{- end }}
  forward_to = argument.metrics_destinations.value
}
{{- end }}
{{- end }}
