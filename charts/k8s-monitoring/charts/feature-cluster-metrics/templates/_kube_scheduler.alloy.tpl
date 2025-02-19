{{- define "feature.clusterMetrics.kubeScheduler.alloy" }}
{{- if or .Values.kubeScheduler.enabled (and .Values.controlPlane.enabled (not (eq .Values.kubeScheduler.enabled false))) }}
{{- $metricAllowList := .Values.kubeScheduler.metricsTuning.includeMetrics }}
{{- $metricDenyList := .Values.kubeScheduler.metricsTuning.excludeMetrics }}

discovery.kubernetes "kube_scheduler" {
  role = "pod"
  namespaces {
    names = ["kube-system"]
  }
  selectors {
    role = "pod"
    label = {{ .Values.kubeScheduler.selectorLabel | quote }}
  }
}

discovery.relabel "kube_scheduler" {
  targets = discovery.kubernetes.kube_scheduler.targets
  rule {
    source_labels = ["__address__"]
    replacement = "$1:{{ .Values.kubeScheduler.port }}"
    target_label = "__address__"
  }
{{- if .Values.kubeScheduler.extraDiscoveryRules }}
{{ .Values.kubeScheduler.extraDiscoveryRules | indent 2 }}
{{- end }}
}

prometheus.scrape "kube_scheduler" {
  targets           = discovery.relabel.kube_scheduler.output
  job_name          = {{ .Values.kubeScheduler.jobLabel | quote }}
  scheme            = "https"
  scrape_interval   = {{ .Values.kubeScheduler.scrapeInterval | default .Values.global.scrapeInterval | quote }}
  bearer_token_file = "/var/run/secrets/kubernetes.io/serviceaccount/token"
  tls_config {
    insecure_skip_verify = true
  }
  clustering {
    enabled = true
  }
{{- if or $metricAllowList $metricDenyList .Values.kubeScheduler.extraMetricProcessingRules }}
  forward_to = [prometheus.relabel.kube_scheduler.receiver]
}

prometheus.relabel "kube_scheduler" {
  max_cache_size = {{ .Values.kubeScheduler.maxCacheSize | default .Values.global.maxCacheSize | int }}
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
{{- if .Values.kubeScheduler.extraMetricProcessingRules }}
{{ .Values.kubeScheduler.extraMetricProcessingRules | indent 2 }}
{{- end }}
{{- end }}
  forward_to = argument.metrics_destinations.value
}
{{- end }}
{{- end }}
