{{- define "integrations.grafana.type.metrics" }}true{{- end }}

{{/* Returns the allowed metrics */}}
{{/* Inputs: instance (grafana integration instance) Files (Files object) */}}
{{- define "integrations.grafana.allowList" }}
{{- $allowList := list -}}
{{- if .instance.metrics.tuning.includeMetrics -}}
{{- $allowList = concat $allowList .instance.metrics.tuning.includeMetrics -}}
{{- end -}}
{{ $allowList | uniq | toYaml }}
{{- end -}}

{{/* Loads the grafana module and instances */}}
{{/* Inputs: Values (all values), Files (Files object) */}}
{{ define "integrations.grafana.module.metrics" }}
declare "grafana_integration" {
  argument "metrics_destinations" {
    comment = "Must be a list of metric destinations where collected metrics should be forwarded to"
  }

  declare "grafana_integration_discovery" {
    argument "namespaces" {
      comment = "The namespaces to look for targets in (default: [] is all namespaces)"
      optional = true
    }

    argument "field_selectors" {
      comment = "The field selectors to use to find matching targets (default: [])"
      optional = true
    }

    argument "label_selectors" {
      comment = "The label selectors to use to find matching targets (default: [\"app.kubernetes.io/name=grafana\"])"
      optional = true
    }

    argument "port_name" {
      comment = "The of the port to scrape metrics from (default: grafana)"
      optional = true
    }

    // grafana service discovery for all of the pods
    discovery.kubernetes "grafana_pods" {
      role = "pod"

      selectors {
        role = "pod"
        field = join(coalesce(argument.field_selectors.value, []), ",")
        label = join(coalesce(argument.label_selectors.value, ["app.kubernetes.io/name=grafana"]), ",")
      }

      namespaces {
        names = coalesce(argument.namespaces.value, [])
      }
    }

    // grafana relabelings (pre-scrape)
    discovery.relabel "grafana_pods" {
      targets = discovery.kubernetes.grafana_pods.targets

      // keep only the specified metrics port name, and pods that are Running and ready
      rule {
        source_labels = [
          "__meta_kubernetes_pod_container_port_name",
          "__meta_kubernetes_pod_phase",
          "__meta_kubernetes_pod_ready",
          "__meta_kubernetes_pod_container_init",
        ]
        separator = "@"
        regex = coalesce(argument.port_name.value, "grafana") + "@Running@true@false"
        action = "keep"
      }

      {{ include "commonRelabelings" . | nindent 4 }}
    }

    export "output" {
      value = discovery.relabel.grafana_pods.output
    }
  }

  declare "grafana_integration_scrape" {
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

    prometheus.scrape "grafana" {
      job_name = "integrations/grafana"
      forward_to = [prometheus.relabel.grafana.receiver]
      targets = argument.targets.value
      scrape_interval = coalesce(argument.scrape_interval.value, "60s")

      clustering {
        enabled = coalesce(argument.clustering.value, false)
      }
    }

    // grafana metric relabelings (post-scrape)
    prometheus.relabel "grafana" {
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
  {{- range $instance := $.Values.grafana.instances }}
    {{- include "integrations.grafana.include.metrics" (deepCopy $ | merge (dict "instance" $instance)) | nindent 2 }}
  {{- end }}
}
{{- end }}

{{/* Instantiates the grafana integration */}}
{{/* Inputs: integration (grafana integration definition), Values (all values), Files (Files object) */}}
{{- define "integrations.grafana.include.metrics" }}
{{- $defaultValues := "integrations/grafana-values.yaml" | .Files.Get | fromYaml }}
{{- with $defaultValues | merge (deepCopy .instance) }}
  {{- $metricAllowList := include "integrations.grafana.allowList" (dict "instance" . "Files" $.Files) | fromYamlArray }}
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
grafana_integration_discovery {{ include "helper.alloy_name" .name | quote }} {
  namespaces = {{ .namespaces | toJson }}
  label_selectors = {{ $labelSelectors | toJson }}
{{- if $fieldSelectors }}
  field_selectors = {{ $fieldSelectors | toJson }}
{{- end }}
  port_name = {{ .metrics.portName | quote }}
}

grafana_integration_scrape  {{ include "helper.alloy_name" .name | quote }} {
  targets = grafana_integration_discovery.{{ include "helper.alloy_name" .name }}.output
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
