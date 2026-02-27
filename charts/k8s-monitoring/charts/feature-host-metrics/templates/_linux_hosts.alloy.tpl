{{- define "feature.hostMetrics.linuxHosts.allowList" }}
{{- $allowList := list }}
{{ if .Values.linuxHosts.metricsTuning.useDefaultAllowList }}
{{- $allowList = concat $allowList (list "up" "scrape_samples_scraped") (.Files.Get "default-allow-lists/node-exporter.yaml" | fromYamlArray) -}}
{{ end }}
{{ if .Values.linuxHosts.metricsTuning.useIntegrationAllowList }}
{{- $allowList = concat $allowList (list "up" "scrape_samples_scraped") (.Files.Get "default-allow-lists/node-exporter-integration.yaml" | fromYamlArray) -}}
{{ end }}
{{ if .Values.linuxHosts.metricsTuning.includeMetrics }}
{{- $allowList = concat $allowList (list "up" "scrape_samples_scraped") .Values.linuxHosts.metricsTuning.includeMetrics -}}
{{ end }}
{{ $allowList | uniq | toYaml }}
{{- end }}

{{- define "feature.hostMetrics.linuxHosts.alloy" }}
{{- if .Values.linuxHosts.enabled }}
{{- $metricAllowList := include "feature.hostMetrics.linuxHosts.allowList" . | fromYamlArray }}
{{- $metricDenyList := .Values.linuxHosts.metricsTuning.excludeMetrics }}
{{- $labelSelectors := list }}
{{- if .Values.linuxHosts.labelMatchers }}
  {{- range $label, $value := .Values.linuxHosts.labelMatchers }}
    {{- $labelSelectors = append $labelSelectors (printf "%s=%s" $label $value) }}
  {{- end }}
{{- else if dig "node-exporter" "deploy" false (.telemetryServices | default dict) }}
  {{- $labelSelectors = append $labelSelectors (printf "release=%s" .Release.Name) }}
  {{- $labelSelectors = append $labelSelectors "app.kubernetes.io/name=node-exporter" }}
{{- end }}

// Linux hosts via Node Exporter
discovery.kubernetes "node_exporter" {
  role = "pod"

  selectors {
    role = "pod"
    label = {{ $labelSelectors | join "," | quote }}
  }

{{- if .Values.linuxHosts.namespace }}
  namespaces {
    names = [{{ .Values.linuxHosts.namespace | quote }}]
  }
{{- else if dig "node-exporter" "deploy" false (.telemetryServices | default dict) }}
  namespaces {
    names = [{{ .Release.Namespace | quote }}]
  }
{{- end }}
}

discovery.relabel "node_exporter" {
  targets = discovery.kubernetes.node_exporter.targets

  // keep only the specified metrics port name, and pods that are Running and ready
  rule {
    source_labels = [
      "__meta_kubernetes_pod_container_init",
      "__meta_kubernetes_pod_phase",
      "__meta_kubernetes_pod_ready",
    ]
    separator = "@"
    regex = "false@Running@true"
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

{{- if .Values.linuxHosts.extraDiscoveryRules }}
  {{ .Values.linuxHosts.extraDiscoveryRules | nindent 2 }}
{{- end }}
}

prometheus.scrape "node_exporter" {
  targets = discovery.relabel.node_exporter.output
  job_name = {{ .Values.linuxHosts.jobLabel | quote }}
  scrape_interval = {{ .Values.linuxHosts.scrapeInterval | default .Values.global.scrapeInterval | quote }}
  scrape_timeout = {{ .Values.linuxHosts.scrapeTimeout | default .Values.global.scrapeTimeout | quote }}
  scrape_protocols = {{ .Values.global.scrapeProtocols | toJson }}
  scrape_classic_histograms = {{ .Values.global.scrapeClassicHistograms }}
  scrape_native_histograms = {{ .Values.global.scrapeNativeHistograms }}
  scheme = {{ .Values.linuxHosts.scheme | quote }}
  {{- if .Values.linuxHosts.bearerTokenFile }}
  bearer_token_file = {{ .Values.linuxHosts.bearerTokenFile | quote }}
  {{- end }}
  tls_config {
    insecure_skip_verify = true
  }

  clustering {
    enabled = true
  }

{{- if or $metricAllowList $metricDenyList .Values.linuxHosts.metricsTuning.dropMetricsForFilesystem .Values.linuxHosts.extraMetricProcessingRules }}
  forward_to = [prometheus.relabel.node_exporter.receiver]
}

prometheus.relabel "node_exporter" {
  max_cache_size = {{ .Values.linuxHosts.maxCacheSize | default .Values.global.maxCacheSize | int }}

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
{{- if .Values.linuxHosts.metricsTuning.dropMetricsForFilesystem }}
  // Drop metrics for certain file systems
  rule {
    source_labels = ["__name__", "fstype"]
    separator = "@"
    regex = "node_filesystem.*@({{ join "|" .Values.linuxHosts.metricsTuning.dropMetricsForFilesystem }})"
    action = "drop"
  }
{{- end }}

{{- if .Values.linuxHosts.extraMetricProcessingRules }}
  {{ .Values.linuxHosts.extraMetricProcessingRules | nindent 2}}
{{- end }}
{{- end }}
  forward_to = argument.metrics_destinations.value
}
{{- end }}
{{- end }}
