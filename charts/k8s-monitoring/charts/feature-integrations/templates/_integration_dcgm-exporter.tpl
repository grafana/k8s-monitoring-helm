{{- define "integrations.dcgm-exporter.type.metrics" }}true{{- end }}
{{- define "integrations.dcgm-exporter.type.logs" }}false{{- end }}

{{/* Returns the allowed metrics */}}
{{/* Inputs: instance (DCGM Exporter integration instance) Files (Files object) */}}
{{- define "integrations.dcgm-exporter.allowList" }}
{{- $allowList := list }}
{{- if .instance.metrics.tuning.includeMetrics -}}
{{- $allowList = concat $allowList (list "up" "scrape_samples_scraped") .instance.metrics.tuning.includeMetrics -}}
{{- end -}}
{{ $allowList | uniq | toYaml }}
{{- end -}}

{{/* Loads the DCGM Exporter module and instances */}}
{{/* Inputs: Values (all values), Files (Files object) */}}
{{ define "integrations.dcgm-exporter.module.metrics" }}
declare "dcgm_exporter_integration" {
  argument "metrics_destinations" {
    comment = "Must be a list of metric destinations where collected metrics should be forwarded to"
  }

  declare "dcgm_exporter_integration_discovery" {
    argument "namespaces" {
      comment = "The namespaces to look for targets in (default: [] is all namespaces)"
      optional = true
    }

    argument "field_selectors" {
      comment = "The field selectors to use to find matching targets (default: [])"
      optional = true
    }

    argument "label_selectors" {
      comment = "The label selectors to use to find matching targets (default: [\"app=nvidia-dcgm-exporter\"])"
      optional = true
    }

    argument "port_name" {
      comment = "The of the port to scrape metrics from (default: metrics)"
      optional = true
    }

    // DCGM Exporter service discovery for all of the pods
    discovery.kubernetes "dcgm_exporter_pods" {
      role = "pod"

      selectors {
        role = "pod"
        field = string.join(coalesce(argument.field_selectors.value, []), ",")
        label = string.join(coalesce(argument.label_selectors.value, ["app=nvidia-dcgm-exporter"]), ",")
      }

      namespaces {
        names = coalesce(argument.namespaces.value, [])
      }
      {{- include "feature.integrations.attachNodeMetadata" . | nindent 6 }}
    }

    // DCGM Exporter relabelings (pre-scrape)
    discovery.relabel "dcgm_exporter_pods" {
      targets = discovery.kubernetes.dcgm_exporter_pods.targets

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
    }

    export "output" {
      value = discovery.relabel.dcgm_exporter_pods.output
    }
  }

  declare "dcgm_exporter_integration_scrape" {
    argument "targets" {
      comment = "Must be a list() of targets"
    }

    argument "forward_to" {
      comment = "Must be a list(MetricsReceiver) where collected metrics should be forwarded to"
    }

    argument "job_label" {
      comment = "The job label to add for all Alloy metrics (default: integrations/dcgm-exporter)"
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
      comment = "The timeout for scraping metrics from the targets (default: 10s)"
      optional = true
    }

    argument "scrape_protocols" {
      comment = "The scrape protocols to use for scraping metrics"
      optional = true
    }

    argument "scrape_classic_histograms" {
      comment = "Whether to scrape classic histograms (default: false)."
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

    prometheus.scrape "dcgm_exporter" {
      targets = argument.targets.value
      job_name = coalesce(argument.job_label.value, "integrations/dcgm-exporter")
      scrape_interval = coalesce(argument.scrape_interval.value, "60s")
      scrape_timeout = coalesce(argument.scrape_timeout.value, "10s")
      scrape_protocols = argument.scrape_protocols.value
      scrape_classic_histograms = argument.scrape_classic_histograms.value

      clustering {
        enabled = coalesce(argument.clustering.value, false)
      }

      forward_to = [prometheus.relabel.dcgm_exporter.receiver]
    }

    // DCGM Exporter metric relabelings (post-scrape)
    prometheus.relabel "dcgm_exporter" {
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
  {{- range $instance := (index $.Values "dcgm-exporter").instances }}
    {{- include "integrations.dcgm-exporter.include.metrics" (deepCopy $ | merge (dict "instance" $instance)) | nindent 2 }}
  {{- end }}
}
{{- end }}

{{/* Instantiates the DCGM Exporter integration */}}
{{/* Inputs: integration (DCGM Exporter integration definition), Values (all values), Files (Files object) */}}
{{- define "integrations.dcgm-exporter.include.metrics" }}
{{- $defaultValues := "integrations/dcgm-exporter-values.yaml" | .Files.Get | fromYaml }}
{{- with mergeOverwrite $defaultValues (deepCopy .instance) }}
{{- $metricAllowList := include "integrations.dcgm-exporter.allowList" (dict "instance" . "Files" $.Files) | fromYamlArray }}
{{- $metricDenyList := .metrics.tuning.excludeMetrics }}
{{- $labelSelectors := list }}
{{- range $k, $v := .labelSelectors }}
  {{- if kindIs "slice" $v }}
    {{- $labelSelectors = append $labelSelectors (printf "%s in (%s)" $k (join "," $v)) }}
  {{- else }}
    {{- $labelSelectors = append $labelSelectors (printf "%s=%s" $k $v) }}
  {{- end }}
{{- end }}
dcgm_exporter_integration_discovery {{ include "helper.alloy_name" .name | quote }} {
  port_name = {{ .metrics.portName | quote }}
{{- if .namespaces }}
  namespaces = {{ .namespaces | toJson }}
{{- end }}
  label_selectors = {{ $labelSelectors | toJson }}
{{- if .fieldSelectors }}
  field_selectors = {{ .fieldSelectors | toJson }}
{{- end }}
}

dcgm_exporter_integration_scrape  {{ include "helper.alloy_name" .name | quote }} {
  targets = dcgm_exporter_integration_discovery.{{ include "helper.alloy_name" .name }}.output
  job_label = {{ .jobLabel | quote }}
  clustering = true
{{- if $metricAllowList }}
  keep_metrics = {{ $metricAllowList | join "|" | quote }}
{{- end }}
{{- if $metricDenyList }}
  drop_metrics = {{ $metricDenyList | join "|" | quote }}
{{- end }}
  scrape_interval = {{ .metrics.scrapeInterval | default .scrapeInterval | default $.Values.global.scrapeInterval | quote }}
  scrape_timeout = {{ .metrics.scrapeTimeout | default .scrapeTimeout | default $.Values.global.scrapeTimeout | quote }}
  scrape_protocols = {{ $.Values.global.scrapeProtocols | toJson }}
  scrape_classic_histograms = {{ $.Values.global.scrapeClassicHistograms }}
  max_cache_size = {{ .metrics.maxCacheSize | default $.Values.global.maxCacheSize | int }}
  forward_to = argument.metrics_destinations.value
}
  {{- end }}
{{- end }}

{{- define "integrations.dcgm-exporter.validate" }}
  {{- range $instance := (index $.Values "dcgm-exporter").instances }}
    {{- include "integrations.dcgm-exporter.instance.validate" (merge $ (dict "instance" $instance)) | nindent 2 }}
  {{- end }}
{{- end }}

{{- define "integrations.dcgm-exporter.instance.validate" }}
  {{- if not .instance.labelSelectors }}
    {{- $msg := list "" "The DCGM Exporter integration requires a label selector" }}
    {{- $msg = append $msg "For example, please set:" }}
    {{- $msg = append $msg "integrations:" }}
    {{- $msg = append $msg "  dcgmExporter:" }}
    {{- $msg = append $msg "    instances:" }}
    {{- $msg = append $msg (printf "      - name: %s" .instance.name) }}
    {{- $msg = append $msg "        labelSelectors:" }}
    {{- $msg = append $msg (printf "          app: %s" .instance.name) }}
    {{- $msg = append $msg "OR" }}
    {{- $msg = append $msg "        labelSelectors:" }}
    {{- $msg = append $msg "          app: [dcgm-exporter-one, dcgm-exporter-two]" }}
    {{- fail (join "\n" $msg) }}
  {{- end }}
{{- end }}
