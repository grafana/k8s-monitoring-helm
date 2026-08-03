{{- define "feature.clusterMetrics.kubeControllerManager.alloy" }}
{{- if or .Values.kubeControllerManager.enabled (and .Values.controlPlane.enabled (not (eq .Values.kubeControllerManager.enabled false))) }}
{{- $metricAllowList := .Values.kubeControllerManager.metricsTuning.includeMetrics }}
{{- $metricDenyList := .Values.kubeControllerManager.metricsTuning.excludeMetrics }}
{{- if eq .Values.kubeControllerManager.discoveryMode "eks-proxy" }}

discovery.relabel "kube_controller_manager" {
  // On Amazon EKS the control plane is managed by AWS and the Kube Controller Manager has no discoverable Pod, so
  // its metrics are scraped from the EKS Control Plane Metrics API served on the Kubernetes API server.
  targets = [{
    __address__      = {{ .Values.global.kubernetesAPIService | default "kubernetes.default.svc.cluster.local:443" | quote }},
    __metrics_path__ = "/apis/metrics.eks.amazonaws.com/v1/kcm/container/metrics",
  }]
{{- if .Values.kubeControllerManager.extraDiscoveryRules }}
{{ .Values.kubeControllerManager.extraDiscoveryRules | indent 2 }}
{{- end }}
} // discovery.relabel "kube_controller_manager"
{{- else }}

discovery.kubernetes "kube_controller_manager" {
  role = "pod"
  namespaces {
    names = ["kube-system"]
  }
  selectors {
    role = "pod"
    label = {{ .Values.kubeControllerManager.selectorLabel | quote }}
  }
} // discovery.kubernetes "kube_controller_manager"

discovery.relabel "kube_controller_manager" {
  targets = discovery.kubernetes.kube_controller_manager.targets
  rule {
    source_labels = ["__meta_kubernetes_pod_ip"]
    replacement = "$1:{{ .Values.kubeControllerManager.port }}"
    target_label = "__address__"
  }
{{- if .Values.kubeControllerManager.extraDiscoveryRules }}
{{ .Values.kubeControllerManager.extraDiscoveryRules | indent 2 }}
{{- end }}
} // discovery.relabel "kube_controller_manager"
{{- end }}

prometheus.scrape "kube_controller_manager" {
  targets           = discovery.relabel.kube_controller_manager.output
  job_name          = {{ .Values.kubeControllerManager.jobLabel | quote }}
  scheme            = "https"
  scrape_interval   = {{ .Values.kubeControllerManager.scrapeInterval | default .Values.global.scrapeInterval | quote }}
  scrape_timeout = {{ .Values.kubeControllerManager.scrapeTimeout | default .Values.global.scrapeTimeout | quote }}
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
{{- if or $metricAllowList $metricDenyList .Values.kubeControllerManager.extraMetricProcessingRules }}
  forward_to = [prometheus.relabel.kube_controller_manager.receiver]
} // prometheus.scrape "kube_controller_manager"

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
  forward_to = argument.metrics_destinations.value
} // prometheus.relabel "kube_controller_manager"
{{- else }}
  forward_to = argument.metrics_destinations.value
} // prometheus.scrape "kube_controller_manager"
{{- end }}
{{- end }}
{{- end }}
