{{- define "feature.clusterMetrics.kubeProxy.alloy" }}
{{- if or .Values.kubeProxy.enabled (and .Values.controlPlane.enabled (not (eq .Values.kubeProxy.enabled false))) }}
{{- $metricAllowList := .Values.kubeProxy.metricsTuning.includeMetrics }}
{{- $metricDenyList := .Values.kubeProxy.metricsTuning.excludeMetrics }}

discovery.kubernetes "kube_proxy" {
  role = "pod"
  namespaces {
    names = ["kube-system"]
  }
  selectors {
    role = "pod"
    label = {{ .Values.kubeProxy.selectorLabel | quote }}
  }
}

discovery.relabel "kube_proxy" {
  targets = discovery.kubernetes.kube_proxy.targets
  rule {
    source_labels = ["__address__"]
    replacement = "$1:{{ .Values.kubeProxy.port }}"
    target_label = "__address__"
  }
{{- if .Values.kubeProxy.extraDiscoveryRules }}
{{ .Values.kubeProxy.extraDiscoveryRules | indent 2 }}
{{- end }}
}

prometheus.scrape "kube_proxy" {
  targets           = discovery.relabel.kube_proxy.output
  job_name          = {{ .Values.kubeProxy.jobLabel | quote }}
  scheme            = "http"
  scrape_interval   = {{ .Values.kubeProxy.scrapeInterval | default .Values.global.scrapeInterval | quote }}
  clustering {
    enabled = true
  }
{{- if or $metricAllowList $metricDenyList .Values.kubeProxy.extraMetricProcessingRules }}
  forward_to = [prometheus.relabel.kube_proxy.receiver]
}

prometheus.relabel "kube_proxy" {
  max_cache_size = {{ .Values.kubeProxy.maxCacheSize | default .Values.global.maxCacheSize | int }}
{{- if $metricAllowList }}
  rule {
    source_labels = ["__name__"]
    regex = "up|scrape_samples_scraped|{{ $metricAllowList | join "|" }}"
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
{{- if .Values.kubeProxy.extraMetricProcessingRules }}
{{ .Values.kubeProxy.extraMetricProcessingRules | indent 2 }}
{{- end }}
{{- end }}
  forward_to = argument.metrics_destinations.value
}
{{- end }}
{{- end }}
