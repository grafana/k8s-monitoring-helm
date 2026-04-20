{{/* Inputs: Values (root Values), collectorName (string), featureKey (string), featureName (string) */}}
{{- define "collectors.validate.collectorIsAssigned" }}
{{- $allCollectors := include "collectors.list.enabled" . | fromYamlArray }}
{{- if not .collectorName }}
  {{- $msg := list "" (printf "The %s feature requires a collector to be assigned." .featureName) }}
  {{- $msg = append $msg "Please assign one by setting the following:" }}
  {{- $msg = append $msg (printf "%s:" .featureKey) }}
  {{- $msg = append $msg (printf "  collector: %s" (include "english_list_or" $allCollectors)) }}
  {{- $msg = append $msg "See https://github.com/grafana/k8s-monitoring-helm/blob/main/charts/k8s-monitoring/docs/collectors/README.md for more details." }}
  {{- fail (join "\n" $msg) }}
{{- end }}
{{- if not (has .collectorName $allCollectors) }}
  {{- $msg := list "" (printf "The %s feature wants to use a collector named \"%s\", but that collector does not exist or is disabled." .featureName .collectorName) }}
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

{{- range $collectorName := include "collectors.list.enabled" . | fromYamlArray }}
  {{- $usedByAFeature := has $collectorName $collectorsUtilized }}
  {{- $collectorValues := include "collector.alloy.values" (dict "Values" $.Values "Files" $.Files "collectorName" $collectorName) | fromYaml }}
  {{- $extraConfigDefined := not (not $collectorValues.extraConfig) }}
  {{- $remoteConfigEnabled := $collectorValues.remoteConfig.enabled }}
  {{- if not (or $usedByAFeature $extraConfigDefined $remoteConfigEnabled) }}
    {{- $msg := list "" (printf "The %s collector is enabled, but there are no enabled features that will use it." $collectorName) }}
    {{- $msg = append $msg "Please disable the collector by removing it from the collectors list or by setting:" }}
    {{- $msg = append $msg "collectors:" }}
    {{- $msg = append $msg (printf "  %s:" $collectorName) }}
    {{- $msg = append $msg "    enabled: false" }}
    {{- fail (join "\n" $msg) }}
  {{- end }}
{{- end }}
{{- end }}

{{/* Inputs: Values (root Values), Files, collectorName (string), featureName (string) */}}
{{- define "collectors.validate.clusteringEnabled" }}
{{- if .collectorName }}
  {{- $collectorValues := include "collector.alloy.valuesWithUpstream" (dict "Values" .Values "Files" .Files "collectorName" .collectorName) | fromYaml }}
  {{- $controllerType := dig "controller" "type" "daemonset" $collectorValues }}
  {{- $replicas := dig "controller" "replicas" 1 $collectorValues }}
  {{- $hpaEnabled := or (dig "controller" "autoscaling" "enabled" false $collectorValues) (dig "controller" "autoscaling" "horizontal" "enabled" false $collectorValues) }}
  {{- if or (eq $controllerType "daemonset") (gt (int $replicas) 1) $hpaEnabled }}
    {{- if not (dig "alloy" "clustering" "enabled" false $collectorValues) }}
      {{- $msg := list "" (printf "The %s feature requires clustering to be enabled on the %s collector." .featureName .collectorName) }}
      {{- $msg = append $msg "Please set:" }}
      {{- $msg = append $msg "collectors:" }}
      {{- $msg = append $msg (printf "  %s:" .collectorName) }}
      {{- $msg = append $msg "    presets: [clustered]" }}
      {{- $msg = append $msg "OR"}}
      {{- $msg = append $msg (printf "  %s:" .collectorName) }}
      {{- $msg = append $msg "    alloy:"}}
      {{- $msg = append $msg "      clustering:"}}
      {{- $msg = append $msg "        enabled: true" }}
      {{- fail (join "\n" $msg) }}
    {{- end }}
  {{- end }}
{{- end }}
{{- end }}

{{- define "collectors.validate.atLeastOneEnabled" }}
  {{- $enabledCollectors := include "collectors.list.enabled" . | fromYamlArray }}
  {{- if eq (len $enabledCollectors) 0 }}
    {{- $msg := list "" "At least one collector should be enabled" }}
    {{- $msg = append $msg "Please enable one by setting:" }}
    {{- $msg = append $msg "collectors:" }}
    {{- $msg = append $msg "  <collector-name>:" }}
    {{- $msg = append $msg "    <collector-settings>" }}
    {{- $msg = append $msg "See https://github.com/grafana/k8s-monitoring-helm/blob/main/charts/k8s-monitoring/docs/collectors/README.md for more details." }}
    {{- fail (join "\n" $msg) }}
  {{- end }}
{{- end }}
