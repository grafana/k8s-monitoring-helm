{{- define "feature.clusterMetrics.node_exporter.allowList" }}
{{- $allowList := list }}
{{ if (index .Values "node-exporter").metricsTuning.useDefaultAllowList }}
{{- $allowList = concat $allowList (list "up" "scrape_samples_scraped") (.Files.Get "default-allow-lists/node-exporter.yaml" | fromYamlArray) -}}
{{ end }}
{{ if (index .Values "node-exporter").metricsTuning.useIntegrationAllowList }}
{{- $allowList = concat $allowList (list "up" "scrape_samples_scraped") (.Files.Get "default-allow-lists/node-exporter-integration.yaml" | fromYamlArray) -}}
{{ end }}
{{ if (index .Values "node-exporter").metricsTuning.includeMetrics }}
{{- $allowList = concat $allowList (list "up" "scrape_samples_scraped") (index .Values "node-exporter").metricsTuning.includeMetrics -}}
{{ end }}
{{ $allowList | uniq | toYaml }}
{{- end }}

{{- define "feature.clusterMetrics.node_exporter.alloy" }}
{{- if (index .Values "node-exporter").enabled }}
{{- $metricAllowList := include "feature.clusterMetrics.node_exporter.allowList" . | fromYamlArray }}
{{- $metricDenyList := (index .Values "node-exporter").metricsTuning.excludeMetrics }}
{{- $labelSelectors := list }}
{{- range $label, $value := (index .Values "node-exporter").labelMatchers }}
  {{- $labelSelectors = append $labelSelectors (printf "%s=%s" $label $value) }}
{{- end }}
{{- if (index .Values "node-exporter").deploy }}
  {{- $labelSelectors = append $labelSelectors (printf "release=%s" .Release.Name) }}
{{- end }}

// Node Exporter
discovery.kubernetes "node_exporter" {
  role = "pod"

  selectors {
    role = "pod"
    label = {{ $labelSelectors | join "," | quote }}
  }

{{- if (index .Values "node-exporter").deploy }}
  namespaces {
    names = [{{ .Release.Namespace | quote }}]
  }
{{- else if (index .Values "node-exporter").namespace }}
  namespaces {
    names = [{{ (index .Values "node-exporter").namespace | quote }}]
  }
{{- end }}
}

discovery.relabel "node_exporter" {
  targets = discovery.kubernetes.node_exporter.targets

  // keep only the specified metrics port name, and pods that are Running and ready
  rule {
    source_labels = [
      "__meta_kubernetes_pod_container_port_name",
      "__meta_kubernetes_pod_container_init",
      "__meta_kubernetes_pod_phase",
      "__meta_kubernetes_pod_ready",
    ]
    separator = "@"
    regex = "{{ (index .Values "node-exporter").service.portName }}@false@Running@true"
    action = "keep"
  }

  // Set the instance label to the node name
  rule {
    source_labels = ["__meta_kubernetes_pod_node_name"]
    action = "replace"
    target_label = "instance"
  }

  // set the namespace label
  rule {
    source_labels = ["__meta_kubernetes_namespace"]
    target_label  = "namespace"
  }

  // set the pod label
  rule {
    source_labels = ["__meta_kubernetes_pod_name"]
    target_label  = "pod"
  }

  // set the container label
  rule {
    source_labels = ["__meta_kubernetes_pod_container_name"]
    target_label  = "container"
  }

  // set a workload label
  rule {
    source_labels = [
      "__meta_kubernetes_pod_controller_kind",
      "__meta_kubernetes_pod_controller_name",
    ]
    separator = "/"
    target_label  = "workload"
  }
  // remove the hash from the ReplicaSet
  rule {
    source_labels = ["workload"]
    regex = "(ReplicaSet/.+)-.+"
    target_label  = "workload"
  }

  // set the app name if specified as metadata labels "app:" or "app.kubernetes.io/name:" or "k8s-app:"
  rule {
    action = "replace"
    source_labels = [
      "__meta_kubernetes_pod_label_app_kubernetes_io_name",
      "__meta_kubernetes_pod_label_k8s_app",
      "__meta_kubernetes_pod_label_app",
    ]
    separator = ";"
    regex = "^(?:;*)?([^;]+).*$"
    replacement = "$1"
    target_label = "app"
  }

  // set the component if specified as metadata labels "component:" or "app.kubernetes.io/component:" or "k8s-component:"
  rule {
    action = "replace"
    source_labels = [
      "__meta_kubernetes_pod_label_app_kubernetes_io_component",
      "__meta_kubernetes_pod_label_k8s_component",
      "__meta_kubernetes_pod_label_component",
    ]
    regex = "^(?:;*)?([^;]+).*$"
    replacement = "$1"
    target_label = "component"
  }

  // set a source label
  rule {
    action = "replace"
    replacement = "kubernetes"
    target_label = "source"
  }

{{- if (index .Values "node-exporter").extraDiscoveryRules }}
  {{ (index .Values "node-exporter").extraDiscoveryRules | nindent 2 }}
{{- end }}
}

prometheus.scrape "node_exporter" {
  targets = discovery.relabel.node_exporter.output
  job_name = {{ (index .Values "node-exporter").jobLabel | quote }}
  scrape_interval = {{ (index .Values "node-exporter").scrapeInterval | default .Values.global.scrapeInterval | quote }}
  scheme = {{ (index .Values "node-exporter").service.scheme | quote }}
  bearer_token_file = {{ (index .Values "node-exporter").bearerTokenFile | quote }}
  tls_config {
    insecure_skip_verify = true
  }

  clustering {
    enabled = true
  }

{{- if or $metricAllowList $metricDenyList (index .Values "node-exporter").metricsTuning.dropMetricsForFilesystem (index .Values "node-exporter").extraMetricProcessingRules }}
  forward_to = [prometheus.relabel.node_exporter.receiver]
}

prometheus.relabel "node_exporter" {
  max_cache_size = {{ (index .Values "node-exporter").maxCacheSize | default .Values.global.maxCacheSize | int }}

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
{{- if (index .Values "node-exporter").metricsTuning.dropMetricsForFilesystem }}
  // Drop metrics for certain file systems
  rule {
    source_labels = ["__name__", "fstype"]
    separator = "@"
    regex = "node_filesystem.*@({{ join "|" (index .Values "node-exporter").metricsTuning.dropMetricsForFilesystem }})"
    action = "drop"
  }
{{- end }}

{{- if (index .Values "node-exporter").extraMetricProcessingRules }}
  {{ (index .Values "node-exporter").extraMetricProcessingRules | nindent 2}}
{{- end }}
{{- end }}
  forward_to = argument.metrics_destinations.value
}
{{- end }}
{{- end }}
