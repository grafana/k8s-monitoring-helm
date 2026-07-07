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
{{- $source := .Values.linuxHosts.source | default "node-exporter" }}
{{- $metricAllowList := include "feature.hostMetrics.linuxHosts.allowList" . | fromYamlArray }}
{{- $metricDenyList := .Values.linuxHosts.metricsTuning.excludeMetrics }}
{{- /* The only difference between the two sources is how the targets are discovered: an external Node Exporter
       deployment, or an internal prometheus.exporter.unix run by Alloy. Both expose their targets as
       discovery.relabel.node_exporter.output, which the shared scrape and metrics tuning below consume. */}}
{{- if eq $source "alloy" }}
{{- include "feature.hostMetrics.linuxHosts.discovery.viaAlloy" . }}
{{- else }}
{{- include "feature.hostMetrics.linuxHosts.discovery.viaNodeExporter" . }}
{{- end }}

prometheus.scrape "node_exporter" {
  targets = discovery.relabel.node_exporter.output
  job_name = {{ .Values.linuxHosts.jobLabel | quote }}
  scrape_interval = {{ .Values.linuxHosts.scrapeInterval | default .Values.global.scrapeInterval | quote }}
  scrape_timeout = {{ .Values.linuxHosts.scrapeTimeout | default .Values.global.scrapeTimeout | quote }}
  scrape_protocols = {{ include "helper.scrapeProtocols" . }}
  scrape_classic_histograms = {{ .Values.global.scrapeClassicHistograms }}
  scrape_native_histograms = {{ .Values.global.scrapeNativeHistograms }}
  convert_classic_histograms_to_nhcb = {{ .Values.global.convertClassicHistogramsToNhcb }}
{{- if ne $source "alloy" }}
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
{{- end }}

{{- if or $metricAllowList $metricDenyList .Values.linuxHosts.metricsTuning.dropMetricsForFilesystem .Values.linuxHosts.extraMetricProcessingRules }}
  forward_to = [prometheus.relabel.node_exporter.receiver]
} // prometheus.scrape "node_exporter"

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
  {{- .Values.linuxHosts.extraMetricProcessingRules | nindent 2}}
{{- end }}
{{- end }}
  forward_to = argument.metrics_destinations.value
} // prometheus.relabel "node_exporter"
{{- end }}
{{- end }}

{{- define "feature.hostMetrics.linuxHosts.discovery.viaNodeExporter" }}
{{- $namespace := .Values.linuxHosts.namespace }}
{{- if dig "node-exporter" "deploy" false (.telemetryServices | default dict) }}
  {{- $namespace = (dig "node-exporter" "namespaceOverride" false (.telemetryServices | default dict) | default .Release.Namespace) }}
{{- end }}
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
{{- if $namespace }}
  namespaces {
    names = [{{ $namespace | quote }}]
  }
{{- end }}
{{- include "feature.hostMetrics.attachNodeMetadata" . | trim | nindent 2 }}
} // discovery.kubernetes "node_exporter"

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
    target_label = "instance"
  }

  rule {
    source_labels = ["__meta_kubernetes_namespace"]
    target_label  = "namespace"
  }

  rule {
    source_labels = ["__meta_kubernetes_pod_name"]
    target_label  = "pod"
  }

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

  // Set the app label.
  //
  // Choose the first value found from the following ordered list:
  // - pod.label[app.kubernetes.io/name]
  // - pod.label[k8s-app]
  // - pod.label[app]
  rule {
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

  // Set the component label.
  //
  // Choose the first value found from the following ordered list:
  // - pod.label[app.kubernetes.io/component]
  // - pod.label[k8s-component]
  // - pod.label[component]
  rule {
    source_labels = [
      "__meta_kubernetes_pod_label_app_kubernetes_io_component",
      "__meta_kubernetes_pod_label_k8s_component",
      "__meta_kubernetes_pod_label_component",
    ]
    regex = "^(?:;*)?([^;]+).*$"
    replacement = "$1"
    target_label = "component"
  }

  rule {
    target_label = "source"
    replacement = "kubernetes"
  }

{{- include "feature.hostMetrics.nodeDiscoveryRules" . | trim | nindent 2 }}
{{- if .Values.linuxHosts.extraDiscoveryRules }}
  {{- .Values.linuxHosts.extraDiscoveryRules | nindent 2 }}
{{- end }}
} // discovery.relabel "node_exporter"
{{- end }}

{{- define "feature.hostMetrics.linuxHosts.discovery.viaAlloy" }}

// Linux hosts via Alloy (prometheus.exporter.unix)
prometheus.exporter.unix "node_exporter" {
  rootfs_path = "/host/root"
  procfs_path = "/host/proc"
  sysfs_path  = "/host/sys"
} // prometheus.exporter.unix "node_exporter"

discovery.relabel "node_exporter" {
  targets = prometheus.exporter.unix.node_exporter.targets

  // Set the instance label to the node name
  rule {
    action = "replace"
    target_label = "instance"
    replacement = sys.env("NODE_NAME")
  }

  // Override the job label set by prometheus.exporter.unix to match the Node Exporter source
  rule {
    action = "replace"
    target_label = "job"
    replacement = {{ .Values.linuxHosts.jobLabel | quote }}
  }

  // set a source label
  rule {
    action = "replace"
    replacement = "kubernetes"
    target_label = "source"
  }
{{- if .Values.linuxHosts.extraDiscoveryRules }}
  {{- .Values.linuxHosts.extraDiscoveryRules | nindent 2 }}
{{- end }}
} // discovery.relabel "node_exporter"
{{- end }}
