{{- define "integrations.loki.type.metrics" }}true{{- end }}

{{/* Returns the allowed metrics */}}
{{/* Inputs: instance (loki integration instance) Files (Files object) */}}
{{- define "integrations.loki.allowList" }}
{{- $defaultAllowList := .Files.Get "default-allow-lists/loki.yaml" | fromYamlArray -}}
{{- $allowList := list -}}
{{- if and .instance.metrics.tuning.useDefaultAllowList $defaultAllowList -}}
{{- $allowList = concat $allowList (list "up") -}}
{{- $allowList = concat $allowList $defaultAllowList -}}
{{- end -}}
{{- if .instance.metrics.tuning.includeMetrics -}}
{{- $allowList = concat $allowList .instance.metrics.tuning.includeMetrics -}}
{{- end -}}
{{ $allowList | uniq | toYaml }}
{{- end -}}

{{/* Loads the loki module and instances */}}
{{/* Inputs: Values (all values), Files (Files object) */}}
{{ define "integrations.loki.module.metrics" }}
declare "loki_integration" {
  argument "metrics_destinations" {
    comment = "Must be a list of metric destinations where collected metrics should be forwarded to"
  }

  declare "loki_integration_discovery" {
    argument "namespaces" {
      comment = "The namespaces to look for targets in (default: [] is all namespaces)"
      optional = true
    }

    argument "field_selectors" {
      comment = "The field selectors to use to find matching targets (default: [])"
      optional = true
    }

    argument "label_selectors" {
      comment = "The label selectors to use to find matching targets (default: [\"app.kubernetes.io/name=loki\"])"
      optional = true
    }

    argument "port_name" {
      comment = "The of the port to scrape metrics from (default: http-metrics)"
      optional = true
    }

    // loki service discovery for all of the pods
    discovery.kubernetes "loki_pods" {
      role = "pod"

      selectors {
        role = "pod"
        field = string.join(coalesce(argument.field_selectors.value, []), ",")
        label = string.join(coalesce(argument.label_selectors.value, ["app.kubernetes.io/name=loki"]), ",")
      }

      namespaces {
        names = coalesce(argument.namespaces.value, [])
      }
    }

    // loki relabelings (pre-scrape)
    discovery.relabel "loki_pods" {
      targets = discovery.kubernetes.loki_pods.targets

      // keep only the specified metrics port name, and pods that are Running and ready
      rule {
        source_labels = [
          "__meta_kubernetes_pod_container_port_name",
          "__meta_kubernetes_pod_phase",
          "__meta_kubernetes_pod_ready",
          "__meta_kubernetes_pod_container_init",
        ]
        separator = "@"
        regex = coalesce(argument.port_name.value, "http-metrics") + "@Running@true@false"
        action = "keep"
      }

      {{ include "commonRelabelings" . | nindent 4 }}
    }

    export "output" {
      value = discovery.relabel.loki_pods.output
    }
  }

  declare "loki_integration_scrape" {
    argument "targets" {
      comment = "Must be a list() of targets"
    }

    argument "forward_to" {
      comment = "Must be a list(MetricsReceiver) where collected metrics should be forwarded to"
    }

    argument "keep_metrics" {
      comment = "A regular expression of metrics to keep (default: see below)"
      optional = true
    }

    argument "drop_metrics" {
      comment = "A regular expression of metrics to drop (default: see below)"
      optional = true
    }

    argument "scrape_interval" {
      comment = "How often to scrape metrics from the targets (default: 60s)"
      optional = true
    }

    argument "max_cache_size" {
      comment = "The maximum number of elements to hold in the relabeling cache (default: 100000).  This should be at least 2x-5x your largest scrape target or samples appended rate."
      optional = true
    }

    argument "clustering" {
      comment = "Whether or not clustering should be enabled (default: false)"
      optional = true
    }

    prometheus.scrape "loki" {
      job_name = "integrations/loki"
      forward_to = [prometheus.relabel.loki.receiver]
      targets = argument.targets.value
      scrape_interval = coalesce(argument.scrape_interval.value, "60s")

      clustering {
        enabled = coalesce(argument.clustering.value, false)
      }
    }

    // loki metric relabelings (post-scrape)
    prometheus.relabel "loki" {
      forward_to = argument.forward_to.value
      max_cache_size = coalesce(argument.max_cache_size.value, 100000)

      // drop metrics that match the drop_metrics regex
      rule {
        source_labels = ["__name__"]
        regex = coalesce(argument.drop_metrics.value, "(^(go|process)_.+$)")
        action = "drop"
      }
    }
  }
  {{- range $instance := $.Values.loki.instances }}
    {{- include "integrations.loki.include.metrics" (deepCopy $ | merge (dict "instance" $instance)) | nindent 2 }}
  {{- end }}
}
{{- end }}

{{/* Instantiates the loki integration */}}
{{/* Inputs: integration (loki integration definition), Values (all values), Files (Files object) */}}
{{- define "integrations.loki.include.metrics" }}
{{- $defaultValues := "integrations/loki-values.yaml" | .Files.Get | fromYaml }}
{{- with $defaultValues | merge (deepCopy .instance) }}
  {{- $metricAllowList := include "integrations.loki.allowList" (dict "instance" . "Files" $.Files) | fromYamlArray }}
  {{- $metricDenyList := .excludeMetrics }}

  {{- $nameLabelDefined := false }}
  {{- $labelSelectors := list }}
  {{- range $k, $v := .labelSelectors }}
    {{- if eq $k "app.kubernetes.io/name" }}{{- $nameLabelDefined = true }}{{- end }}
    {{- if $v }}
      {{- $labelSelectors = append $labelSelectors (printf "%s=%s" $k $v) }}
    {{- end }}
  {{- end }}
  {{- if not $nameLabelDefined }}
    {{- $labelSelectors = append $labelSelectors (printf "app.kubernetes.io/name=%s" .name) }}
  {{- end }}
  {{- $fieldSelectors := list }}
  {{- range $k, $v := .fieldSelectors }}
    {{- $fieldSelectors = append $fieldSelectors (printf "%s=%s" $k $v) }}
  {{- end }}
loki_integration_discovery {{ include "helper.alloy_name" .name | quote }} {
  namespaces = {{ .namespaces | toJson }}
  label_selectors = {{ $labelSelectors | toJson }}
{{- if $fieldSelectors }}
  field_selectors = {{ $fieldSelectors | toJson }}
{{- end }}
  port_name = {{ .metrics.portName | quote }}
}

loki_integration_scrape  {{ include "helper.alloy_name" .name | quote }} {
  targets = loki_integration_discovery.{{ include "helper.alloy_name" .name }}.output
  clustering = true
{{- if $metricAllowList }}
  keep_metrics = {{ $metricAllowList | join "|" | quote }}
{{- end }}
{{- if $metricDenyList }}
  drop_metrics = {{ $metricDenyList | join "|" | quote }}
{{- end }}
  scrape_interval = {{ .scrapeInterval | default $.Values.global.scrapeInterval | quote }}
  max_cache_size = {{ .metrics.maxCacheSize | default $.Values.global.maxCacheSize | int }}
  forward_to = argument.metrics_destinations.value
}
{{- end }}
{{- end }}
