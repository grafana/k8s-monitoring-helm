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

kubernetes.cadvisor "scrape" {
  clustering = true
  job_label = {{ .Values.cadvisor.jobLabel | quote }}
{{- if $metricAllowList }}
  keep_metrics = {{ $metricAllowList | join "|" | quote }}
{{- end }}
{{- if $metricDenyList }}
  drop_metrics = {{ $metricDenyList | join "|" | quote }}
{{- end }}
  scrape_interval = {{ .Values.cadvisor.scrapeInterval | default .Values.global.scrapeInterval | quote }}
  max_cache_size = {{ .Values.cadvisor.maxCacheSize | default .Values.global.maxCacheSize | int }}
  forward_to = [prometheus.relabel.cadvisor.receiver]
}

prometheus.relabel "cadvisor" {
  max_cache_size = {{ .Values.cadvisor.maxCacheSize | default .Values.global.maxCacheSize | int }}

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
{{- if .Values.cadvisor.extraMetricProcessingRules }}
{{ .Values.cadvisor.extraMetricProcessingRules | indent 2 }}
{{- end }}
  forward_to = argument.metrics_destinations.value
}
{{- end }}
{{- end }}
