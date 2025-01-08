{{- define "feature.autoInstrumentation.module" }}
{{- $metricAllowList := .Values.beyla.metricsTuning.includeMetrics }}
{{- $metricDenyList := .Values.beyla.metricsTuning.excludeMetrics }}
{{- $labelSelectors := list }}
{{- range $k, $v := .Values.beyla.labelMatchers }}
{{- $labelSelectors = append $labelSelectors (printf "%s=%s" $k $v) }}
{{- end }}
declare "auto_instrumentation" {
  argument "metrics_destinations" {
    comment = "Must be a list of metric destinations where collected metrics should be forwarded to"
  }

  discovery.kubernetes "beyla_pods" {
    role = "pod"
    namespaces {
      own_namespace = true
    }
    selectors {
      role = "pod"
      label = {{ $labelSelectors | join "," | quote }}
    }
  }

  discovery.relabel "beyla_pods" {
    targets = discovery.kubernetes.beyla_pods.targets
    rule {
      source_labels = ["__meta_kubernetes_pod_node_name"]
      action = "replace"
      target_label = "instance"
    }

{{- if .Values.beyla.extraDiscoveryRules }}
{{ .Values.beyla.extraDiscoveryRules | indent 4 }}
{{- end }}
  }

  prometheus.scrape "beyla_applications" {
    targets         = discovery.relabel.beyla_pods.output
    honor_labels    = true
    scrape_interval = {{ .Values.beyla.scrapeInterval | default .Values.global.scrapeInterval | quote }}
    clustering {
      enabled = true
    }
{{- if or $metricAllowList $metricDenyList .Values.beyla.extraMetricProcessingRules }}
    forward_to = [prometheus.relabel.beyla.receiver]
{{- else }}
    forward_to = argument.metrics_destinations.value
{{- end }}
  }

  prometheus.scrape "beyla_internal" {
    targets         = discovery.relabel.beyla_pods.output
    metrics_path    = "/internal/metrics"
    job_name        = "integrations/beyla"
    honor_labels    = true
    scrape_interval = {{ .Values.beyla.scrapeInterval | default .Values.global.scrapeInterval | quote }}
    clustering {
      enabled = true
    }
{{- if or $metricAllowList $metricDenyList .Values.beyla.extraMetricProcessingRules }}
    forward_to = [prometheus.relabel.beyla.receiver]
  }

prometheus.relabel "beyla" {
  max_cache_size = {{ .Values.beyla.maxCacheSize | default .Values.global.maxCacheSize | int }}
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
{{- if .Values.beyla.extraMetricProcessingRules }}
{{ .Values.beyla.extraMetricProcessingRules | indent 4 }}
{{- end }}
{{- end }}
    forward_to = argument.metrics_destinations.value
  }
}
{{- end -}}

{{- define "feature.autoInstrumentation.alloyModules" }}{{- end }}
