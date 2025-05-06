{{- define "integrations.tempo.type.metrics" }}true{{- end }}

{{/* Returns the allowed metrics */}}
{{/* Inputs: instance (tempo integration instance) Files (Files object) */}}
{{- define "integrations.tempo.allowList" }}
{{- $allowList := list -}}
{{- if .instance.metrics.tuning.useDefaultAllowList -}}
{{- $allowList = concat $allowList (list "up" "scrape_samples_scraped") (.Files.Get "default-allow-lists/tempo.yaml" | fromYamlArray) -}}
{{- end -}}
{{- if .instance.metrics.tuning.includeMetrics -}}
{{- $allowList = concat $allowList (list "up" "scrape_samples_scraped") .instance.metrics.tuning.includeMetrics -}}
{{- end -}}
{{ $allowList | uniq | toYaml }}
{{- end -}}

{{/* Loads the tempo module and instances */}}
{{/* Inputs: Values (all values), Files (Files object) */}}
{{ define "integrations.tempo.module.metrics" }}
declare "tempo_integration" {
  argument "metrics_destinations" {
    comment = "Must be a list of metric destinations where collected metrics should be forwarded to"
  }

  declare "tempo_integration_discovery" {
    argument "namespaces" {
      comment = "The namespaces to look for targets in (default: [] is all namespaces)"
      optional = true
    }

    argument "field_selectors" {
      comment = "The field selectors to use to find matching targets (default: [])"
      optional = true
    }

    argument "label_selectors" {
      comment = "The label selectors to use to find matching targets (default: [\"app.kubernetes.io/name=tempo\"])"
      optional = true
    }

    argument "port_name" {
      comment = "The of the port to scrape metrics from (default: http-metrics)"
      optional = true
    }

    // tempo service discovery for all of the pods
    discovery.kubernetes "tempo_pods" {
      role = "pod"

      selectors {
        role = "pod"
        field = string.join(coalesce(argument.field_selectors.value, []), ",")
        label = string.join(coalesce(argument.label_selectors.value, ["app.kubernetes.io/name=tempo"]), ",")
      }

      namespaces {
        names = coalesce(argument.namespaces.value, [])
      }
      {{- include "feature.integrations.attachNodeMetadata" . | nindent 6 }}
    }

    // tempo relabelings (pre-scrape)
    discovery.relabel "tempo_pods" {
      targets = discovery.kubernetes.tempo_pods.targets

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

      // the tempo-mixin expects the job label to be namespace/component
      rule {
        source_labels = ["__meta_kubernetes_namespace","__meta_kubernetes_pod_label_app_kubernetes_io_component"]
        separator = "/"
        target_label = "job"
      }

      {{ include "feature.integrations.commonDiscoveryRules" . | nindent 6 }}
    }

    export "output" {
      value = discovery.relabel.tempo_pods.output
    }
  }

  declare "tempo_integration_scrape" {
    argument "targets" {
      comment = "Must be a list() of targets"
    }

    argument "forward_to" {
      comment = "Must be a list(MetricsReceiver) where collected metrics should be forwarded to"
    }

    argument "job_label" {
      comment = "The job label to add for all Tempo metrics (default: integrations/tempo)"
      optional = true
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

    prometheus.scrape "tempo" {
      job_name = coalesce(argument.job_label.value, "integrations/tempo")
      forward_to = [prometheus.relabel.tempo.receiver]
      targets = argument.targets.value
      scrape_interval = coalesce(argument.scrape_interval.value, "60s")

      clustering {
        enabled = coalesce(argument.clustering.value, false)
      }
    }

    // tempo metric relabelings (post-scrape)
    prometheus.relabel "tempo" {
      forward_to = argument.forward_to.value
      max_cache_size = coalesce(argument.max_cache_size.value, 100000)

      // drop metrics that match the drop_metrics regex
      rule {
        source_labels = ["__name__"]
        regex = coalesce(argument.drop_metrics.value, "")
        action = "drop"
      }

      // keep only metrics that match the keep_metrics regex
      rule {
        source_labels = ["__name__"]
        regex = coalesce(argument.keep_metrics.value, "(.+)")
        action = "keep"
      }

      // the tempo-mixin expects the instance label to be the node name
      rule {
        source_labels = ["node"]
        target_label = "instance"
        replacement = "$1"
      }
      rule {
        action = "labeldrop"
        regex = "node"
      }

      // set the memcached exporter container name from container="exporter" to container="memcached"
      rule {
        source_labels = ["component", "container"]
        separator = ";"
        regex = "memcached-[^;]+;exporter"
        target_label = "container"
        replacement = "memcached"
      }
    }
  }
  {{- range $instance := $.Values.tempo.instances }}
    {{- include "integrations.tempo.include.metrics" (deepCopy $ | merge (dict "instance" $instance)) | nindent 2 }}
  {{- end }}
}
{{- end }}

{{/* Instantiates the tempo integration */}}
{{/* Inputs: integration (tempo integration definition), Values (all values), Files (Files object) */}}
{{- define "integrations.tempo.include.metrics" }}
{{- $defaultValues := fromYaml (.Files.Get "integrations/tempo-values.yaml") }}
{{- with mergeOverwrite $defaultValues .instance (dict "type" "integration.tempo") }}
{{- $metricAllowList := include "integrations.tempo.allowList" (dict "instance" . "Files" $.Files) | fromYamlArray }}
{{- $metricDenyList := .metrics.tuning.excludeMetrics }}
{{- $labelSelectors := list }}
{{- range $k, $v := .labelSelectors }}
  {{- if kindIs "slice" $v }}
    {{- $labelSelectors = append $labelSelectors (printf "%s in (%s)" $k (join "," $v)) }}
  {{- else }}
    {{- $labelSelectors = append $labelSelectors (printf "%s=%s" $k $v) }}
  {{- end }}
{{- end }}
tempo_integration_discovery {{ include "helper.alloy_name" .name | quote }} {
  namespaces = {{ .namespaces | toJson }}
  label_selectors = {{ $labelSelectors | toJson }}
{{- if .fieldSelectors }}
  field_selectors = {{ .fieldSelectors | toJson }}
{{- end }}
  port_name = {{ .metrics.portName | quote }}
}

tempo_integration_scrape  {{ include "helper.alloy_name" .name | quote }} {
  targets = tempo_integration_discovery.{{ include "helper.alloy_name" .name }}.output
  job_label = "integrations/tempo"
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
