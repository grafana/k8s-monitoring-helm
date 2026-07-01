{{- /* Per-(type, ecosystem) support flags. EC2 enrichment applies to the label-based
       ecosystems only — discovery.ec2 enrichment is built on the experimental *.enrich
       components, and there is no discovery-driven OTLP equivalent. */}}
{{- define "dataProcessors.ec2Enrichment.supports_metrics_prometheus" }}true{{ end -}}
{{- define "dataProcessors.ec2Enrichment.supports_metrics_otlp" }}false{{ end -}}
{{- define "dataProcessors.ec2Enrichment.supports_logs_loki" }}true{{ end -}}
{{- define "dataProcessors.ec2Enrichment.supports_logs_otlp" }}false{{ end -}}
{{- define "dataProcessors.ec2Enrichment.supports_traces_otlp" }}false{{ end -}}
{{- define "dataProcessors.ec2Enrichment.supports_profiles_pyroscope" }}true{{ end -}}

{{- /* Per-(ecosystem, type) input target lookups. Telemetry flows straight into the enrich
       component for that slice. */}}
{{- define "dataProcessors.ec2Enrichment.alloy.prometheus.metrics.input" }}prometheus.enrich.{{ include "helper.alloy_name" .processorName }}_in_metrics_prometheus.receiver{{ end -}}
{{- define "dataProcessors.ec2Enrichment.alloy.loki.logs.input" }}loki.enrich.{{ include "helper.alloy_name" .processorName }}_in_logs_loki.receiver{{ end -}}
{{- define "dataProcessors.ec2Enrichment.alloy.pyroscope.profiles.input" }}pyroscope.enrich.{{ include "helper.alloy_name" .processorName }}_in_profiles_pyroscope.receiver{{ end -}}

{{- /* Per-(ecosystem, type) config slices. Each label-based ecosystem has its own enrich
       stage because their *.enrich components take different matching arguments. */}}
{{- define "dataProcessors.ec2Enrichment.alloy.prometheus.metrics.config" }}
{{- include "dataProcessors.ec2Enrichment.alloy.enrichMetrics" (dict "processor" .processor "processorName" .processorName) }}
{{- end -}}
{{- define "dataProcessors.ec2Enrichment.alloy.loki.logs.config" }}
{{- include "dataProcessors.ec2Enrichment.alloy.enrichLogs" (dict "processor" .processor "processorName" .processorName) }}
{{- end -}}
{{- define "dataProcessors.ec2Enrichment.alloy.pyroscope.profiles.config" }}
{{- include "dataProcessors.ec2Enrichment.alloy.enrichProfiles" (dict "processor" .processor "processorName" .processorName) }}
{{- end -}}

{{- /* Sanitized telemetry label names to copy from the discovered instances. */}}
{{- define "dataProcessors.ec2Enrichment.tagsToCopy" -}}
{{- $tags := default dict .tags -}}
{{- $labels := list -}}
{{- range $label := keys $tags | sortAlpha }}{{ $labels = append $labels (include "escape_label" $label) }}{{ end }}
{{- $labels | toJson }}
{{- end -}}

{{- /* Stable reference to the shared EC2 instance discovery for a processor. The label-based
       pipelines use it as their enrich targets; the collectorComponents hook renders the
       backing components once per collector when anything references it.
       Inputs: processorName */}}
{{- define "dataProcessors.ec2Enrichment.alloy.discovery.ref" -}}
discovery.relabel.{{ include "helper.alloy_name" .processorName }}_instances.output
{{- end -}}

{{- /* Renders the chart-owned components shared by every (type, ecosystem) slice of a
       processor on a collector. The EC2 API is polled for instances and tags, so the
       discovery pair is rendered once per (collector, processor) — only when the assembled
       collector config actually references it.
       Inputs: processor, processorName, config (the collector's assembled Alloy config) */}}
{{- define "dataProcessors.ec2Enrichment.alloy.collectorComponents" }}
{{- $discoveryRef := include "dataProcessors.ec2Enrichment.alloy.discovery.ref" (dict "processorName" .processorName) }}
{{- if contains $discoveryRef .config }}
// Processor: {{ .processorName }} (ec2Enrichment) — shared EC2 instance discovery
{{- include "dataProcessors.ec2Enrichment.alloy.discovery" (dict "processor" .processor "processorName" .processorName) }}
{{- end }}
{{- end }}

{{- /* EC2 instance discovery shared by the label-based pipelines. Discovers the instances in
       the region and exposes the requested tags (`__meta_ec2_tag_<tag>`) under their
       sanitized telemetry label names. The instance's private DNS name
       (`__meta_ec2_private_dns_name`) is retained for matching. Each setting maps
       `<telemetry label>: <EC2 tag name>`.
       Inputs: processor, processorName */}}
{{- define "dataProcessors.ec2Enrichment.alloy.discovery" }}
{{- $name := printf "%s_instances" (include "helper.alloy_name" .processorName) }}
{{- $tags := default dict (dig "tags" dict .processor) }}
discovery.ec2 {{ $name | quote }} {
{{- with dig "region" "" .processor }}
  region = {{ . | quote }}
{{- end }}
{{- with dig "roleARN" "" .processor }}
  role_arn = {{ . | quote }}
{{- end }}
{{- with dig "refreshInterval" "" .processor }}
  refresh_interval = {{ . | quote }}
{{- end }}
} // discovery.ec2 "{{ $name }}"
discovery.relabel {{ $name | quote }} {
  targets = discovery.ec2.{{ $name }}.targets
{{- range $label, $tag := $tags }}
  rule {
    source_labels = [{{ include "ec2_tag" $tag | quote }}]
    target_label = {{ include "escape_label" $label | quote }}
  }
{{- end }}
} // discovery.relabel "{{ $name }}"
{{- end }}

{{- /* Metrics enrichment via prometheus.enrich. Metrics are matched to their source instance
       by comparing their `node` label to the instance's private DNS name, then the requested
       tags are copied on. The enrich stage reads targets from the processor's shared EC2
       discovery, which the collectorComponents hook renders once per collector. Built from the
       experimental prometheus.enrich component, so collectors running this slice must set
       `alloy.stabilityLevel: experimental`.
       Inputs: processor, processorName */}}
{{- define "dataProcessors.ec2Enrichment.alloy.enrichMetrics" }}
{{- $p := include "helper.alloy_name" .processorName }}
{{- $outputSink := include "pipeline.alloy.outputSink.ref" (dict "processor" .processorName "type" "metrics" "ecosystem" "prometheus") }}
{{- $discoveryRef := include "dataProcessors.ec2Enrichment.alloy.discovery.ref" (dict "processorName" .processorName) }}
prometheus.enrich "{{ $p }}_in_metrics_prometheus" {
  targets = {{ $discoveryRef }}
  target_to_metric_match = {
    "__meta_ec2_private_dns_name" = "node",
  }
  labels_to_copy = {{ include "dataProcessors.ec2Enrichment.tagsToCopy" .processor }}
  forward_to = [{{ $outputSink }}]
} // prometheus.enrich "{{ $p }}_in_metrics_prometheus"
{{- end }}

{{- /* Logs enrichment via loki.enrich. Logs are matched to their source instance by comparing
       their `node` label to the instance's private DNS name, then the requested tags are
       copied on. The enrich stage reads targets from the processor's shared EC2 discovery,
       which the collectorComponents hook renders once per collector. Built from the
       experimental loki.enrich component, so collectors running this slice must set
       `alloy.stabilityLevel: experimental`.
       Inputs: processor, processorName */}}
{{- define "dataProcessors.ec2Enrichment.alloy.enrichLogs" }}
{{- $p := include "helper.alloy_name" .processorName }}
{{- $outputSink := include "pipeline.alloy.outputSink.ref" (dict "processor" .processorName "type" "logs" "ecosystem" "loki") }}
{{- $discoveryRef := include "dataProcessors.ec2Enrichment.alloy.discovery.ref" (dict "processorName" .processorName) }}
loki.enrich "{{ $p }}_in_logs_loki" {
  targets = {{ $discoveryRef }}
  target_match_label = "__meta_ec2_private_dns_name"
  logs_match_label = "node"
  labels_to_copy = {{ include "dataProcessors.ec2Enrichment.tagsToCopy" .processor }}
  forward_to = [{{ $outputSink }}]
} // loki.enrich "{{ $p }}_in_logs_loki"
{{- end }}

{{- /* Profiles enrichment via pyroscope.enrich. Profiles are matched to their source instance
       by comparing their `node` label to the instance's private DNS name, then the requested
       tags are copied on. The enrich stage reads targets from the processor's shared EC2
       discovery, which the collectorComponents hook renders once per collector. Built from the
       experimental pyroscope.enrich component, so collectors running this slice must set
       `alloy.stabilityLevel: experimental`.
       Inputs: processor, processorName */}}
{{- define "dataProcessors.ec2Enrichment.alloy.enrichProfiles" }}
{{- $p := include "helper.alloy_name" .processorName }}
{{- $outputSink := include "pipeline.alloy.outputSink.ref" (dict "processor" .processorName "type" "profiles" "ecosystem" "pyroscope") }}
{{- $discoveryRef := include "dataProcessors.ec2Enrichment.alloy.discovery.ref" (dict "processorName" .processorName) }}
pyroscope.enrich "{{ $p }}_in_profiles_pyroscope" {
  targets = {{ $discoveryRef }}
  target_match_label = "__meta_ec2_private_dns_name"
  profiles_match_label = "node"
  labels_to_copy = {{ include "dataProcessors.ec2Enrichment.tagsToCopy" .processor }}
  forward_to = [{{ $outputSink }}]
} // pyroscope.enrich "{{ $p }}_in_profiles_pyroscope"
{{- end }}

{{- /* Values-time validation for an ec2Enrichment processor definition. */}}
{{- define "dataProcessors.ec2Enrichment.validate" }}
{{- $tags := default dict (dig "tags" dict .processor) }}
{{- if empty $tags }}
  {{- $msg := list "" (printf "The processor %q does not have any tags to enrich with." .processorName) }}
  {{- $msg = append $msg "Please set at least one entry under tags. For example:" }}
  {{- $msg = append $msg "dataProcessors:" }}
  {{- $msg = append $msg (printf "  %s:" .processorName) }}
  {{- $msg = append $msg "    type: ec2Enrichment" }}
  {{- $msg = append $msg "    tags:" }}
  {{- $msg = append $msg "      team: Team" }}
  {{- fail (join "\n" $msg) }}
{{- end }}
{{- range $label, $tag := $tags }}
  {{- if not $tag }}
    {{- fail (printf "The processor %q has an empty value for tags.%s. Please set it to the name of the EC2 tag to copy." $.processorName $label) }}
  {{- end }}
{{- end }}
{{- end }}

{{- /* Per-(feature, type, ecosystem) validation. Every ecosystem this processor supports
       uses experimental Alloy components, so the collector that runs the feature must use the
       experimental stability level.
       Inputs: root, featureKey, featureName, processorName, processor, type, ecosystem */}}
{{- define "dataProcessors.ec2Enrichment.validate.feature" }}
{{- $collectorName := include "collectors.getCollectorForFeature" (dict "Values" .root.Values "Files" .root.Files "Subcharts" .root.Subcharts "featureKey" .featureKey) | trim }}
{{- if $collectorName }}
  {{- $collectorValues := include "collector.alloy.values" (dict "Values" .root.Values "Files" .root.Files "collectorName" $collectorName) | fromYaml }}
  {{- $stabilityLevel := dig "alloy" "stabilityLevel" "generally-available" $collectorValues }}
  {{- if ne $stabilityLevel "experimental" }}
    {{- $msg := list "" (printf "The processor %q requires Alloy to use the experimental stability level when enriching %s." .processorName .type) }}
    {{- $msg = append $msg "Please set:" }}
    {{- $msg = append $msg "collectors:" }}
    {{- $msg = append $msg (printf "  %s:" $collectorName) }}
    {{- $msg = append $msg "    alloy:" }}
    {{- $msg = append $msg "      stabilityLevel: experimental" }}
    {{- fail (join "\n" $msg) }}
  {{- end }}
{{- end }}
{{- end }}
