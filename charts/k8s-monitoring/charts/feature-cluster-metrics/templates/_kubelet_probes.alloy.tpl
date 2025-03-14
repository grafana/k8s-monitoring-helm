{{ define "feature.clusterMetrics.kubeletProbes.allowList" }}
{{- $allowList := list }}
{{ if .Values.kubeletProbes.metricsTuning.useDefaultAllowList }}
{{- $allowList = concat $allowList (list "up" "scrape_samples_scraped") (.Files.Get "default-allow-lists/kubelet_probes.yaml" | fromYamlArray) -}}
{{ end }}
{{ if .Values.kubeletProbes.metricsTuning.includeMetrics }}
{{- $allowList = concat $allowList (list "up" "scrape_samples_scraped") .Values.kubeletProbes.metricsTuning.includeMetrics -}}
{{ end }}
{{ $allowList | uniq | toYaml }}
{{ end }}

{{- define "feature.clusterMetrics.kubeletProbes.alloy" }}
{{- if .Values.kubeletProbes.enabled }}
{{- $metricAllowList := include "feature.clusterMetrics.kubeletProbes.allowList" . | fromYamlArray }}
{{- $metricDenyList := .Values.kubeletProbes.metricsTuning.excludeMetrics }}

// Kubelet Probes
discovery.relabel "kubelet_probes" {
  targets = discovery.kubernetes.nodes.targets
{{- if eq .Values.kubeletProbes.nodeAddressFormat "proxy" }}
  rule {
    target_label = "__address__"
    replacement  = "{{ .Values.global.kubernetesAPIService | default "kubernetes.default.svc.cluster.local:443" }}"
  }
  rule {
    source_labels = ["__meta_kubernetes_node_name"]
    regex         = "(.+)"
    replacement   = "/api/v1/nodes/${1}/proxy/metrics/probes"
    target_label  = "__metrics_path__"
  }
{{ else if eq .Values.kubeletProbes.nodeAddressFormat "direct" }}
  rule {
    replacement   = "/metrics/probes"
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
{{- if .Values.kubeletProbes.extraRelabelingRules }}
{{ .Values.kubeletProbes.extraRelabelingRules | indent 2 }}
{{- end }}
}

prometheus.scrape "kubelet_probes" {
  targets  = discovery.relabel.kubelet_probes.output
  job_name = {{ .Values.kubeletProbes.jobLabel | quote }}
  scheme   = "https"
  scrape_interval = {{ .Values.kubeletProbes.scrapeInterval | default .Values.global.scrapeInterval | quote }}
  bearer_token_file = "/var/run/secrets/kubernetes.io/serviceaccount/token"

  tls_config {
    ca_file = "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
    insecure_skip_verify = true
    server_name = "kubernetes"
  }

  clustering {
    enabled = true
  }

  forward_to = [prometheus.relabel.kubelet_probes.receiver]
}

prometheus.relabel "kubelet_probes" {
  max_cache_size = {{ .Values.kubeletProbes.maxCacheSize | default .Values.global.maxCacheSize | int }}

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
{{- if .Values.kubeletProbes.extraMetricProcessingRules }}
  {{ .Values.kubeletProbes.extraMetricProcessingRules | indent 2 }}
{{- end }}

  forward_to = argument.metrics_destinations.value
}
{{- end }}
{{- end }}
