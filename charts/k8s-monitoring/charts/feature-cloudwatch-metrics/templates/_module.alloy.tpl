{{- /*
Renders an Alloy map literal from a dict, one key per line. Ranging a map in a Go template visits keys in sorted
order, so the generated config is stable across renders.
Inputs: . (dict)
*/ -}}
{{- define "feature.cloudwatchMetrics.map" }}
{
{{- range $key, $value := . }}
  {{ $key | quote }} = {{ $value | quote }},
{{- end }}
}
{{- end }}

{{- /*
Renders the `metric` blocks for a job. `period`, `length`, `nilToZero`, and `addCloudwatchTimestamp` are only emitted
when set, so that the exporter falls back to the value on the enclosing job.
Inputs: . (list of metrics)
*/ -}}
{{- define "feature.cloudwatchMetrics.metrics" }}
{{- range $metric := . }}
metric {
  name = {{ $metric.name | quote }}
  statistics = {{ $metric.statistics | toJson }}
  {{- if $metric.period }}
  period = {{ $metric.period | quote }}
  {{- end }}
  {{- if $metric.length }}
  length = {{ $metric.length | quote }}
  {{- end }}
  {{- if hasKey $metric "nilToZero" }}
  nil_to_zero = {{ $metric.nilToZero }}
  {{- end }}
  {{- if hasKey $metric "addCloudwatchTimestamp" }}
  add_cloudwatch_timestamp = {{ $metric.addCloudwatchTimestamp }}
  {{- end }}
}
{{- end }}
{{- end }}

{{- /*
Renders the `role` blocks for a job. Each role is scraped independently, which is how a single job gathers the same
metrics from several AWS accounts. Emitting nothing leaves the exporter using the credentials Alloy already has,
which is the IRSA and EKS Pod Identity case.
Inputs: . (list of roles)
*/ -}}
{{- define "feature.cloudwatchMetrics.roles" }}
{{- range $role := . }}
role {
  role_arn = {{ $role.roleArn | quote }}
  {{- if $role.externalId }}
  external_id = {{ $role.externalId | quote }}
  {{- end }}
}
{{- end }}
{{- end }}

{{- /*
Renders a `discovery` job, which finds resources by tag and gathers the listed metrics for each one.
Inputs: job, regions (instance default), roles (instance default)
*/ -}}
{{- define "feature.cloudwatchMetrics.job.discovery" }}
{{- $job := .job }}
discovery {
  type = {{ $job.type | quote }}
  regions = {{ ($job.regions | default .regions) | toJson }}
  {{- if $job.searchTags }}
  search_tags = {{ include "feature.cloudwatchMetrics.map" $job.searchTags | indent 2 | trim }}
  {{- end }}
  {{- if $job.customTags }}
  custom_tags = {{ include "feature.cloudwatchMetrics.map" $job.customTags | indent 2 | trim }}
  {{- end }}
  {{- if $job.dimensionNameRequirements }}
  dimension_name_requirements = {{ $job.dimensionNameRequirements | toJson }}
  {{- end }}
  {{- if $job.period }}
  period = {{ $job.period | quote }}
  {{- end }}
  {{- if $job.length }}
  length = {{ $job.length | quote }}
  {{- end }}
  {{- if $job.delay }}
  delay = {{ $job.delay | quote }}
  {{- end }}
  {{- if hasKey $job "nilToZero" }}
  nil_to_zero = {{ $job.nilToZero }}
  {{- end }}
  {{- if $job.recentlyActiveOnly }}
  recently_active_only = true
  {{- end }}
  {{- if hasKey $job "addCloudwatchTimestamp" }}
  add_cloudwatch_timestamp = {{ $job.addCloudwatchTimestamp }}
  {{- end }}
  {{- with ($job.roles | default .roles) }}
  {{- include "feature.cloudwatchMetrics.roles" . | trim | nindent 2 }}
  {{- end }}
  {{- include "feature.cloudwatchMetrics.metrics" $job.metrics | trim | nindent 2 }}
}
{{- end }}

{{- /*
Renders a `static` job, which gathers metrics for an explicit set of dimensions without using discovery.
Inputs: job, regions (instance default), roles (instance default)
*/ -}}
{{- define "feature.cloudwatchMetrics.job.static" }}
{{- $job := .job }}
static {{ $job.name | quote }} {
  namespace = {{ $job.namespace | quote }}
  regions = {{ ($job.regions | default .regions) | toJson }}
  dimensions = {{ include "feature.cloudwatchMetrics.map" $job.dimensions | indent 2 | trim }}
  {{- if $job.customTags }}
  custom_tags = {{ include "feature.cloudwatchMetrics.map" $job.customTags | indent 2 | trim }}
  {{- end }}
  {{- if $job.period }}
  period = {{ $job.period | quote }}
  {{- end }}
  {{- if $job.length }}
  length = {{ $job.length | quote }}
  {{- end }}
  {{- if $job.delay }}
  delay = {{ $job.delay | quote }}
  {{- end }}
  {{- if hasKey $job "nilToZero" }}
  nil_to_zero = {{ $job.nilToZero }}
  {{- end }}
  {{- with ($job.roles | default .roles) }}
  {{- include "feature.cloudwatchMetrics.roles" . | trim | nindent 2 }}
  {{- end }}
  {{- include "feature.cloudwatchMetrics.metrics" $job.metrics | trim | nindent 2 }}
}
{{- end }}

{{- /*
Renders a `custom_namespace` job, which discovers dimensions within a namespace that CloudWatch discovery does not
cover, such as one published by your own application.
Inputs: job, regions (instance default), roles (instance default)
*/ -}}
{{- define "feature.cloudwatchMetrics.job.customNamespace" }}
{{- $job := .job }}
custom_namespace {{ $job.name | quote }} {
  namespace = {{ $job.namespace | quote }}
  regions = {{ ($job.regions | default .regions) | toJson }}
  {{- if $job.customTags }}
  custom_tags = {{ include "feature.cloudwatchMetrics.map" $job.customTags | indent 2 | trim }}
  {{- end }}
  {{- if $job.dimensionNameRequirements }}
  dimension_name_requirements = {{ $job.dimensionNameRequirements | toJson }}
  {{- end }}
  {{- if $job.period }}
  period = {{ $job.period | quote }}
  {{- end }}
  {{- if $job.length }}
  length = {{ $job.length | quote }}
  {{- end }}
  {{- if $job.delay }}
  delay = {{ $job.delay | quote }}
  {{- end }}
  {{- if hasKey $job "nilToZero" }}
  nil_to_zero = {{ $job.nilToZero }}
  {{- end }}
  {{- if $job.recentlyActiveOnly }}
  recently_active_only = true
  {{- end }}
  {{- if hasKey $job "addCloudwatchTimestamp" }}
  add_cloudwatch_timestamp = {{ $job.addCloudwatchTimestamp }}
  {{- end }}
  {{- with ($job.roles | default .roles) }}
  {{- include "feature.cloudwatchMetrics.roles" . | trim | nindent 2 }}
  {{- end }}
  {{- include "feature.cloudwatchMetrics.metrics" $job.metrics | trim | nindent 2 }}
}
{{- end }}

{{- /*
Renders one CloudWatch exporter instance: the exporter itself, plus the scrape and metric processing for it.
Inputs: . (root context), instance (this CloudWatch instance)
*/ -}}
{{- define "feature.cloudwatchMetrics.instance" }}
{{- $defaults := "instance-defaults.yaml" | .Files.Get | fromYaml }}
{{- $root := . }}
{{- with mergeOverwrite $defaults .instance }}
{{- $alloyName := include "helper.alloy_name" .name }}
{{- $jobContext := dict "regions" .regions "roles" .roles }}
prometheus.exporter.cloudwatch {{ $alloyName | quote }} {
  sts_region = {{ (.stsRegion | default (first .regions)) | quote }}
  fips_disabled = {{ .fipsDisabled }}
  {{- if .labelsSnakeCase }}
  labels_snake_case = true
  {{- end }}
  {{- if .discoveryExportedTags }}
  discovery_exported_tags = {
    {{- range $namespace, $tags := .discoveryExportedTags }}
    {{ $namespace | quote }} = {{ $tags | toJson }},
    {{- end }}
  }
  {{- end }}
  {{- if .decoupledScraping.enabled }}
  decoupled_scraping {
    enabled = true
    scrape_interval = {{ .decoupledScraping.scrapeInterval | quote }}
  }
  {{- end }}
  {{- range $job := .discoveryJobs }}
  {{- include "feature.cloudwatchMetrics.job.discovery" (merge (dict "job" $job) $jobContext) | trim | nindent 2 }}
  {{- end }}
  {{- range $job := .staticJobs }}
  {{- include "feature.cloudwatchMetrics.job.static" (merge (dict "job" $job) $jobContext) | trim | nindent 2 }}
  {{- end }}
  {{- range $job := .customNamespaceJobs }}
  {{- include "feature.cloudwatchMetrics.job.customNamespace" (merge (dict "job" $job) $jobContext) | trim | nindent 2 }}
  {{- end }}
} // prometheus.exporter.cloudwatch {{ $alloyName | quote }}

prometheus.scrape {{ $alloyName | quote }} {
  targets = prometheus.exporter.cloudwatch.{{ $alloyName }}.targets
  clustering {
    enabled = true
  }

  scrape_interval = {{ .metrics.scrapeInterval | default $root.Values.global.scrapeInterval | quote }}
  scrape_timeout = {{ .metrics.scrapeTimeout | default $root.Values.global.scrapeTimeout | quote }}
  scrape_protocols = {{ include "helper.scrapeProtocols" $root }}
  scrape_classic_histograms = {{ $root.Values.global.scrapeClassicHistograms }}
  scrape_native_histograms = {{ $root.Values.global.scrapeNativeHistograms }}
  forward_to = [prometheus.relabel.{{ $alloyName }}.receiver]
} // prometheus.scrape {{ $alloyName | quote }}

prometheus.relabel {{ $alloyName | quote }} {
  max_cache_size = {{ .metrics.maxCacheSize | default $root.Values.global.maxCacheSize | int }}
  rule {
    target_label = "instance"
    replacement = {{ .name | quote }}
  }
  rule {
    target_label = "job"
    replacement = {{ .jobLabel | quote }}
  }
  {{- if .metrics.tuning.includeMetrics }}
  rule {
    source_labels = ["__name__"]
    regex = "up|scrape_samples_scraped|{{ .metrics.tuning.includeMetrics | join "|" }}"
    action = "keep"
  }
  {{- end }}
  {{- if .metrics.tuning.excludeMetrics }}
  rule {
    source_labels = ["__name__"]
    regex = {{ .metrics.tuning.excludeMetrics | join "|" | quote }}
    action = "drop"
  }
  {{- end }}
  {{- with .metrics.extraMetricProcessingRules }}
  {{ . | indent 2 | trim }}
  {{- end }}
  forward_to = argument.metrics_destinations.value
} // prometheus.relabel {{ $alloyName | quote }}
{{- end }}
{{- end }}

{{- define "feature.cloudwatchMetrics.module" }}
declare "cloudwatch_metrics" {
  argument "metrics_destinations" {
    comment = "Must be a list of metric destinations where collected metrics should be forwarded to"
  }
{{- range $instance := .Values.instances }}
  {{- print "\n" }}
  {{- include "feature.cloudwatchMetrics.instance" (deepCopy $ | merge (dict "instance" $instance)) | trim | nindent 2 }}
{{- end }}
} // declare "cloudwatch_metrics"
{{- end -}}
