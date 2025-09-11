{{- define "feature.privateDatasourceConnect.module" }}
{{- if .Values.enabled }}
declare "pdc_agent" {
  argument "metrics_destinations" {
    comment = "Must be a list of metric destinations where collected metrics should be forwarded to"
  }

  {{- $metricAllowList := .Values.metricsTuning.includeMetrics }}
  {{- $metricDenyList := .Values.metricsTuning.excludeMetrics }}
  {{- $namespace := include "feature-private-datasource-connect.namespace" . }}

  // Kubernetes service discovery for PDC Agent
  discovery.kubernetes "pdc_agent_pods" {
    role = "pod"
    {{- if $namespace }}
    namespaces {
      names = [{{ $namespace | quote }}]
    }
    {{- end }}
  }

  // Relabel rules for PDC Agent service discovery
  discovery.relabel "pdc_agent_pods" {
    targets = discovery.kubernetes.pdc_agent_pods.targets

    // Only target pods with the pdc-agent label
    rule {
      source_labels = ["__meta_kubernetes_pod_label_app_kubernetes_io_name"]
      regex = "pdc-agent"
      action = "keep"
    }

    // Set the address to the pod IP and port
    rule {
      source_labels = ["__meta_kubernetes_pod_ip"]
      target_label = "__address__"
      replacement = "${1}:{{ index .Values "pdc-agent" "metricsPort" | default "8090" }}"
    }

    // Set the instance label
    rule {
      source_labels = ["__meta_kubernetes_pod_name"]
      target_label = "instance"
    }

    // Set the job label
    rule {
      target_label = "job"
      replacement = "pdc-agent"
    }

    // Set the namespace label
    rule {
      source_labels = ["__meta_kubernetes_pod_namespace"]
      target_label = "namespace"
    }

    // Set the pod label
    rule {
      source_labels = ["__meta_kubernetes_pod_name"]
      target_label = "pod"
    }

    {{- if .Values.extraDiscoveryRules }}
    {{ .Values.extraDiscoveryRules | indent 4 }}
    {{- end }}

  }

  // Prometheus scraper for PDC Agent
  prometheus.scrape "pdc_agent" {
    targets = discovery.relabel.pdc_agent_pods.output
    scrape_interval = {{ include "feature-private-datasource-connect.scrapeInterval" . | quote }}
    {{- if .Values.scrapeTimeout }}
    scrape_timeout = {{ .Values.scrapeTimeout | quote }}
    {{- end }}
    metrics_path = "/metrics"
    scheme = "http"

    {{- if or $metricAllowList $metricDenyList .Values.extraMetricProcessingRules }}
    forward_to = [prometheus.relabel.pdc_agent.receiver]
    {{- else }}
    forward_to = argument.metrics_destinations.value
    {{- end }}
  }

  {{- if or $metricAllowList $metricDenyList .Values.extraMetricProcessingRules }}
  // Metric processing and filtering
  prometheus.relabel "pdc_agent" {
    {{- if $metricAllowList }}
    rule {
      source_labels = ["__name__"]
      regex = "{{ $metricAllowList | join "|" }}"
      action = "keep"
    }
    {{- end }}
    {{- if $metricDenyList }}
    rule {
      source_labels = ["__name__"]
      regex = "{{ $metricDenyList | join "|" }}"
      action = "drop"
    }
    {{- end }}
    {{- if .Values.extraMetricProcessingRules }}
    {{ .Values.extraMetricProcessingRules | indent 4 }}
    {{- end }}
    
    max_cache_size = {{ include "feature-private-datasource-connect.maxCacheSize" . }}
    forward_to = argument.metrics_destinations.value
  }
  {{- end }}
}
{{- end }}
{{- end -}}
