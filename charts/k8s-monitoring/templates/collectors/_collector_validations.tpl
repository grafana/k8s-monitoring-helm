{{/* Inputs: Values (root Values), collectorName (string), featureKey (string), featureName (string) */}}
{{- define "collectors.validate.collectorIsAssigned" }}
{{- $allCollectors := (keys .Values.collectors | sortAlpha) }}
{{- if not .collectorName }}
  {{- $msg := list "" (printf "The %s feature requires a collector to be assigned." .featureName) }}
  {{- $msg = append $msg "Please assign one by setting the following:" }}
  {{- $msg = append $msg (printf "%s:" .featureKey) }}
  {{- $msg = append $msg (printf "  collector: %s" (include "english_list_or" $allCollectors)) }}
  {{- $msg = append $msg "See https://github.com/grafana/k8s-monitoring-helm/blob/main/charts/k8s-monitoring/docs/collectors/README.md for more details." }}
  {{- fail (join "\n" $msg) }}
{{- end }}
{{- if not (has .collectorName $allCollectors) }}
  {{- $msg := list "" (printf "The %s feature wants to use a collector named \"%s\", but that collector does not exist." .featureName .collectorName) }}
  {{- $msg = append $msg "Please assign one by setting the following:" }}
  {{- $msg = append $msg (printf "%s:" .featureKey) }}
  {{- $msg = append $msg (printf "  collector: %s" (include "english_list_or" $allCollectors)) }}
  {{- $msg = append $msg "See https://github.com/grafana/k8s-monitoring-helm/blob/main/charts/k8s-monitoring/docs/collectors/README.md for more details." }}
  {{- fail (join "\n" $msg) }}
{{- end }}
{{- end }}

{{- define "collectors.validate.featuresEnabled" }}
{{- $collectorsUtilized := list }}
{{- range $featureKey := include "features.list.enabled" . | fromYamlArray }}
  {{- $assignedCollector := include "collectors.getCollectorForFeature" (dict "Values" $.Values "Files" $.Files "Subcharts" $.Subcharts "featureKey" $featureKey) }}
  {{- $collectorsUtilized = append $collectorsUtilized $assignedCollector }}
{{- end }}

{{- range $collectorName := keys .Values.collectors | sortAlpha }}
  {{- $usedByAFeature := has $collectorName $collectorsUtilized }}
  {{- $collectorValues := include "collector.alloy.values" (dict "Values" $.Values "Files" $.Files "collectorName" $collectorName) | fromYaml }}
  {{- $extraConfigDefined := not (not $collectorValues.extraConfig) }}
  {{- $remoteConfigEnabled := $collectorValues.remoteConfig.enabled }}
  {{- if not (or $usedByAFeature $extraConfigDefined $remoteConfigEnabled) }}
    {{- $msg := list "" (printf "The %s collector is enabled, but there are no enabled features that will use it." $collectorName) }}
    {{- $msg = append $msg "Please disable the collector by removing it from the collectors list." }}
    {{- fail (join "\n" $msg) }}
  {{- end }}
{{- end }}
{{- end }}

{{- define "collectors.validate.atLeastOneEnabled" }}
  {{- if eq (keys .Values.collectors | len) 0 }}
    {{- $msg := list "" "At least one collector should be enabled" }}
    {{- $msg = append $msg "Please enable one by setting:" }}
    {{- $msg = append $msg "collectors:" }}
    {{- $msg = append $msg "  <collector-name>:" }}
    {{- $msg = append $msg "    <collector-settings>" }}
    {{- $msg = append $msg "See https://github.com/grafana/k8s-monitoring-helm/blob/main/charts/k8s-monitoring/docs/collectors/README.md for more details." }}
    {{- fail (join "\n" $msg) }}
  {{- end }}
{{- end }}
