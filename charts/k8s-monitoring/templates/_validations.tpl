{{- define "validations" }}
  {{- include "validations.checkForV1" . }}
  {{- include "validations.platform" . }}
  {{- include "validations.cluster_name" . }}
  {{- include "validations.platform" . }}

  {{- include "destinations.validate" . -}}

  {{- /* Feature Validations*/}}
  {{- include "validations.features_enabled" . }}
  {{- range $feature := ((include "features.list" .) | fromYamlArray) }}
    {{- include (printf "features.%s.validate" $feature) $ }}
  {{- end }}

  {{- include "collectors.validate.featuresEnabled" . }}
  {{- range $collectorName := ((include "collectors.list.enabled" .) | fromYamlArray) }}
    {{- include "collectors.validate.remoteConfig" (dict "collectorName" $collectorName "Values" $.Values) }}
  {{- end }}
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
{{- if or (not .Values.cluster) (not .Values.cluster.name) }}
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
{{- range $collector := ((include "collectors.list" .) | fromYamlArray ) }}
  {{- $aFeatureIsEnabled = or $aFeatureIsEnabled ((index $.Values $collector).remoteConfig.enabled) }}
  {{- $aFeatureIsEnabled = or $aFeatureIsEnabled ((index $.Values $collector).extraConfig) }}
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
