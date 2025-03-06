{{- define "feature.clusterMetrics.apiServer.alloy" }}
{{- if or .Values.apiServer.enabled (and .Values.controlPlane.enabled (not (eq .Values.apiServer.enabled false))) }}
{{- $metricAllowList := .Values.apiServer.metricsTuning.includeMetrics }}
{{- $metricDenyList := .Values.apiServer.metricsTuning.excludeMetrics }}

discovery.kubernetes "apiserver" {
  role = "endpoints"

  selectors {
    role = "endpoints"
    field = "metadata.name=kubernetes"
  }

  namespaces {
    names = ["default"]
  }
}

discovery.relabel "apiserver" {
  targets = discovery.kubernetes.apiserver.targets

  rule {
    source_labels = ["__meta_kubernetes_endpoint_port_name"]
    regex = "https"
    action = "keep"
  }

  rule {
    source_labels = ["__meta_kubernetes_namespace"]
    target_label = "namespace"
  }

  rule {
    source_labels = ["__meta_kubernetes_service_name"]
    target_label = "service"
  }

  rule {
    replacement = "kubernetes"
    target_label = "source"
  }

{{- if .Values.apiServer.extraDiscoveryRules }}
  {{ .Values.apiServer.extraDiscoveryRules | indent 2 }}
{{- end }}
}

prometheus.scrape "apiserver" {
  targets = discovery.relabel.apiserver.output
  job_name = {{ .Values.apiServer.jobLabel | quote }}
  scheme = "https"
  scrape_interval = {{ .Values.apiServer.scrapeInterval | default .Values.global.scrapeInterval | quote }}
  bearer_token_file = "/var/run/secrets/kubernetes.io/serviceaccount/token"

  tls_config {
    ca_file = "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
    insecure_skip_verify = false
    server_name = "kubernetes"
  }

  clustering {
    enabled = true
  }
{{- if or $metricAllowList $metricDenyList .Values.apiServer.extraMetricProcessingRules }}

  forward_to = [prometheus.relabel.apiserver.receiver]
}

prometheus.relabel "apiserver" {
  max_cache_size = {{ .Values.apiServer.maxCacheSize | default .Values.global.maxCacheSize | int }}

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

{{- if .Values.apiServer.extraMetricProcessingRules }}
  {{ .Values.apiServer.extraMetricProcessingRules | indent 2 }}
{{- end }}

{{- end }}
  forward_to = argument.metrics_destinations.value
}
{{- end }}
{{- end }}
