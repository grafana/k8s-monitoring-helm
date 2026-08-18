{{- define "profiling.subfeatures" -}}
- ebpf
- java
- pprof
{{- end -}}

{{- define "collectors.profiling.assignedCollectors" -}}
{{- $root := . -}}
{{- $collectors := list -}}
{{- if $root.Values.profiling.enabled -}}
{{- range $sub := include "profiling.subfeatures" . | fromYamlArray -}}
  {{- $subValues := get $root.Values.profiling $sub -}}
  {{- if and $subValues (dig "enabled" false $subValues) -}}
    {{- $collector := include "collectors.getCollectorForFeature" (dict "Values" $root.Values "Files" $root.Files "Subcharts" $root.Subcharts "featureKey" (printf "profiling_%s" $sub)) | trim -}}
    {{- if and $collector (not (has $collector $collectors)) -}}
      {{- $collectors = append $collectors $collector -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- end -}}
{{- range $collector := $collectors }}
- {{ $collector }}
{{- end -}}
{{- end -}}

{{- define "collectors.profiling.filterSubfeaturesForCollector" -}}
{{- $root := .root -}}
{{- $collectorName := .collectorName -}}
{{- $profiling := deepCopy $root.Values.profiling -}}
{{- range $sub := include "profiling.subfeatures" . | fromYamlArray -}}
  {{- $subValues := get $profiling $sub -}}
  {{- if and $subValues (dig "enabled" false $subValues) -}}
    {{- $collector := include "collectors.getCollectorForFeature" (dict "Values" $root.Values "Files" $root.Files "Subcharts" $root.Subcharts "featureKey" (printf "profiling_%s" $sub)) | trim -}}
    {{- if ne $collector $collectorName -}}
      {{- $_ := set $subValues "enabled" false -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- $profiling | toYaml -}}
{{- end -}}

{{- define "features.profiling.enabled" }}{{ .Values.profiling.enabled }}{{- end }}

{{- define "features.profiling.include" }}
{{- if .Values.profiling.enabled -}}
{{- $destinations := include "features.profiling.destinations" . | fromYamlArray }}
{{- $profilingValues := $.Values.profiling }}
{{- if $.collectorName }}
  {{- $profilingValues = include "collectors.profiling.filterSubfeaturesForCollector" (dict "root" $ "collectorName" $.collectorName) | fromYaml }}
{{- end }}
// Feature: Profiling
{{- include "feature.profiling.module" (dict "Values" $profilingValues "Files" $.Subcharts.profiling.Files) }}
profiling "feature" {
  profiles_destinations = [
    {{ include "pipeline.alloy.targets.forFeature" (dict "root" $ "featureKey" "profiling" "destinationNames" $destinations "type" "profiles" "ecosystem" "pyroscope") | indent 4 | trim }}
  ]
}
{{- include "pipeline.alloy.feature.render.forFeature" (dict "root" $ "featureKey" "profiling" "destinationNames" $destinations "type" "profiles" "ecosystem" "pyroscope") }}
{{- end -}}
{{- end -}}

{{- define "features.profiling.destinations" }}
{{- if .Values.profiling.enabled -}}
{{- include "destinations.get" (dict "destinations" $.Values.destinations "type" "profiles" "ecosystem" "pyroscope" "filter" $.Values.profiling.destinations) -}}
{{- end -}}
{{- end -}}

{{- define "features.profiling.destinations.isTranslating" }}
{{- $isTranslating := false -}}
{{- $destinations := include "features.profiling.destinations" . | fromYamlArray -}}
{{ range $destination := $destinations -}}
  {{- $destinationEcosystem := include "destination.getEcosystem" (deepCopy $ | merge (dict "destination" $destination)) -}}
  {{- if ne $destinationEcosystem "pyroscope" -}}
    {{- $isTranslating = true -}}
  {{- end -}}
{{- end -}}
{{- $isTranslating -}}
{{- end -}}

{{- define "features.profiling.collector.values" }}{{- end -}}

{{- define "features.profiling.validate" }}
{{- if .Values.profiling.enabled -}}
{{- $featureKey := "profiling" }}
{{- $featureName := "Profiling" }}
{{- $destinations := include "features.profiling.destinations" . | fromYamlArray }}
{{- include "destinations.validate.destinationListNotEmpty" (dict "destinations" $destinations "type" "profiles" "ecosystem" "pyroscope" "featureName" $featureName "Values" $.Values "featureKey" $featureKey) }}
{{- include "dataProcessors.validate.feature" (dict "root" $ "featureKey" "profiling" "featureName" $featureName "type" "profiles" "ecosystem" "pyroscope") }}
{{- $enabledCollectors := include "collectors.list.enabled" (dict "Values" $.Values) | fromYamlArray }}
{{- $featureCollector := include "collectors.getCollectorForFeature" (dict "Values" $.Values "featureKey" $featureKey) | trim }}
{{- range $sub := include "profiling.subfeatures" . | fromYamlArray }}
  {{- $subValues := get $.Values.profiling $sub }}
  {{- if and $subValues (dig "enabled" false $subValues) }}
    {{- $subCollector := dig "collector" "" $subValues }}
    {{- if $subCollector }}
      {{- if not (has $subCollector $enabledCollectors) }}
        {{- $msg := list "" (printf "The %s feature has %q enabled and assigned to collector %q, but that collector does not exist or is disabled." $featureName $sub $subCollector) }}
        {{- $msg = append $msg "Please assign it to one of the enabled collectors:" }}
        {{- $msg = append $msg (printf "  collector: %s" (include "english_list_or" $enabledCollectors)) }}
        {{- $msg = append $msg "See https://github.com/grafana/k8s-monitoring-helm/blob/main/charts/k8s-monitoring/docs/collectors/README.md for more details." }}
        {{- fail (join "\n" $msg) }}
      {{- end }}
    {{- else }}
      {{- include "collectors.validate.collectorIsAssigned" (dict "Values" $.Values "collectorName" $featureCollector "featureKey" $featureKey "featureName" $featureName) }}
    {{- end }}
  {{- end }}
{{- end }}
{{- include "feature.profiling.validate" (dict "Values" $.Values.profiling) }}
{{- end -}}
{{- end -}}
