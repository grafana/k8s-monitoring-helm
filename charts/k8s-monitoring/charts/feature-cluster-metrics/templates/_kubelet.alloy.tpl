{{ define "feature.clusterMetrics.kubelet.allowList" }}
{{- $allowList := list }}
{{ if .Values.kubelet.metricsTuning.useDefaultAllowList }}
{{- $allowList = concat $allowList (list "up" "scrape_samples_scraped") (.Files.Get "default-allow-lists/kubelet.yaml" | fromYamlArray) -}}
{{ end }}
{{ if .Values.kubelet.metricsTuning.includeMetrics }}
{{- $allowList = concat $allowList (list "up" "scrape_samples_scraped") .Values.kubelet.metricsTuning.includeMetrics -}}
{{ end }}
{{ $allowList | uniq | toYaml }}
{{ end }}

{{- define "feature.clusterMetrics.kubelet.alloy" }}
{{- if .Values.kubelet.enabled }}
{{- $metricAllowList := include "feature.clusterMetrics.kubelet.allowList" . | fromYamlArray }}
{{- $metricDenyList := .Values.kubelet.metricsTuning.excludeMetrics }}

// Kubelet
discovery.relabel "kubelet" {
  targets = discovery.relabel.nodes.output
{{- if eq .Values.kubelet.nodeAddressFormat "proxy" }}
  rule {
    target_label = "__address__"
    replacement  = "{{ .Values.global.kubernetesAPIService | default "kubernetes.default.svc.cluster.local:443" }}"
  }
  rule {
    source_labels = ["__meta_kubernetes_node_name"]
    regex         = "(.+)"
    replacement   = "/api/v1/nodes/${1}/proxy/metrics"
    target_label  = "__metrics_path__"
  }
{{- end }}
{{- if .Values.kubelet.extraDiscoveryRules }}
{{ .Values.kubelet.extraDiscoveryRules | indent 2 }}
{{- end }}
}

prometheus.scrape "kubelet" {
  targets  = discovery.relabel.kubelet.output
  job_name = {{ .Values.kubelet.jobLabel | quote }}
  scheme   = "https"
  scrape_interval = {{ .Values.kubelet.scrapeInterval | default .Values.global.scrapeInterval | quote }}
  bearer_token_file = "/var/run/secrets/kubernetes.io/serviceaccount/token"

  tls_config {
    ca_file = "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
    insecure_skip_verify = true
    server_name = "kubernetes"
  }

  clustering {
    enabled = true
  }

  forward_to = [prometheus.relabel.kubelet.receiver]
}

prometheus.relabel "kubelet" {
  max_cache_size = {{ .Values.kubelet.maxCacheSize | default .Values.global.maxCacheSize | int }}

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
{{- if .Values.kubelet.extraMetricProcessingRules }}
  {{ .Values.kubelet.extraMetricProcessingRules | indent 2 }}
{{- end }}

  forward_to = argument.metrics_destinations.value
}
{{- end }}
{{- end }}
