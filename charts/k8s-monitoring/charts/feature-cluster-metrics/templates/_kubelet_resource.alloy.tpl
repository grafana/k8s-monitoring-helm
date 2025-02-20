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
  targets = discovery.kubernetes.nodes.targets
{{- if eq .Values.kubeletResource.nodeAddressFormat "proxy" }}
  rule {
    target_label = "__address__"
    replacement  = "{{ .Values.cluster.kubernetesAPIService }}"
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
  // set the node label
  rule {
    source_labels = ["__meta_kubernetes_node_name"]
    target_label  = "node"
  }

  // set the app name if specified as metadata labels "app:" or "app.kubernetes.io/name:" or "k8s-app:"
  rule {
    action = "replace"
    source_labels = [
      "__meta_kubernetes_node_label_app_kubernetes_io_name",
      "__meta_kubernetes_node_label_k8s_app",
      "__meta_kubernetes_node_label_app",
    ]
    separator = ";"
    regex = "^(?:;*)?([^;]+).*$"
    replacement = "$1"
    target_label = "app"
  }

  // set a source label
  rule {
    action = "replace"
    replacement = "kubernetes"
    target_label = "source"
  }
{{- if .Values.kubeletResource.extraRelabelingRules }}
{{ .Values.kubeletResource.extraRelabelingRules | indent 2 }}
{{- end }}
}

prometheus.scrape "kubelet_resources" {
  targets  = discovery.relabel.kubelet_resources.output
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
