{{- define "features.cloudwatchMetrics.enabled" }}{{ .Values.cloudwatchMetrics.enabled }}{{- end }}

{{- define "features.cloudwatchMetrics.include" }}
{{- if .Values.cloudwatchMetrics.enabled -}}
{{- $destinations := include "features.cloudwatchMetrics.destinations" . | fromYamlArray }}
// Feature: CloudWatch Metrics
{{- include "feature.cloudwatchMetrics.module" (dict "Values" $.Values.cloudwatchMetrics "Files" $.Subcharts.cloudwatchMetrics.Files "Release" $.Release) }}
cloudwatch_metrics "feature" {
  metrics_destinations = [
    {{ include "dataProcessors.pipeline.targets.forFeature" (dict "root" $ "featureKey" "cloudwatchMetrics" "destinationNames" $destinations "type" "metrics" "ecosystem" "prometheus") | indent 4 | trim }}
  ]
}
{{- include "dataProcessors.pipeline.render.forFeature" (dict "root" $ "featureKey" "cloudwatchMetrics" "destinationNames" $destinations "type" "metrics" "ecosystem" "prometheus") }}
{{- end -}}
{{- end -}}

{{- define "features.cloudwatchMetrics.destinations" }}
{{- if .Values.cloudwatchMetrics.enabled -}}
{{- include "destinations.get" (dict "destinations" $.Values.destinations "type" "metrics" "ecosystem" "prometheus" "filter" $.Values.cloudwatchMetrics.destinations) -}}
{{- end -}}
{{- end -}}

{{- define "features.cloudwatchMetrics.destinations.isTranslating" }}
{{- $isTranslating := false -}}
{{- $destinations := include "features.cloudwatchMetrics.destinations" . | fromYamlArray -}}
{{ range $destination := $destinations -}}
  {{- $destinationEcosystem := include "destination.getEcosystem" (deepCopy $ | merge (dict "destination" $destination)) -}}
  {{- if ne $destinationEcosystem "prometheus" -}}
    {{- $isTranslating = true -}}
  {{- end -}}
{{- end -}}
{{- $isTranslating -}}
{{- end -}}

{{- define "features.cloudwatchMetrics.collector.values" }}{{- end -}}

{{/* Reports whether the collector runs more than one Alloy instance, and so could gather the same CloudWatch metrics
     more than once. Mirrors the checks in collectors.validate.clusteringEnabled.
     Inputs: Values, Files, collectorName (string) */}}
{{- define "features.cloudwatchMetrics.collectorRunsMultipleInstances" }}
{{- $collectorValues := include "collector.alloy.valuesWithUpstream" (dict "Values" .Values "Files" .Files "collectorName" .collectorName) | fromYaml }}
{{- $controllerType := dig "controller" "type" "daemonset" $collectorValues }}
{{- $replicas := dig "controller" "replicas" 1 $collectorValues }}
{{- $hpaEnabled := or (dig "controller" "autoscaling" "enabled" false $collectorValues) (dig "controller" "autoscaling" "horizontal" "enabled" false $collectorValues) }}
{{- or (eq $controllerType "daemonset") (gt (int $replicas) 1) $hpaEnabled }}
{{- end -}}

{{/* Every CloudWatch API call the exporter makes is billed, so gathering the same metric twice costs real money. The
     generated prometheus.scrape components enable clustering, which shards the exporter targets across replicas, but
     that only helps when the collector actually has clustering turned on. This is the same condition as
     collectors.validate.clusteringEnabled, reported separately so the remedy can lead with the singleton preset,
     which suits this feature better than scaling out.
     Inputs: Values, Files, collectorName (string) */}}
{{- define "features.cloudwatchMetrics.validate.scrapesAreNotDuplicated" }}
{{- if .collectorName }}
  {{- if eq (include "features.cloudwatchMetrics.collectorRunsMultipleInstances" .) "true" }}
    {{- $collectorValues := include "collector.alloy.valuesWithUpstream" (dict "Values" .Values "Files" .Files "collectorName" .collectorName) | fromYaml }}
    {{- if not (dig "alloy" "clustering" "enabled" false $collectorValues) }}
      {{- $msg := list "" (printf "The AWS CloudWatch metrics feature is assigned to the %s collector, which runs more than one Alloy instance without clustering." .collectorName) }}
      {{- $msg = append $msg "Every instance would gather the same CloudWatch metrics and be billed for its own API calls." }}
      {{- $msg = append $msg "Please run the collector as a single instance:" }}
      {{- $msg = append $msg "collectors:" }}
      {{- $msg = append $msg (printf "  %s:" .collectorName) }}
      {{- $msg = append $msg "    presets: [singleton]" }}
      {{- $msg = append $msg "Or, to keep scaling out, enable clustering so the scrapes are shared between instances:" }}
      {{- $msg = append $msg (printf "  %s:" .collectorName) }}
      {{- $msg = append $msg "    presets: [clustered]" }}
      {{- fail (join "\n" $msg) }}
    {{- end }}
  {{- end }}
{{- end }}
{{- end -}}

{{/* Decoupled scraping gathers CloudWatch metrics on a background timer inside the exporter, which runs in every
     replica of the collector. Unlike a prometheus.scrape, that background poller is not sharded by clustering, so
     every replica issues its own billed CloudWatch API calls. Require a single replica in that case.
     Inputs: Values, Files, collectorName (string) */}}
{{- define "features.cloudwatchMetrics.validate.decoupledScrapingIsSingleReplica" }}
{{- if .collectorName }}
  {{- $usesDecoupledScraping := false }}
  {{- range $instance := .Values.cloudwatchMetrics.instances }}
    {{- if dig "decoupledScraping" "enabled" false $instance }}
      {{- $usesDecoupledScraping = true }}
    {{- end }}
  {{- end }}
  {{- if $usesDecoupledScraping }}
    {{- $collectorValues := include "collector.alloy.valuesWithUpstream" (dict "Values" .Values "Files" .Files "collectorName" .collectorName) | fromYaml }}
    {{- $controllerType := dig "controller" "type" "daemonset" $collectorValues }}
    {{- $replicas := dig "controller" "replicas" 1 $collectorValues }}
    {{- $hpaEnabled := or (dig "controller" "autoscaling" "enabled" false $collectorValues) (dig "controller" "autoscaling" "horizontal" "enabled" false $collectorValues) }}
    {{- if or (eq $controllerType "daemonset") (gt (int $replicas) 1) $hpaEnabled }}
      {{- $msg := list "" (printf "The AWS CloudWatch metrics feature has decoupled scraping enabled, but the %s collector runs more than one instance." .collectorName) }}
      {{- $msg = append $msg "Decoupled scraping polls the CloudWatch API on a background timer that clustering does not shard," }}
      {{- $msg = append $msg "so every replica would gather the same metrics and be billed for its own API calls." }}
      {{- $msg = append $msg "Please run the collector as a single instance:" }}
      {{- $msg = append $msg "collectors:" }}
      {{- $msg = append $msg (printf "  %s:" .collectorName) }}
      {{- $msg = append $msg "    presets: [singleton]" }}
      {{- $msg = append $msg "Or disable decoupled scraping on every cloudwatchMetrics instance." }}
      {{- fail (join "\n" $msg) }}
    {{- end }}
  {{- end }}
{{- end }}
{{- end -}}

{{- define "features.cloudwatchMetrics.validate" }}
{{- if .Values.cloudwatchMetrics.enabled }}
  {{- $featureKey := "cloudwatchMetrics" }}
  {{- $featureName := "AWS CloudWatch metrics" }}
  {{- $destinations := include "features.cloudwatchMetrics.destinations" . | fromYamlArray }}
  {{- include "destinations.validate.destinationListNotEmpty" (dict "destinations" $destinations "type" "metrics" "ecosystem" "prometheus" "featureName" $featureName "Values" $.Values "featureKey" $featureKey) }}
  {{- include "dataProcessors.validate.feature" (dict "root" $ "featureKey" $featureKey "featureName" $featureName "type" "metrics" "ecosystem" "prometheus") }}

  {{- $collectorName := include "collectors.getCollectorForFeature" (dict "Values" $.Values "featureKey" $featureKey) }}
  {{- include "collectors.validate.collectorIsAssigned" (dict "Values" $.Values "collectorName" $collectorName "featureKey" $featureKey "featureName" $featureName) }}
  {{- include "features.cloudwatchMetrics.validate.scrapesAreNotDuplicated" (dict "Values" $.Values "Files" $.Files "collectorName" $collectorName) }}
  {{- include "features.cloudwatchMetrics.validate.decoupledScrapingIsSingleReplica" (dict "Values" $.Values "Files" $.Files "collectorName" $collectorName) }}

  {{- include "feature.cloudwatchMetrics.validate" (dict "Values" $.Values.cloudwatchMetrics) }}
{{- end }}
{{- end }}
