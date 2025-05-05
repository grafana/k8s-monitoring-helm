{{- define "integrations.etcd.type.metrics" }}true{{- end }}
{{- define "integrations.etcd.type.logs" }}false{{- end }}

{{/* Loads the etcd module and instances */}}
{{/* Inputs: Values (all values), Files (Files object) */}}
{{- define "integrations.etcd.module.metrics" }}
declare "etcd_integration" {
  argument "metrics_destinations" {
    comment = "Must be a list of metric destinations where collected metrics should be forwarded to"
  }

  {{- range $instance := (index $.Values "etcd").instances }}
    {{- include "integrations.etcd.include.metrics" (deepCopy $ | merge (dict "instance" $instance)) | nindent 2 }}
  {{- end }}
}
{{- end }}

{{/* Instantiates the etcd integration */}}
{{/* Inputs: integration (etcd integration definition), Values (all values), Files (Files object) */}}
{{- define "integrations.etcd.include.metrics" }}
{{- $defaultValues := "integrations/etcd-values.yaml" | .Files.Get | fromYaml }}
{{- with mergeOverwrite $defaultValues (deepCopy .instance) }}
{{- $metricAllowList := .metrics.tuning.includeMetrics }}
{{- $metricDenyList := .metrics.tuning.excludeMetrics }}
{{- $labelSelectors := list }}
{{- range $k, $v := .labelSelectors }}
  {{- if kindIs "slice" $v }}
    {{- $labelSelectors = append $labelSelectors (printf "%s in (%s)" $k (join "," $v)) }}
  {{- else }}
    {{- $labelSelectors = append $labelSelectors (printf "%s=%s" $k $v) }}
  {{- end }}
{{- end }}
discovery.kubernetes {{ include "helper.alloy_name" .name | quote }} {
  role = "pod"

  selectors {
    role = "pod"
{{- if .fieldSelectors }}
    field = {{ .fieldSelectors | join "," | quote }}
{{- end }}
    label = {{ $labelSelectors | join "," | quote }}
  }

{{- if .namespaces }}
  namespaces {
    names = {{ .namespaces | toJson }}
  }
{{- end }}
}

discovery.relabel {{ include "helper.alloy_name" .name | quote }} {
  targets = discovery.kubernetes.{{ include "helper.alloy_name" .name }}.targets

  // keep only the specified metrics port name, and pods that are Running and ready
  rule {
    source_labels = [
      "__meta_kubernetes_pod_phase",
      "__meta_kubernetes_pod_ready",
    ]
    separator = "@"
    regex = "Running@true"
    action = "keep"
  }

  // drop any init containers
  rule {
    source_labels = ["__meta_kubernetes_pod_container_init"]
    regex = "true"
    action = "drop"
  }

  // set the metrics port
  rule {
    source_labels = ["__address__"]
    replacement = "$1:{{ .metrics.port }}"
    target_label = "__address__"
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
  rule {
    source_labels = [
      "__meta_kubernetes_pod_controller_kind",
      "__meta_kubernetes_pod_controller_name",
    ]
    separator = "/"
    target_label  = "workload"
  }
  rule {
    source_labels = ["workload"]
    regex = "(ReplicaSet/.+)-.+"
    target_label  = "workload"
  }

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

  rule {
    action = "replace"
    replacement = "kubernetes"
    target_label = "source"
  }
}

prometheus.scrape {{ include "helper.alloy_name" .name | quote }} {
  targets = discovery.relabel.{{ include "helper.alloy_name" .name }}.output
  job_name = {{ .jobLabel | quote }}
  scrape_interval = {{ .scrapeInterval | default $.Values.global.scrapeInterval | quote }}
  clustering {
    enabled = true
  }
  forward_to = [prometheus.relabel.{{ include "helper.alloy_name" .name }}.receiver]
}

prometheus.relabel {{ include "helper.alloy_name" .name | quote }} {
  max_cache_size = {{ .metrics.maxCacheSize | default $.Values.global.maxCacheSize | int }}

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

{{- define "integrations.etcd.validate" }}
  {{- range $instance := $.Values.etcd.instances }}
    {{- include "integrations.etcd.instance.validate" (merge $ (dict "instance" $instance)) | nindent 2 }}
  {{- end }}
{{- end }}

{{- define "integrations.etcd.instance.validate" }}
  {{- if not .instance.labelSelectors }}
    {{- $msg := list "" "The etcd integration requires a label selector" }}
    {{- $msg = append $msg "For example, please set:" }}
    {{- $msg = append $msg "integrations:" }}
    {{- $msg = append $msg "  etcd:" }}
    {{- $msg = append $msg "    instances:" }}
    {{- $msg = append $msg (printf "      - name: %s" .instance.name) }}
    {{- $msg = append $msg "        labelSelectors:" }}
    {{- $msg = append $msg (printf "          app.kubernetes.io/component: %s" .instance.name) }}
    {{- $msg = append $msg "OR" }}
    {{- $msg = append $msg "        labelSelectors:" }}
    {{- $msg = append $msg "          app.kubernetes.io/component: [etcd-one, etcd-two]" }}
    {{- fail (join "\n" $msg) }}
  {{- end }}
{{- end }}