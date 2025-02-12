{{ define "feature.clusterMetrics.kubeletResource.allowList" }}
{{- $allowList := list }}
{{ if .Values.kubeletResource.metricsTuning.useDefaultAllowList }}
{{- $allowList = concat $allowList (list "up" "scrape_samples_scraped") (.Files.Get "default-allow-lists/kubelet_resource.yaml" | fromYamlArray) -}}
{{ end }}
{{ if .Values.kubeletResource.metricsTuning.includeMetrics }}
{{- $allowList = concat $allowList (list "up" "scrape_samples_scraped") .Values.kubeletResource.metricsTuning.includeMetrics -}}
{{ end }}
{{ $allowList | uniq | toYaml }}
{{ end }}

{{- define "feature.clusterMetrics.kubeletResource.alloy" }}
{{- if .Values.kubeletResource.enabled }}
{{- $metricAllowList := include "feature.clusterMetrics.kubeletResource.allowList" . | fromYamlArray }}
{{- $metricDenyList := .Values.kubeletResource.metricsTuning.excludeMetrics }}

// Kubelet Resources
discovery.relabel "kubelet_resources" {
  targets = discovery.relabel.nodes.output
{{- if eq .Values.kubeletResource.nodeAddressFormat "proxy" }}
  rule {
    target_label = "__address__"
    replacement  = "{{ .Values.global.kubernetesAPIService | default "kubernetes.default.svc.cluster.local:443" }}"
  }
  rule {
    source_labels = ["__meta_kubernetes_node_name"]
    regex         = "(.+)"
    replacement   = "/api/v1/nodes/${1}/proxy/metrics/resource"
    target_label  = "__metrics_path__"
  }
{{ else if eq .Values.kubeletResource.nodeAddressFormat "direct" }}
  rule {
    replacement   = "/metrics/resource"
    target_label  = "__metrics_path__"
  }
{{- end }}
{{- if .Values.kubeletResource.extraRelabelingRules }}
{{ .Values.kubeletResource.extraRelabelingRules | indent 2 }}
{{- end }}
}

prometheus.scrape "kubelet_resources" {
  targets = discovery.relabel.kubelet_resources.output
  job_name = {{ .Values.kubeletResource.jobLabel | quote }}
  scheme   = "https"
  scrape_interval = {{ .Values.kubeletResource.scrapeInterval | default .Values.global.scrapeInterval | quote }}
  bearer_token_file = "/var/run/secrets/kubernetes.io/serviceaccount/token"

  tls_config {
    ca_file = "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
    insecure_skip_verify = true
    server_name = "kubernetes"
  }

  clustering {
    enabled = true
  }

  forward_to = [prometheus.relabel.kubelet_resources.receiver]
}

prometheus.relabel "kubelet_resources" {
  max_cache_size = {{ .Values.kubeletResource.maxCacheSize | default .Values.global.maxCacheSize | int }}

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
{{- if .Values.kubeletResource.extraMetricProcessingRules }}
  {{ .Values.kubeletResource.extraMetricProcessingRules | indent 2 }}
{{- end }}

  forward_to = argument.metrics_destinations.value
}
{{- end }}
{{- end }}
