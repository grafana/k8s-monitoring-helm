{{- define "integrations.cert-manager.type.metrics" }}true{{- end }}
{{- define "integrations.cert-manager.type.logs" }}false{{- end }}

{{/* Loads the cert-manager module and instances */}}
{{/* Inputs: Values (all values), Files (Files object) */}}
{{- define "integrations.cert-manager.module.metrics" }}
declare "cert_manager_integration" {
  argument "metrics_destinations" {
    comment = "Must be a list of metric destinations where collected metrics should be forwarded to"
  }

  {{- range $instance := (index $.Values "cert-manager").instances }}
    {{- include "integrations.cert-manager.include.metrics" (deepCopy $ | merge (dict "instance" $instance)) | nindent 2 }}
  {{- end }}
}
{{- end }}

{{/* Instantiates the cert-manager integration */}}
{{/* Inputs: integration (cert-manager integration definition), Values (all values), Files (Files object) */}}
{{- define "integrations.cert-manager.include.metrics" }}
{{- $defaultValues := "integrations/cert-manager-values.yaml" | .Files.Get | fromYaml }}
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
      "__meta_kubernetes_pod_container_port_name",
      "__meta_kubernetes_pod_phase",
      "__meta_kubernetes_pod_ready",
    ]
    separator = "@"
    regex = "{{ .metrics.portName }}@Running@true"
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
}

prometheus.scrape {{ include "helper.alloy_name" .name | quote }} {
  targets = discovery.relabel.{{ include "helper.alloy_name" .name }}.output
  job_name = {{ .jobLabel | quote }}
  scrape_interval = {{ .scrapeInterval | default $.Values.global.scrapeInterval | quote }}
  clustering {
    enabled = true
  }
{{- if or $metricAllowList $metricDenyList }}
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
{{- end }}
  forward_to = argument.metrics_destinations.value
}
{{- end }}
{{- end }}

{{- define "integrations.cert-manager.validate" }}
  {{- range $instance := (index $.Values "cert-manager").instances }}
    {{- include "integrations.cert-manager.instance.validate" (merge $ (dict "instance" $instance)) | nindent 2 }}
  {{- end }}
{{- end }}

{{- define "integrations.cert-manager.instance.validate" }}
  {{- if not .instance.labelSelectors }}
    {{- $msg := list "" "The cert-manager integration requires a label selector" }}
    {{- $msg = append $msg "For example, please set:" }}
    {{- $msg = append $msg "integrations:" }}
    {{- $msg = append $msg "  cert-manager:" }}
    {{- $msg = append $msg "    instances:" }}
    {{- $msg = append $msg (printf "      - name: %s" .instance.name) }}
    {{- $msg = append $msg "        labelSelectors:" }}
    {{- $msg = append $msg (printf "          app.kubernetes.io/name: %s" .instance.name) }}
    {{- $msg = append $msg "OR" }}
    {{- $msg = append $msg "        labelSelectors:" }}
    {{- $msg = append $msg "          app.kubernetes.io/name: [cert-manager-one, cert-manager-two]" }}
    {{- fail (join "\n" $msg) }}
  {{- end }}
{{- end }}