{{ define "feature.clusterMetrics.cadvisor.allowList" }}
{{- $allowList := list }}
{{ if .Values.cadvisor.metricsTuning.useDefaultAllowList }}
{{- $allowList = concat $allowList (list "up" "scrape_samples_scraped") (.Files.Get "default-allow-lists/cadvisor.yaml" | fromYamlArray) -}}
{{ end }}
{{ if .Values.cadvisor.metricsTuning.includeMetrics }}
{{- $allowList = concat $allowList (list "up" "scrape_samples_scraped") .Values.cadvisor.metricsTuning.includeMetrics -}}
{{ end }}
{{ $allowList | uniq | toYaml }}
{{ end }}

{{- define "feature.clusterMetrics.cadvisor.alloy" }}
{{- if .Values.cadvisor.enabled }}
{{- $metricAllowList := include "feature.clusterMetrics.cadvisor.allowList" . | fromYamlArray }}
{{- $metricDenyList := .Values.cadvisor.metricsTuning.excludeMetrics }}

// cAdvisor
discovery.relabel "cadvisor" {
  targets = discovery.kubernetes.nodes.targets
{{- if eq .Values.cadvisor.nodeAddressFormat "proxy" }}
  rule {
    target_label = "__address__"
    replacement  = "{{ .Values.global.kubernetesAPIService | default "kubernetes.default.svc.cluster.local:443" }}"
  }
  rule {
    source_labels = ["__meta_kubernetes_node_name"]
    regex         = "(.+)"
    replacement   = "/api/v1/nodes/${1}/proxy/metrics/cadvisor"
    target_label  = "__metrics_path__"
  }
{{ else if eq .Values.cadvisor.nodeAddressFormat "direct" }}
  rule {
    replacement   = "/metrics/cadvisor"
    target_label  = "__metrics_path__"
  }
{{- end }}
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

{{- if .Values.cadvisor.extraDiscoveryRules }}
{{ .Values.cadvisor.extraDiscoveryRules | indent 2 }}
{{- end }}
}

prometheus.scrape "cadvisor" {
  targets = discovery.relabel.cadvisor.output
  job_name = {{ .Values.cadvisor.jobLabel | quote }}
  scheme = "https"
  scrape_interval = {{ .Values.cadvisor.scrapeInterval | default .Values.global.scrapeInterval | quote }}
  bearer_token_file = "/var/run/secrets/kubernetes.io/serviceaccount/token"

  tls_config {
    ca_file = "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
    insecure_skip_verify = true
    server_name = "kubernetes"
  }

  clustering {
    enabled = true
  }

  forward_to = [prometheus.relabel.cadvisor.receiver]
}

prometheus.relabel "cadvisor" {
  max_cache_size = {{ .Values.cadvisor.maxCacheSize | default .Values.global.maxCacheSize | int }}

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

{{- if .Values.cadvisor.metricsTuning.dropEmptyContainerLabels }}
  // Drop empty container labels, addressing https://github.com/google/cadvisor/issues/2688
  rule {
    source_labels = ["__name__","container"]
    separator = "@"
    regex = "(container_cpu_.*|container_fs_.*|container_memory_.*)@"
    action = "drop"
  }
{{- end }}
{{- if .Values.cadvisor.metricsTuning.dropEmptyImageLabels }}
  // Drop empty image labels, addressing https://github.com/google/cadvisor/issues/2688
  rule {
    source_labels = ["__name__","image"]
    separator = "@"
    regex = "(container_cpu_.*|container_fs_.*|container_memory_.*|container_network_.*)@"
    action = "drop"
  }
{{- end }}
{{- if .Values.cadvisor.metricsTuning.normalizeUnnecessaryLabels }}
  // Normalizing unimportant labels (not deleting to continue satisfying <label>!="" checks)
  {{- range $i := .Values.cadvisor.metricsTuning.normalizeUnnecessaryLabels }}
  {{- range $label := $i.labels }}
  rule {
    source_labels = ["__name__", {{ $label | quote }}]
    separator = "@"
    regex = "{{ $i.metric }}@.*"
    target_label = {{ $label | quote }}
    replacement = "NA"
  }
  {{- end }}
  {{- end }}
{{- end }}
{{- if .Values.cadvisor.metricsTuning.keepPhysicalFilesystemDevices }}
  // Filter out non-physical devices/interfaces
  rule {
    source_labels = ["__name__", "device"]
    separator = "@"
    regex = "container_fs_.*@(/dev/)?({{ join "|" .Values.cadvisor.metricsTuning.keepPhysicalFilesystemDevices }})"
    target_label = "__keepme"
    replacement = "1"
  }
  rule {
    source_labels = ["__name__", "__keepme"]
    separator = "@"
    regex = "container_fs_.*@"
    action = "drop"
  }
  rule {
    source_labels = ["__name__"]
    regex = "container_fs_.*"
    target_label = "__keepme"
    replacement = ""
  }
{{- end }}
{{- if .Values.cadvisor.metricsTuning.keepPhysicalNetworkDevices }}
  rule {
    source_labels = ["__name__", "interface"]
    separator = "@"
    regex = "container_network_.*@({{ join "|" .Values.cadvisor.metricsTuning.keepPhysicalNetworkDevices }})"
    target_label = "__keepme"
    replacement = "1"
  }
  rule {
    source_labels = ["__name__", "__keepme"]
    separator = "@"
    regex = "container_network_.*@"
    action = "drop"
  }
  rule {
    source_labels = ["__name__"]
    regex = "container_network_.*"
    target_label = "__keepme"
    replacement = ""
  }
{{- end }}
{{- if .Values.cadvisor.metricsTuning.includeNamespaces }}
  rule {
    source_labels = ["namespace"]
    regex = {{ .Values.cadvisor.metricsTuning.includeNamespaces | join "|" | quote }}
    action = "keep"
  }
{{- end }}
{{- if .Values.cadvisor.metricsTuning.excludeNamespaces }}
  rule {
    source_labels = ["namespace"]
    regex = {{ .Values.cadvisor.metricsTuning.excludeNamespaces | join "|" | quote }}
    action = "drop"
  }
{{- end }}
{{- if .Values.cadvisor.extraMetricProcessingRules }}
{{ .Values.cadvisor.extraMetricProcessingRules | indent 2 }}
{{- end }}
  forward_to = argument.metrics_destinations.value
}
{{- end }}
{{- end }}
