{{- define "validations" }}
  {{- include "validations.checkForV1" . }}
  {{- include "validations.cluster_name" . }}
  {{- include "validations.platform" . }}

  {{- include "destinations.validate" . -}}
  {{- include "collectors.validate.atLeastOneEnabled" . }}
  {{- include "collectors.validate.uniqueNames" . }}

  {{- /* Feature Config Influence */}}
  {{- $updatedValues := $.Values }}
  {{- range $featureKey := ((include "features.list.enabled" .) | fromYamlArray) }}
    {{- $collectorName := include "collectors.getCollectorForFeature" (dict "Values" $.Values "Files" $.Files "Subcharts" $.Subcharts "featureKey" $featureKey) }}
    {{- if $collectorName }}
      {{- $valuesWithFeatureModification := (include (printf "features.%s.collector.values" $featureKey) $ | fromYaml) }}
      {{- $updatedValues = merge $.Values $valuesWithFeatureModification }}
    {{- end }}
  {{- end }}
  {{- $updatedValues = merge $.Values (include "collectors.remoteConfig.collector.values" (dict "Values" $updatedValues "Files" $.Files "Release" $.Release "Chart" $.Chart) | fromYaml) }}

  {{- /* Feature Validations */}}
  {{- include "validations.features_enabled" . }}
  {{- range $feature := ((include "features.list" .) | fromYamlArray) }}
    {{- include (printf "features.%s.validate" $feature) $ }}
  {{- end }}

  {{- include "collectors.validate.featuresEnabled" . }}
  {{- range $collectorName := include "collectors.list.enabled" . | fromYamlArray }}
    {{- include "collectors.validate.remoteConfig" (deepCopy $ | merge (dict "collectorName" $collectorName)) }}
  {{- end }}
  {{- include "telemetryServices.validate" . }}
{{- end }}

{{/* Checks if a V1 values file was used */}}
{{- define "validations.checkForV1" }}
{{- if (index .Values "externalServices") }}
  {{- $msg := list "" "The Helm chart values appears to be from version 1.x of the k8s-monitoring Helm chart." }}
  {{- $msg = append $msg "To continue using version 1.x, add this to your helm command:" }}
  {{- $msg = append $msg "  --version ^1" }}
  {{- $msg = append $msg "" }}
  {{- $msg = append $msg "If you'd like to migrate to version 2.0, see the Migration guide:" }}
  {{- $msg = append $msg "  https://github.com/grafana/k8s-monitoring-helm/blob/main/charts/k8s-monitoring/docs/Migration.md" }}
  {{- fail (join "\n" $msg) }}
{{- end }}
{{- end }}

{{/* Checks that the cluster name is defined */}}
{{- define "validations.cluster_name" }}
{{- if or (not .Values.cluster) (and (not .Values.cluster.name) (not .Values.cluster.nameFrom)) }}
  {{- $msg := list "" "A Cluster name is required!" }}
  {{- $msg = append $msg "Please set:" }}
  {{- $msg = append $msg "cluster:" }}
  {{- $msg = append $msg "  name: my-cluster-name" }}
  {{- fail (join "\n" $msg) }}
{{- end }}
{{- end }}

{{/* Checks that at least one feature is enabled */}}
{{- define "validations.features_enabled" }}
{{ $aFeatureIsEnabled := false }}
{{- range $feature := ((include "features.list" .) | fromYamlArray ) }}
  {{- $aFeatureIsEnabled = or $aFeatureIsEnabled (eq (include (printf "features.%s.enabled" $feature) $) "true") }}
{{- end }}

{{- range $collectorName := include "collectors.list.enabled" . | fromYamlArray }}
  {{- $collectorValues := include "collector.alloy.values" (dict "Values" $.Values "Files" $.Files "collectorName" $collectorName) | fromYaml }}
  {{- $aFeatureIsEnabled = or $aFeatureIsEnabled (dig "remoteConfig" "enabled" false $collectorValues) }}
  {{- $aFeatureIsEnabled = or $aFeatureIsEnabled (hasKey $collectorValues "extraConfig") }}
{{- end }}

{{- if not $aFeatureIsEnabled }}
  {{- $msg := list "" "No features are enabled. Please choose a feature to start monitoring. For example:" }}
  {{- $msg = append $msg "clusterMetrics:" }}
  {{- $msg = append $msg "  enabled: true" }}
  {{- $msg = append $msg "" }}
  {{- $msg = append $msg "See https://github.com/grafana/k8s-monitoring-helm/blob/main/charts/k8s-monitoring/docs/Features.md for the list of available features." }}
  {{- fail (join "\n" $msg) }}
{{- end }}
{{- end }}
