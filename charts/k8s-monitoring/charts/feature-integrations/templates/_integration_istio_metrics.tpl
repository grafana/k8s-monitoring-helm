{{/* Returns the allowed metrics */}}
{{/* Inputs: instance (Istio integration instance) Files (Files object) */}}
{{- define "integrations.istio.sidecar.allowList" }}
{{- $allowList := list }}
{{- if .instance.sidecarMetrics.tuning.useDefaultAllowList -}}
{{- $allowList = concat $allowList (list "up" "scrape_samples_scraped") (.Files.Get "default-allow-lists/istio.yaml" | fromYamlArray) -}}
{{- end -}}
{{- if .instance.sidecarMetrics.tuning.includeMetrics -}}
{{- $allowList = concat $allowList (list "up" "scrape_samples_scraped") .instance.sidecarMetrics.tuning.includeMetrics -}}
{{- end -}}
{{ $allowList | uniq | toYaml }}
{{- end -}}
{{/* Returns the allowed metrics */}}
{{/* Inputs: instance (Istio integration instance) Files (Files object) */}}
{{- define "integrations.istio.istiod.allowList" }}
{{- $allowList := list }}
{{- if .instance.istiodMetrics.tuning.useDefaultAllowList -}}
{{- $allowList = concat $allowList (list "up" "scrape_samples_scraped") (.Files.Get "default-allow-lists/istio.yaml" | fromYamlArray) -}}
{{- end -}}
{{- if .instance.istiodMetrics.tuning.includeMetrics -}}
{{- $allowList = concat $allowList (list "up" "scrape_samples_scraped") .instance.istiodMetrics.tuning.includeMetrics -}}
{{- end -}}
{{ $allowList | uniq | toYaml }}
{{- end -}}

{{/* Inputs: . (Values) */}}
{{- define "integrations.istio.type.metrics" }}
{{- $defaultValues := "integrations/istio-values.yaml" | .Files.Get | fromYaml }}
{{- $metricsEnabled := false }}
{{- range $instance := .Values.istio.instances }}
  {{- $metricsEnabled = or $metricsEnabled (dig "metrics" "enabled" true $instance) }}
{{- end }}
{{- $metricsEnabled -}}
{{- end }}

{{- define "integrations.istio.module.metrics" }}
declare "istio_integration" {
  argument "metrics_destinations" {
    comment = "Must be a list of metric destinations where collected metrics should be forwarded to"
  }
  {{- range $instance := $.Values.istio.instances }}
    {{- include "integrations.istio.include.metrics" (deepCopy $ | merge (dict "instance" $instance)) | nindent 2 }}
  {{- end }}
}
{{- end }}

{{/* Inputs: . (Values), instance (this Istio instance) */}}
{{- define "integrations.istio.include.metrics" }}
{{- $defaultValues := "integrations/istio-values.yaml" | .Files.Get | fromYaml }}
{{- with mergeOverwrite $defaultValues .instance (dict "type" "integration.istio") }}
  {{- if .sidecarMetrics.enabled }}
    {{- $metricAllowList := include "integrations.istio.sidecar.allowList" (dict "instance" . "Files" $.Files) | fromYamlArray }}
    {{- $metricDenyList := .sidecarMetrics.tuning.excludeMetrics }}
    {{- $labelSelectors := list }}
    {{- range $k, $v := .sidecarMetrics.labelSelectors }}
      {{- if kindIs "slice" $v }}
        {{- $labelSelectors = append $labelSelectors (printf "%s in (%s)" $k (join "," $v)) }}
      {{- else }}
        {{- $labelSelectors = append $labelSelectors (printf "%s=%s" $k $v) }}
      {{- end }}
    {{- end }}
discovery.kubernetes {{ printf "%s_sidecar" (include "helper.alloy_name" .name) | quote }} {
  role = "pod"
{{- if $labelSelectors }}
  selectors {
    role = "pod"
    label = {{ $labelSelectors | join "," | quote }}
  }
{{- end }}
}

discovery.relabel {{ printf "%s_sidecar" (include "helper.alloy_name" .name) | quote }} {
  targets = discovery.kubernetes.{{ printf "%s_sidecar" (include "helper.alloy_name" .name) }}.targets
  rule {
    source_labels = ["__meta_kubernetes_pod_controller_kind", "__meta_kubernetes_pod_phase"]
    regex         = "Job;(Succeeded|Failed)"
    action        = "drop"
  }

  rule {
    source_labels = ["__meta_kubernetes_pod_container_name"]
    regex         = {{ .sidecarMetrics.sidecarContainerName | quote }}
    action        = "keep"
  }
  rule {
    source_labels = [{{ include "pod_annotation" "prometheus.io/port" | quote }}, "__meta_kubernetes_pod_ip"]
    regex = "(\\d+);(([A-Fa-f0-9]{1,4}::?){1,7}[A-Fa-f0-9]{1,4})"
    replacement = "[$2]:$1" // IPv6
    target_label = "__address__"
  }
  rule {
    source_labels = [{{ include "pod_annotation" "prometheus.io/port" | quote }}, "__meta_kubernetes_pod_ip"]
    regex = "(\\d+);((([0-9]+?)(\\.|$)){4})" // IPv4, takes priority over IPv6 when both exists
    replacement = "$2:$1"
    target_label = "__address__"
  }
  rule {
    source_labels = [{{ include "pod_annotation" "prometheus.io/path" | quote }}]
    target_label  = "__metrics_path__"
  }
  rule {
    target_label = "job"
    replacement  = {{ .jobLabel | quote }}
  }
  rule {
    source_labels = ["__meta_kubernetes_namespace", "__meta_kubernetes_pod_name"]
    separator     = "-"
    target_label  = "instance"
  }
  rule {
    source_labels = ["__meta_kubernetes_pod_name"]
    target_label  = "pod"
  }
}

prometheus.scrape {{ printf "%s_sidecar" (include "helper.alloy_name" .name) | quote }} {
  targets = discovery.relabel.{{ printf "%s_sidecar" (include "helper.alloy_name" .name) }}.output
  scrape_interval = {{ .sidecarMetrics.scrapeInterval | default $.Values.global.scrapeInterval | quote }}
  scrape_timeout = {{ .sidecarMetrics.scrapeTimeout | default $.Values.global.scrapeTimeout | quote }}
  scrape_protocols = {{ $.Values.global.scrapeProtocols | toJson }}
  scrape_classic_histograms = {{ $.Values.global.scrapeClassicHistograms }}
  scrape_native_histograms = {{ $.Values.global.scrapeNativeHistograms }}
  clustering {
    enabled = true
  }
  forward_to = [prometheus.relabel.{{ printf "%s_sidecar" (include "helper.alloy_name" .name) }}.receiver]
}

prometheus.relabel {{ printf "%s_sidecar" (include "helper.alloy_name" .name) | quote }} {
  max_cache_size = {{ .sidecarMetrics.maxCacheSize | default $.Values.global.maxCacheSize | int }}
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
  forward_to = argument.metrics_destinations.value
}
  {{ end }}
  {{- if .istiodMetrics.enabled }}
    {{- $metricAllowList := include "integrations.istio.istiod.allowList" (dict "instance" . "Files" $.Files) | fromYamlArray }}
    {{- $metricDenyList := .istiodMetrics.tuning.excludeMetrics }}
    {{- $istiodLabelSelectors := list }}
    {{- range $k, $v := .istiodMetrics.labelSelectors }}
      {{- if kindIs "slice" $v }}
        {{- $istiodLabelSelectors = append $istiodLabelSelectors (printf "%s in (%s)" $k (join "," $v)) }}
      {{- else }}
        {{- $istiodLabelSelectors = append $istiodLabelSelectors (printf "%s=%s" $k $v) }}
      {{- end }}
    {{- end }}
discovery.kubernetes {{ printf "%s_istiod" (include "helper.alloy_name" .name) | quote }} {
  role = "endpoints"
  selectors {
    role = "service"
{{- if .istiodMetrics.serviceName }}
    field = "metadata.name={{ .istiodMetrics.serviceName }}"
{{- end }}
{{- if $istiodLabelSelectors }}
    label = {{ $istiodLabelSelectors | join "," | quote }}
{{- end }}
  }
{{- if .istiodMetrics.namespace }}
  namespaces {
    names = [{{ .istiodMetrics.namespace | quote }}]
  }
{{- end }}
}

discovery.relabel {{ printf "%s_istiod" (include "helper.alloy_name" .name) | quote }} {
  targets = discovery.kubernetes.{{ printf "%s_istiod" (include "helper.alloy_name" .name) }}.targets

  rule {
    source_labels = ["__meta_kubernetes_endpoint_port_name"]
    regex         = "http-monitoring"
    action        = "keep"
  }
  rule {
    target_label = "job"
    replacement  = {{ .jobLabel | quote }}
  }
  rule {
    target_label  = "instance"
    source_labels = ["__meta_kubernetes_namespace", "__meta_kubernetes_pod_name"]
    separator     = "-"
  }
  rule {
    target_label  = "pod"
    action        = "replace"
    source_labels = ["__meta_kubernetes_pod_name"]
  }
}

prometheus.scrape {{ printf "%s_istiod" (include "helper.alloy_name" .name) | quote }} {
  targets = discovery.relabel.{{ printf "%s_istiod" (include "helper.alloy_name" .name) }}.output
  clustering {
    enabled = true
  }

  scrape_interval = {{ .istiodMetrics.scrapeInterval | default $.Values.global.scrapeInterval | quote }}
  scrape_timeout = {{ .istiodMetrics.scrapeTimeout | default $.Values.global.scrapeTimeout | quote }}
  scrape_protocols = {{ $.Values.global.scrapeProtocols | toJson }}
  scrape_classic_histograms = {{ $.Values.global.scrapeClassicHistograms }}
  scrape_native_histograms = {{ $.Values.global.scrapeNativeHistograms }}
  forward_to = [prometheus.relabel.{{ printf "%s_istiod" (include "helper.alloy_name" .name) }}.receiver]
}

prometheus.relabel {{ printf "%s_istiod" (include "helper.alloy_name" .name) | quote }} {
  max_cache_size = {{ .istiodMetrics.maxCacheSize | default $.Values.global.maxCacheSize | int }}
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
  forward_to = argument.metrics_destinations.value
}
{{- end }}
{{- end }}
{{- end }}
