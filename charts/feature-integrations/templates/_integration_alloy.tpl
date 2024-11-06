{{- define "integrations.alloy.type.metrics" }}true{{- end }}
{{- define "integrations.alloy.type.logs" }}false{{- end }}

{{/* Returns the allowed metrics */}}
{{/* Inputs: integration (Alloy integration definition) Files (Files object) */}}
{{- define "integrations.alloy.allowList" }}
{{- if .integration.metricsTuning.useDefaultAllowList }}
{{ "default-allow-lists/alloy.yaml" | .Files.Get }}
{{- end }}
{{- if .integration.metricsTuning.useIntegrationAllowList }}
{{ "default-allow-lists/alloy-integration.yaml" | .Files.Get }}
{{- end }}
{{- if .integration.metricsTuning.includeMetrics }}
{{ .integration.metricsTuning.includeMetrics | toYaml }}
{{- end }}
{{- end }}

{{/* Loads the Alloy module and instances */}}
{{/* Inputs: Values (all values), Files (Files object) */}}
{{ define "integrations.alloy.module.metrics" }}
declare "alloy_integration" {
  argument "metrics_destinations" {
    comment = "Must be a list of metric destinations where collected metrics should be forwarded to"
  }

  declare "alloy_integration_discovery" {
    argument "namespaces" {
      comment = "The namespaces to look for targets in (default: [] is all namespaces)"
      optional = true
    }

    argument "field_selectors" {
      comment = "The field selectors to use to find matching targets (default: [])"
      optional = true
    }

    argument "label_selectors" {
      comment = "The label selectors to use to find matching targets (default: [\"app.kubernetes.io/name=alloy\"])"
      optional = true
    }

    argument "port_name" {
      comment = "The of the port to scrape metrics from (default: http-metrics)"
      optional = true
    }

    // Alloy service discovery for all of the pods
    discovery.kubernetes "alloy_pods" {
      role = "pod"

      selectors {
        role = "pod"
        field = join(coalesce(argument.field_selectors.value, []), ",")
        label = join(coalesce(argument.label_selectors.value, ["app.kubernetes.io/name=alloy"]), ",")
      }

      namespaces {
        names = coalesce(argument.namespaces.value, [])
      }
    }

    // alloy relabelings (pre-scrape)
    discovery.relabel "alloy_pods" {
      targets = discovery.kubernetes.alloy_pods.targets

      // keep only the specified metrics port name, and pods that are Running and ready
      rule {
        source_labels = [
          "__meta_kubernetes_pod_container_port_name",
          "__meta_kubernetes_pod_phase",
          "__meta_kubernetes_pod_ready",
          "__meta_kubernetes_pod_container_init",
        ]
        separator = "@"
        regex = coalesce(argument.port_name.value, "metrics") + "@Running@true@false"
        action = "keep"
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

    export "output" {
      value = discovery.relabel.alloy_pods.output
    }
  }

  declare "alloy_integration_scrape" {
    argument "targets" {
      comment = "Must be a list() of targets"
    }

    argument "forward_to" {
      comment = "Must be a list(MetricsReceiver) where collected logs should be forwarded to"
    }

    argument "job_label" {
      comment = "The job label to add for all alloy metric (default: integrations/alloy)"
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

    argument "scrape_timeout" {
      comment = "How long before a scrape times out (default: 10s)"
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

    prometheus.scrape "alloy" {
      job_name = coalesce(argument.job_label.value, "integrations/alloy")
      forward_to = [prometheus.relabel.alloy.receiver]
      targets = argument.targets.value
      scrape_interval = coalesce(argument.scrape_interval.value, "60s")
      scrape_timeout = coalesce(argument.scrape_timeout.value, "10s")

      clustering {
        enabled = coalesce(argument.clustering.value, false)
      }
    }

    // alloy metric relabelings (post-scrape)
    prometheus.relabel "alloy" {
      forward_to = argument.forward_to.value
      max_cache_size = coalesce(argument.max_cache_size.value, 100000)

      // drop metrics that match the drop_metrics regex
      rule {
        source_labels = ["__name__"]
        regex = coalesce(argument.drop_metrics.value, "(^(go|process)_.+$)")
        action = "drop"
      }

      // keep only metrics that match the keep_metrics regex
      rule {
        source_labels = ["__name__"]
        regex = coalesce(argument.keep_metrics.value, ".*")
        action = "keep"
      }

      // remove the component_id label from any metric that starts with log_bytes or log_lines, these are custom metrics that are generated
      // as part of the log annotation modules in this repo
      rule {
        action = "replace"
        source_labels = ["__name__"]
        regex = "^log_(bytes|lines).+"
        replacement = ""
        target_label = "component_id"
      }

      // set the namespace label to that of the exported_namespace
      rule {
        action = "replace"
        source_labels = ["__name__", "exported_namespace"]
        separator = "@"
        regex = "^log_(bytes|lines).+@(.+)"
        replacement = "$2"
        target_label = "namespace"
      }

      // set the pod label to that of the exported_pod
      rule {
        action = "replace"
        source_labels = ["__name__", "exported_pod"]
        separator = "@"
        regex = "^log_(bytes|lines).+@(.+)"
        replacement = "$2"
        target_label = "pod"
      }

      // set the container label to that of the exported_container
      rule {
        action = "replace"
        source_labels = ["__name__", "exported_container"]
        separator = "@"
        regex = "^log_(bytes|lines).+@(.+)"
        replacement = "$2"
        target_label = "container"
      }

      // set the job label to that of the exported_job
      rule {
        action = "replace"
        source_labels = ["__name__", "exported_job"]
        separator = "@"
        regex = "^log_(bytes|lines).+@(.+)"
        replacement = "$2"
        target_label = "job"
      }

      // set the instance label to that of the exported_instance
      rule {
        action = "replace"
        source_labels = ["__name__", "exported_instance"]
        separator = "@"
        regex = "^log_(bytes|lines).+@(.+)"
        replacement = "$2"
        target_label = "instance"
      }

      rule {
        action = "labeldrop"
        regex = "exported_(namespace|pod|container|job|instance)"
      }
    }
  }
  {{- range $instance := $.Values.alloy.instances }}
    {{- include "integrations.alloy.include.metrics" (deepCopy $ | merge (dict "integration" $instance)) | nindent 2 }}
  {{- end }}
}
{{- end }}

{{/* Instantiates the Alloy integration */}}
{{/* Inputs: integration (Alloy integration definition), Values (all values), Files (Files object) */}}
{{- define "integrations.alloy.include.metrics" }}
{{- $defaultValues := "integrations/alloy-values.yaml" | .Files.Get | fromYaml }}
{{- with deepCopy .integration | merge $defaultValues }}
{{- $metricAllowList := include "integrations.alloy.allowList" (dict "integration" . "Files" $.Files) }}
{{- $metricDenyList := .excludeMetrics }}
{{- $labelSelectors := list }}
{{- range $k, $v := .labelSelectors }}
{{- $labelSelectors = append $labelSelectors (printf "%s=%s" $k $v) }}
{{- end }}

alloy_integration_discovery {{ include "helper.alloy_name" .name | quote }} {
  port_name       = "http-metrics"
  label_selectors = {{ $labelSelectors | toJson }}
}

alloy_integration_scrape  {{ include "helper.alloy_name" .name | quote }} {
  targets = alloy_integration_discovery.{{ include "helper.alloy_name" .name }}.output
  clustering = true
{{- if $metricAllowList }}
  keep_metrics = "up|{{ $metricAllowList | fromYamlArray | join "|" }}"
{{- end }}
{{- if $metricDenyList }}
  drop_metrics = {{ $metricDenyList | join "|" | quote }}
{{- end }}
  scrape_interval = {{ .scrapeInterval | default $.Values.global.scrapeInterval | quote }}
  max_cache_size = {{ .maxCacheSize | default $.Values.global.maxCacheSize | int }}
  forward_to = argument.metrics_destinations.value
}
{{- end }}
{{- end }}
