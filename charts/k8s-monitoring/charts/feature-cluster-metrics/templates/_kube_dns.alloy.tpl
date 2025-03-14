{{- define "feature.clusterMetrics.kubeDNS.alloy" }}
{{- if or .Values.kubeDNS.enabled (and .Values.controlPlane.enabled (not (eq .Values.kubeDNS.enabled false))) }}
{{- $metricAllowList := .Values.kubeDNS.metricsTuning.includeMetrics }}
{{- $metricDenyList := .Values.kubeDNS.metricsTuning.excludeMetrics }}

// KubeDNS
discovery.kubernetes "kube_dns" {
  role = "endpoints"
  namespaces {
    names = ["kube-system"]
  }
  selectors {
    role = "endpoints"
    label = "k8s-app=kube-dns"
  }
}

discovery.relabel "kube_dns" {
  targets = discovery.kubernetes.kube_dns.targets

  // keep only the specified metrics port name, and pods that are Running and ready
  rule {
    source_labels = [
      "__meta_kubernetes_pod_container_port_name",
      "__meta_kubernetes_pod_phase",
      "__meta_kubernetes_pod_ready",
    ]
    separator = "@"
    regex = "metrics@Running@true"
    action = "keep"
  }

  // drop any init containers
  rule {
    source_labels = ["__meta_kubernetes_pod_container_init"]
    regex = "true"
    action = "drop"
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

  // set the service label
  rule {
    source_labels = ["__meta_kubernetes_service_name"]
    target_label  = "service"
  }

  // set a source label
  rule {
    action = "replace"
    replacement = "kubernetes"
    target_label = "source"
  }
{{- if .Values.kubeDNS.extraDiscoveryRules }}
{{ .Values.kubeDNS.extraDiscoveryRules | indent 2 }}
{{- end }}
}

prometheus.scrape "kube_dns" {
  targets = discovery.relabel.kube_dns.output
  job_name = {{ .Values.kubeDNS.jobLabel | quote }}
  scheme = "http"
  scrape_interval = {{ .Values.kubeDNS.scrapeInterval | default .Values.global.scrapeInterval | quote }}
  clustering {
    enabled = true
  }
{{- if or $metricAllowList $metricDenyList .Values.kubeDNS.extraMetricProcessingRules }}
  forward_to = [prometheus.relabel.kube_dns.receiver]
}

prometheus.relabel "kube_dns" {
  max_cache_size = {{ .Values.kubeDNS.maxCacheSize | default .Values.global.maxCacheSize | int }}
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
{{- if .Values.kubeDNS.extraMetricProcessingRules }}
{{ .Values.kubeDNS.extraMetricProcessingRules | indent 2 }}
{{- end }}
{{- end }}
  forward_to = argument.metrics_destinations.value
}
{{- end }}
{{- end }}
