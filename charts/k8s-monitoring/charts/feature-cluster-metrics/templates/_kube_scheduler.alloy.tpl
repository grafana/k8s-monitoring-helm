{{- define "feature.clusterMetrics.kubeScheduler.alloy" }}
{{- if or .Values.kubeScheduler.enabled (and .Values.controlPlane.enabled (not (eq .Values.kubeScheduler.enabled false))) }}
{{- $metricAllowList := .Values.kubeScheduler.metricsTuning.includeMetrics }}
{{- $metricDenyList := .Values.kubeScheduler.metricsTuning.excludeMetrics }}
{{- if eq .Values.kubeScheduler.discoveryMode "eks-proxy" }}

discovery.relabel "kube_scheduler" {
  // On Amazon EKS the control plane is managed by AWS and the Kube Scheduler has no discoverable Pod, so
  // its metrics are scraped from the EKS Control Plane Metrics API served on the Kubernetes API server.
  targets = [{
    __address__      = {{ .Values.global.kubernetesAPIService | default "kubernetes.default.svc.cluster.local:443" | quote }},
    __metrics_path__ = "/apis/metrics.eks.amazonaws.com/v1/ksh/container/metrics",
  }]
{{- if .Values.kubeScheduler.extraDiscoveryRules }}
{{ .Values.kubeScheduler.extraDiscoveryRules | indent 2 }}
{{- end }}
} // discovery.relabel "kube_scheduler"
{{- else }}

discovery.kubernetes "kube_scheduler" {
  role = "pod"
  namespaces {
    names = ["kube-system"]
  }
  selectors {
    role = "pod"
    label = {{ .Values.kubeScheduler.selectorLabel | quote }}
  }
} // discovery.kubernetes "kube_scheduler"

discovery.relabel "kube_scheduler" {
  targets = discovery.kubernetes.kube_scheduler.targets
  rule {
    source_labels = ["__meta_kubernetes_pod_ip"]
    replacement = "$1:{{ .Values.kubeScheduler.port }}"
    target_label = "__address__"
  }
{{- if .Values.kubeScheduler.extraDiscoveryRules }}
{{ .Values.kubeScheduler.extraDiscoveryRules | indent 2 }}
{{- end }}
} // discovery.relabel "kube_scheduler"
{{- end }}

prometheus.scrape "kube_scheduler" {
  targets           = discovery.relabel.kube_scheduler.output
  job_name          = {{ .Values.kubeScheduler.jobLabel | quote }}
  scheme            = "https"
  scrape_interval   = {{ .Values.kubeScheduler.scrapeInterval | default .Values.global.scrapeInterval | quote }}
  scrape_timeout = {{ .Values.kubeScheduler.scrapeTimeout | default .Values.global.scrapeTimeout | quote }}
  scrape_protocols = {{ include "helper.scrapeProtocols" . }}
  scrape_classic_histograms = {{ .Values.global.scrapeClassicHistograms }}
  scrape_native_histograms = {{ .Values.global.scrapeNativeHistograms }}
  convert_classic_histograms_to_nhcb = {{ .Values.global.convertClassicHistogramsToNhcb }}
  bearer_token_file = "/var/run/secrets/kubernetes.io/serviceaccount/token"
  tls_config {
    insecure_skip_verify = true
  }
  clustering {
    enabled = true
  }
{{- if or $metricAllowList $metricDenyList .Values.kubeScheduler.extraMetricProcessingRules }}
  forward_to = [prometheus.relabel.kube_scheduler.receiver]
} // prometheus.scrape "kube_scheduler"

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
  forward_to = argument.metrics_destinations.value
} // prometheus.relabel "kube_scheduler"
{{- else }}
  forward_to = argument.metrics_destinations.value
} // prometheus.scrape "kube_scheduler"
{{- end }}
{{- end }}
{{- end }}
