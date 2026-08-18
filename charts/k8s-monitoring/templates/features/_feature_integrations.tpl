{{- define "collectors.integrations.filterInstancesForCollector" -}}
{{- $root := .root -}}
{{- $collectorName := .collectorName -}}
{{- $integrations := deepCopy $root.Values.integrations -}}
{{- range $type := include "integrations.types" . | fromYamlArray -}}
  {{- $typeValues := index $integrations $type -}}
  {{- if and $typeValues $typeValues.instances -}}
    {{- $kept := list -}}
    {{- range $instance := $typeValues.instances -}}
      {{- $instanceCollector := include "collectors.getCollectorForIntegrationInstance" (dict "Values" $root.Values "Files" $root.Files "Subcharts" $root.Subcharts "instance" $instance) | trim -}}
      {{- if eq $instanceCollector $collectorName -}}
        {{- $kept = append $kept $instance -}}
      {{- end -}}
    {{- end -}}
    {{- $_ := set $typeValues "instances" $kept -}}
  {{- end -}}
{{- end -}}
{{- $integrations | toYaml -}}
{{- end -}}

{{/* Returns "true" if this single instance produces metrics or exporter logs, and so needs an integrations collector. A log-parsing-only instance returns empty. Inputs: type, instance, Files (subchart Files) */}}
{{- define "collectors.integrations.instanceProducesOutput" -}}
{{- $slice := dict "Values" (dict .type (dict "instances" (list .instance))) "Files" .Files -}}
{{- $metrics := include "feature.integrations.configured.metrics" $slice | fromYamlArray -}}
{{- $logOutput := include "feature.integrations.configured.logOutput" $slice | fromYamlArray -}}
{{- if or $metrics $logOutput }}true{{ end -}}
{{- end -}}

{{/* Returns, as a YAML list, every collector assigned to at least one integration instance that produces metrics or exporter logs. Inputs: Values (root), Files, Subcharts */}}
{{- define "collectors.integrations.assignedCollectors" -}}
{{- $root := . -}}
{{- $collectors := list -}}
{{- range $type := include "integrations.types" . | fromYamlArray -}}
  {{- $typeValues := index $root.Values.integrations $type -}}
  {{- if and $typeValues $typeValues.instances -}}
    {{- range $instance := $typeValues.instances -}}
      {{- if include "collectors.integrations.instanceProducesOutput" (dict "type" $type "instance" $instance "Files" $root.Subcharts.integrations.Files) -}}
        {{- $collector := include "collectors.getCollectorForIntegrationInstance" (dict "Values" $root.Values "Files" $root.Files "Subcharts" $root.Subcharts "instance" $instance) | trim -}}
        {{- if and $collector (not (has $collector $collectors)) -}}
          {{- $collectors = append $collectors $collector -}}
        {{- end -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- range $collector := $collectors }}
- {{ $collector }}
{{- end -}}
{{- end -}}

{{- define "features.integrations.enabled" }}
{{- $metricIntegrations := include "feature.integrations.configured.metrics" (dict "Values" .Values.integrations "Files" $.Subcharts.integrations.Files) | fromYamlArray }}
{{- $logRuleIntegrations := include "feature.integrations.configured.logRules" (dict "Values" .Values.integrations "Files" $.Subcharts.integrations.Files) | fromYamlArray }}
{{- if or $metricIntegrations $logRuleIntegrations }}true{{ else }}false{{ end }}
{{- end }}

{{- define "features.integrations.metrics.include" }}
{{- $filteredIntegrations := include "collectors.integrations.filterInstancesForCollector" (dict "root" $ "collectorName" $.collectorName) | fromYaml }}
{{- $values := dict "Chart" $.Subcharts.integrations.Chart "Values" $filteredIntegrations "Files" $.Subcharts.integrations.Files "Release" $.Release }}
{{- $metricsDestinations := include "destinations.get" (dict "destinations" $.Values.destinations "type" "metrics" "ecosystem" "prometheus" "filter" $.Values.integrations.destinations) | fromYamlArray }}
{{- $logsDestinations := include "destinations.get" (dict "destinations" $.Values.destinations "type" "logs" "ecosystem" "loki" "filter" $.Values.integrations.destinations) | fromYamlArray }}
{{- $metricIntegrations := include "feature.integrations.configured.metrics" $values | fromYamlArray }}
{{- $logOutputIntegrations := include "feature.integrations.configured.logOutput" $values | fromYamlArray }}
{{- range $integrationType := $metricIntegrations }}
{{- include (printf "integrations.%s.module.metrics" $integrationType) $values | indent 0 }}
{{ include "helper.alloy_name" $integrationType }}_integration "integration" {
  metrics_destinations = [
    {{ include "pipeline.alloy.targets.forFeature" (dict "root" $ "featureKey" "integrations" "destinationNames" $metricsDestinations "type" "metrics" "ecosystem" "prometheus") | indent 4 | trim }}
  ]
{{- if has $integrationType $logOutputIntegrations }}
  logs_destinations = [
    {{ include "pipeline.alloy.targets.forFeature" (dict "root" $ "featureKey" "integrations" "destinationNames" $logsDestinations "type" "logs" "ecosystem" "loki") | indent 4 | trim }}
  ]
{{- end }}
}
{{- end }}
{{- /* Emit the chart-owned pipeline boundary components once for the feature (not per integration), so the shared stamper/sinks/gates aren't duplicated. */}}
{{- if $metricIntegrations }}
{{- include "pipeline.alloy.feature.render.forFeature" (dict "root" $ "featureKey" "integrations" "destinationNames" $metricsDestinations "type" "metrics" "ecosystem" "prometheus") }}
{{- end }}
{{- if $logOutputIntegrations }}
{{- include "pipeline.alloy.feature.render.forFeature" (dict "root" $ "featureKey" "integrations" "destinationNames" $logsDestinations "type" "logs" "ecosystem" "loki") }}
{{- end }}
{{- end }}

{{- define "features.integrations.include" }}
  {{ include "features.integrations.metrics.include" . | indent 0 }}
{{- end }}

{{- define "features.integrations.destinations" }}
{{ include "destinations.get" (dict "destinations" $.Values.destinations "type" "metrics" "ecosystem" "prometheus" "filter" $.Values.integrations.destinations) | nindent 0 }}
{{- /* When rendering a specific collector, only wire the logs destination if that collector emits exporter logs,
       so a metrics-only collector doesn't get an idle loki.write. Without a collector (feature-level validation),
       use the unfiltered values so the logs destination is still validated. */}}
{{- $integrationsValues := $.Values.integrations }}
{{- if $.collectorName }}
  {{- $integrationsValues = include "collectors.integrations.filterInstancesForCollector" (dict "root" $ "collectorName" $.collectorName) | fromYaml }}
{{- end }}
{{- $logOutputIntegrations := include "feature.integrations.configured.logOutput" (dict "Values" $integrationsValues "Files" $.Subcharts.integrations.Files) | fromYamlArray }}
{{- if $logOutputIntegrations }}
  {{ include "destinations.get" (dict "destinations" $.Values.destinations "type" "logs" "ecosystem" "loki" "filter" $.Values.integrations.destinations) | nindent 0 }}
{{- end }}
{{- end }}

{{- define "features.integrations.destinations.isTranslating" }}
{{- $isTranslating := false -}}
{{- /*{{- $destinations := include "features.integrations.destinations" . | fromYamlArray -}}*/}}
{{- /*{{ range $destination := $destinations -}}*/}}
{{- /*  {{- $destinationEcosystem := include "destination.getEcosystem" (deepCopy $ | merge (dict "destination" $destination)) -}}*/}}
{{- /*  {{- if ne $destinationEcosystem "prometheus" -}}*/}}
{{- /*    {{- $isTranslating = true -}}*/}}
{{- /*  {{- end -}}*/}}
{{- /*{{- end -}}*/}}
{{- $isTranslating -}}
{{- end -}}

{{- define "features.integrations.logs.discoveryRules" }}
{{- $values := (dict "Values" .Values.integrations "Files" $.Subcharts.integrations.Files) }}
{{- $extraDiscoveryRules := list }}
{{- $logIntegrations := include "feature.integrations.configured.logRules" $values | fromYamlArray }}
{{- range $integration := $logIntegrations }}
  {{- $extraDiscoveryRules = append $extraDiscoveryRules ((include (printf "integrations.%s.logs.discoveryRules" $integration) $values) | indent 0) }}
{{- end }}
{{ $extraDiscoveryRules | join "\n" }}
{{- end }}

{{- define "features.integrations.logs.logProcessingStages" }}
{{- $values := (dict "Values" .Values.integrations "Files" $.Subcharts.integrations.Files) }}
{{- $extraLogProcessingStages := "" }}
{{- $logIntegrations := include "feature.integrations.configured.logRules" $values | fromYamlArray }}
{{- range $integration := $logIntegrations }}
  {{- $extraLogProcessingStages = cat $extraLogProcessingStages "\n" (include (printf "integrations.%s.logs.processingStage" $integration) $values) | indent 0 }}
{{- end }}
{{ $extraLogProcessingStages }}
{{- end }}

{{- define "features.integrations.collector.values" }}{{ end -}}

{{- define "features.integrations.validate" }}
{{- if eq (include "features.integrations.enabled" .) "true" }}
{{- $featureName := "Service Integrations" }}

{{- $metricIntegrations := include "feature.integrations.configured.metrics" (dict "Values" .Values.integrations "Files" $.Subcharts.integrations.Files) | fromYamlArray }}
{{- $logOutputIntegrations := include "feature.integrations.configured.logOutput" (dict "Values" .Values.integrations "Files" $.Subcharts.integrations.Files) | fromYamlArray }}
{{- $destinations := include "features.integrations.destinations" . | fromYamlArray }}

{{- /*
Integrations that scrape exporters (metrics) or emit exporter logs (logOutput) run on a dedicated
collector, so each instance must resolve to one: its own `collector`, else the feature-level
`integrations.collector`, else the single enabled collector. An instance naming a disabled/missing
collector fails; an instance with no collector when auto-selection returns empty also fails, since it
would be silently dropped. Log-parsing integrations (logRules only) attach to the Pod Logs feature's
collector, so they need no assignment.
*/}}
{{- if or $metricIntegrations $logOutputIntegrations }}
  {{- $enabledCollectors := include "collectors.list.enabled" (dict "Values" $.Values) | fromYamlArray }}
  {{- $featureCollector := include "collectors.getCollectorForFeature" (dict "Values" $.Values "Files" $.Files "Subcharts" $.Subcharts "featureKey" "integrations") | trim }}
  {{- range $type := concat $metricIntegrations $logOutputIntegrations | uniq }}
    {{- range $instance := (index $.Values.integrations $type).instances }}
      {{- /* Skip log-parsing-only instances: they attach to the Pod Logs collector, not an integrations collector. */}}
      {{- if include "collectors.integrations.instanceProducesOutput" (dict "type" $type "instance" $instance "Files" $.Subcharts.integrations.Files) }}
        {{- $instanceCollector := dig "collector" "" $instance }}
        {{- if $instanceCollector }}
          {{- if not (has $instanceCollector $enabledCollectors) }}
            {{- $msg := list "" (printf "The %s feature has an instance %q of type %q assigned to collector %q, but that collector does not exist or is disabled." $featureName (dig "name" "" $instance) $type $instanceCollector) }}
            {{- $msg = append $msg "Please assign it to one of the enabled collectors:" }}
            {{- $msg = append $msg (printf "  collector: %s" (include "english_list_or" $enabledCollectors)) }}
            {{- $msg = append $msg "See https://github.com/grafana/k8s-monitoring-helm/blob/main/charts/k8s-monitoring/docs/collectors/README.md for more details." }}
            {{- fail (join "\n" $msg) }}
          {{- end }}
        {{- else }}
          {{- include "collectors.validate.collectorIsAssigned" (dict "Values" $.Values "collectorName" $featureCollector "featureKey" "integrations" "featureName" $featureName) }}
        {{- end }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}

{{- if $metricIntegrations }}
  {{- include "destinations.validate.destinationListNotEmpty" (dict "destinations" $destinations "type" "metrics" "ecosystem" "prometheus" "featureName" $featureName "Values" $.Values "featureKey" "integrations") }}
  {{- include "dataProcessors.validate.feature" (dict "root" $ "featureKey" "integrations" "featureName" $featureName "type" "metrics" "ecosystem" "prometheus") }}
  {{- /* Validate clustering only on explicitly-assigned collectors (feature-level or per-instance). An
         auto-selected collector is left unchecked, matching the behavior before per-instance routing. */}}
  {{- $clusteringCollectors := list }}
  {{- with $.Values.integrations.collector }}{{- $clusteringCollectors = append $clusteringCollectors . }}{{- end }}
  {{- range $type := concat $metricIntegrations $logOutputIntegrations | uniq }}
    {{- range $instance := (index $.Values.integrations $type).instances }}
      {{- /* Skip log-parsing-only instances: they attach to the Pod Logs collector, not an integrations collector. */}}
      {{- if include "collectors.integrations.instanceProducesOutput" (dict "type" $type "instance" $instance "Files" $.Subcharts.integrations.Files) }}
        {{- $instanceCollector := dig "collector" "" $instance }}
        {{- if and $instanceCollector (not (has $instanceCollector $clusteringCollectors)) }}
          {{- $clusteringCollectors = append $clusteringCollectors $instanceCollector }}
        {{- end }}
      {{- end }}
    {{- end }}
  {{- end }}
  {{- range $collectorName := $clusteringCollectors }}
    {{- include "collectors.validate.clusteringEnabled" (dict "Values" $.Values "Files" $.Files "collectorName" $collectorName "featureName" $featureName) }}
  {{- end }}
{{- end }}

{{- if $logOutputIntegrations }}
  {{- include "destinations.validate.destinationListNotEmpty" (dict "destinations" $destinations "type" "logs" "ecosystem" "loki" "featureName" $featureName "Values" $.Values "featureKey" "integrations") }}
  {{- include "dataProcessors.validate.feature" (dict "root" $ "featureKey" "integrations" "featureName" $featureName "type" "logs" "ecosystem" "loki") }}
{{- end }}

{{- $podLogsEnabled := include "features.podLogsViaLoki.enabled" $ }}
{{- $logIntegrations := include "feature.integrations.configured.logRules" (dict "Values" .Values.integrations "Files" $.Subcharts.integrations.Files) | fromYamlArray }}
{{- if and $logIntegrations (ne $podLogsEnabled "true") }}
  {{- $msg := list "" "Service integrations that include logs requires enabling the Pod Logs feature." }}
  {{- $msg = append $msg "Please set:" }}
  {{- $msg = append $msg "podLogsViaLoki:" }}
  {{- $msg = append $msg "  enabled: true" }}
  {{- fail (join "\n" $msg) }}
{{- end }}

{{- include "feature.integrations.validate" (dict "Values" .Values.integrations "Files" $.Subcharts.integrations.Files) }}
{{- end }}
{{- end }}
