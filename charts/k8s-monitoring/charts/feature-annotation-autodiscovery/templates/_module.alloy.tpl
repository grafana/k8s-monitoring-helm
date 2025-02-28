{{- define "feature.annotationAutodiscovery.module" }}
declare "annotation_autodiscovery" {
  argument "metrics_destinations" {
    comment = "Must be a list of metric destinations where collected metrics should be forwarded to"
  }

  discovery.kubernetes "pods" {
    role = "pod"
{{- if .Values.namespaces }}
    namespaces {
      names = {{ .Values.namespaces | toJson }}
    }
{{- end }}
  }

  discovery.relabel "annotation_autodiscovery_pods" {
    targets = discovery.kubernetes.pods.targets
{{- if .Values.excludeNamespaces }}
    rule {
      source_labels = ["__meta_kubernetes_namespace"]
      regex = "{{ join "|" .Values.excludeNamespaces }}"
      action = "drop"
    }
{{- end }}
    rule {
      source_labels = ["{{ include "pod_annotation" .Values.annotations.scrape }}"]
      regex = "true"
      action = "keep"
    }
    rule {
      source_labels = ["{{ include "pod_annotation" .Values.annotations.job }}"]
      action = "replace"
      target_label = "job"
    }
    rule {
      source_labels = ["{{ include "pod_annotation" .Values.annotations.instance }}"]
      action = "replace"
      target_label = "instance"
    }
    rule {
      source_labels = ["{{ include "pod_annotation" .Values.annotations.metricsPath }}"]
      action = "replace"
      target_label = "__metrics_path__"
    }

    // Choose the pod port
    // The discovery generates a target for each declared container port of the pod.
    // If the metricsPortName annotation has value, keep only the target where the port name matches the one of the annotation.
    rule {
      source_labels = ["__meta_kubernetes_pod_container_port_name"]
      target_label = "__tmp_port"
    }
    rule {
      source_labels = ["{{ include "pod_annotation" .Values.annotations.metricsPortName }}"]
      regex = "(.+)"
      target_label = "__tmp_port"
    }
    rule {
      source_labels = ["__meta_kubernetes_pod_container_port_name"]
      action = "keepequal"
      target_label = "__tmp_port"
    }
    rule {
      action = "labeldrop"
      regex = "__tmp_port"
    }

    // If the metrics port number annotation has a value, override the target address to use it, regardless whether it is
    // one of the declared ports on that Pod.
    rule {
      source_labels = ["{{ include "pod_annotation" .Values.annotations.metricsPortNumber }}", "__meta_kubernetes_pod_ip"]
      regex = "(\\d+);(([A-Fa-f0-9]{1,4}::?){1,7}[A-Fa-f0-9]{1,4})"
      replacement = "[$2]:$1" // IPv6
      target_label = "__address__"
    }
    rule {
      source_labels = ["{{ include "pod_annotation" .Values.annotations.metricsPortNumber }}", "__meta_kubernetes_pod_ip"]
      regex = "(\\d+);((([0-9]+?)(\\.|$)){4})" // IPv4, takes priority over IPv6 when both exists
      replacement = "$2:$1"
      target_label = "__address__"
    }

    rule {
      source_labels = ["{{ include "pod_annotation" .Values.annotations.metricsScheme }}"]
      regex = "(.+)"
      target_label = "__scheme__"
    }

    rule {
      source_labels = ["{{ include "pod_annotation" .Values.annotations.metricsScrapeInterval }}"]
      regex = "(.+)"
      target_label = "__scrape_interval__"
    }
    rule {
      source_labels = ["__scrape_interval__"]
      regex = ""
      replacement = {{ .Values.scrapeInterval | default .Values.global.scrapeInterval | quote }}
      target_label = "__scrape_interval__"
    }
    rule {
      source_labels = ["{{ include "pod_annotation" .Values.annotations.metricsScrapeTimeout }}"]
      regex = "(.+)"
      target_label = "__scrape_timeout__"
    }
    rule {
      source_labels = ["__scrape_timeout__"]
      regex = ""
      replacement = {{ .Values.scrapeTimeout | default .Values.global.scrapeTimeout | quote }}
      target_label = "__scrape_timeout__"
    }
{{- if .Values.extraDiscoveryRules }}
{{ .Values.extraDiscoveryRules | indent 4 }}
{{- end }}
  }

  discovery.kubernetes "services" {
    role = "service"
{{- if .Values.namespaces }}
    namespaces {
      names = {{ .Values.namespaces | toJson }}
    }
{{- end }}
  }

  discovery.relabel "annotation_autodiscovery_services" {
    targets = discovery.kubernetes.services.targets
{{- if .Values.excludeNamespaces }}
    rule {
      source_labels = ["__meta_kubernetes_namespace"]
      regex = "{{ join "|" .Values.excludeNamespaces }}"
      action = "drop"
    }
{{- end }}
    rule {
      source_labels = ["{{ include "service_annotation" .Values.annotations.scrape }}"]
      regex = "true"
      action = "keep"
    }
    rule {
      source_labels = ["{{ include "service_annotation" .Values.annotations.job }}"]
      action = "replace"
      target_label = "job"
    }
    rule {
      source_labels = ["{{ include "service_annotation" .Values.annotations.instance }}"]
      action = "replace"
      target_label = "instance"
    }
    rule {
      source_labels = ["{{ include "service_annotation" .Values.annotations.metricsPath }}"]
      action = "replace"
      target_label = "__metrics_path__"
    }

    // Choose the service port
    rule {
      source_labels = ["__meta_kubernetes_service_port_name"]
      target_label = "__tmp_port"
    }
    rule {
      source_labels = ["{{ include "service_annotation" .Values.annotations.metricsPortName }}"]
      regex = "(.+)"
      target_label = "__tmp_port"
    }
    rule {
      source_labels = ["__meta_kubernetes_service_port_name"]
      action = "keepequal"
      target_label = "__tmp_port"
    }

    rule {
      source_labels = ["__meta_kubernetes_service_port_number"]
      target_label = "__tmp_port"
    }
    rule {
      source_labels = ["{{ include "service_annotation" .Values.annotations.metricsPortNumber }}"]
      regex = "(.+)"
      target_label = "__tmp_port"
    }
    rule {
      source_labels = ["__meta_kubernetes_service_port_number"]
      action = "keepequal"
      target_label = "__tmp_port"
    }
    rule {
      action = "labeldrop"
      regex = "__tmp_port"
    }

    rule {
      source_labels = ["{{ include "service_annotation" .Values.annotations.metricsScheme }}"]
      regex = "(.+)"
      target_label = "__scheme__"
    }

    rule {
      source_labels = ["{{ include "service_annotation" .Values.annotations.metricsScrapeInterval }}"]
      regex = "(.+)"
      target_label = "__scrape_interval__"
    }
    rule {
      source_labels = ["__scrape_interval__"]
      regex = ""
      replacement = {{ .Values.scrapeInterval | default .Values.global.scrapeInterval | quote }}
      target_label = "__scrape_interval__"
    }
    rule {
      source_labels = ["{{ include "service_annotation" .Values.annotations.metricsScrapeTimeout }}"]
      regex = "(.+)"
      target_label = "__scrape_timeout__"
    }
    rule {
      source_labels = ["__scrape_timeout__"]
      regex = ""
      replacement = {{ .Values.scrapeTimeout | default .Values.global.scrapeTimeout | quote }}
      target_label = "__scrape_timeout__"
    }

{{- if .Values.extraDiscoveryRules }}
{{ .Values.extraDiscoveryRules | indent 4 }}
{{- end }}
  }

  discovery.relabel "annotation_autodiscovery_http" {
    targets = concat(discovery.relabel.annotation_autodiscovery_pods.output, discovery.relabel.annotation_autodiscovery_services.output)
    rule {
      source_labels = ["__scheme__"]
      regex = "https"
      action = "drop"
    }
  }

  discovery.relabel "annotation_autodiscovery_https" {
    targets = concat(discovery.relabel.annotation_autodiscovery_pods.output, discovery.relabel.annotation_autodiscovery_services.output)
    rule {
      source_labels = ["__scheme__"]
      regex = "https"
      action = "keep"
    }
  }

  prometheus.scrape "annotation_autodiscovery_http" {
    targets = discovery.relabel.annotation_autodiscovery_http.output
    honor_labels = true
{{- if .Values.bearerToken.enabled }}
    bearer_token_file = {{ .Values.bearerToken.token | quote }}
{{- end }}
    clustering {
      enabled = true
    }
{{ if or .Values.metricsTuning.includeMetrics .Values.metricsTuning.excludeMetrics .Values.extraMetricProcessingRules }}
    forward_to = [prometheus.relabel.annotation_autodiscovery.receiver]
{{- else }}
    forward_to = argument.metrics_destinations.value
{{- end }}
  }

  prometheus.scrape "annotation_autodiscovery_https" {
    targets = discovery.relabel.annotation_autodiscovery_https.output
    honor_labels = true
{{- if .Values.bearerToken.enabled }}
    bearer_token_file = {{ .Values.bearerToken.token | quote }}
{{- end }}
    tls_config {
      insecure_skip_verify = true
    }
    clustering {
      enabled = true
    }
{{ if or .Values.metricsTuning.includeMetrics .Values.metricsTuning.excludeMetrics .Values.extraMetricProcessingRules }}
    forward_to = [prometheus.relabel.annotation_autodiscovery.receiver]
  }

  prometheus.relabel "annotation_autodiscovery" {
    max_cache_size = {{ .Values.maxCacheSize | default .Values.global.maxCacheSize | int }}
{{- if .Values.metricsTuning.includeMetrics }}
    rule {
      source_labels = ["__name__"]
      regex = "up|scrape_samples_scraped|{{ join "|" .Values.metricsTuning.includeMetrics }}"
      action = "keep"
    }
{{- end }}
{{- if .Values.metricsTuning.excludeMetrics }}
    rule {
      source_labels = ["__name__"]
      regex = {{ join "|" .Values.metricsTuning.excludeMetrics | quote }}
      action = "drop"
    }
{{- end }}
{{- if .Values.extraMetricProcessingRules }}
{{ .Values.extraMetricProcessingRules | indent 4 }}
{{- end }}
{{- end }}
    forward_to = argument.metrics_destinations.value
  }
}
{{- end -}}

{{- define "feature.annotationAutodiscovery.alloyModules" }}{{- end }}
