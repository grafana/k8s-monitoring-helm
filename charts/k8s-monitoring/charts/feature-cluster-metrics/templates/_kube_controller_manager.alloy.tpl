{{- define "feature.clusterMetrics.kubeControllerManager.alloy" }}
{{- if or .Values.kubeControllerManager.enabled (and .Values.controlPlane.enabled (not (eq .Values.kubeControllerManager.enabled false))) }}
{{- $metricAllowList := .Values.kubeControllerManager.metricsTuning.includeMetrics }}
{{- $metricDenyList := .Values.kubeControllerManager.metricsTuning.excludeMetrics }}

discovery.kubernetes "kube_controller_manager" {
  role = "pod"
  namespaces {
    names = ["kube-system"]
  }
  selectors {
    role = "pod"
    label = {{ .Values.kubeControllerManager.selectorLabel | quote }}
  }
}

discovery.relabel "kube_controller_manager" {
  targets = discovery.kubernetes.kube_controller_manager.targets
  rule {
    source_labels = ["__address__"]
    replacement = "$1:{{ .Values.kubeControllerManager.port }}"
    target_label = "__address__"
  }
{{- if .Values.kubeControllerManager.extraDiscoveryRules }}
{{ .Values.kubeControllerManager.extraDiscoveryRules | indent 2 }}
{{- end }}
}

prometheus.scrape "kube_controller_manager" {
  targets           = discovery.relabel.kube_controller_manager.output
  job_name          = {{ .Values.kubeControllerManager.jobLabel | quote }}
  scheme            = "https"
  scrape_interval   = {{ .Values.kubeControllerManager.scrapeInterval | default .Values.global.scrapeInterval | quote }}
  bearer_token_file = "/var/run/secrets/kubernetes.io/serviceaccount/token"
  tls_config {
    insecure_skip_verify = true
  }
  clustering {
    enabled = true
  }
{{- if or $metricAllowList $metricDenyList .Values.kubeControllerManager.extraMetricProcessingRules }}
  forward_to = [prometheus.relabel.kube_controller_manager.receiver]
}

prometheus.relabel "kube_controller_manager" {
  max_cache_size = {{ .Values.kubeControllerManager.maxCacheSize | default .Values.global.maxCacheSize | int }}
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
{{- if .Values.kubeControllerManager.extraMetricProcessingRules }}
{{ .Values.kubeControllerManager.extraMetricProcessingRules | indent 2 }}
{{- end }}
{{- end }}
  forward_to = argument.metrics_destinations.value
}
{{- end }}
{{- end }}
